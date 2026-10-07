import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart' hide Matrix4;
import 'package:flutter/animation.dart' show Curves;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle;

import 'dino_series.dart';
import 'game_logic.dart';

enum GameStatus { idle, playing, paused, gameOver, won }

/// Poderes que se pagan con diamantes.
enum PowerUp {
  undo(1, 'DESHACER'),
  shuffle(2, 'MEZCLAR'),
  clean(2, 'LIMPIAR');

  final int cost;
  final String label;
  const PowerUp(this.cost, this.label);
}

/// Costo de seguir jugando después de perder.
const int kContinueCost = 5;

const _slideTime = 0.12;

const _tileColors = [
  Color(0xFFFFE45E),
  Color(0xFFFFBF69),
  Color(0xFFFF9F68),
  Color(0xFFFF6B6B),
  Color(0xFFF15BB5),
  Color(0xFF9B5DE5),
  Color(0xFF00BBF9),
  Color(0xFF2EC4B6),
  Color(0xFF80ED99),
  Color(0xFFFFD166),
  Color(0xFFFFFFFF),
];

class DinoGame extends FlameGame {
  DinoGame({required DinoSeries series}) : series = ValueNotifier(series);

  // ---- Estado observable desde Flutter (header, botones, overlays) ----
  final ValueNotifier<DinoSeries> series;
  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> bestScore = ValueNotifier(0);
  final ValueNotifier<GameStatus> status = ValueNotifier(GameStatus.idle);
  final ValueNotifier<bool> canUndo = ValueNotifier(false);

  /// Se llama cuando se supera el mejor puntaje (para guardarlo).
  void Function(int best)? onBestScoreChanged;
  VoidCallback? onValidSwipe;
  VoidCallback? onEvolution;
  VoidCallback? onGameOver;

  final GameLogic _logic = GameLogic();
  final Map<int, TileComponent> _tiles = {};
  final Map<String, Sprite> _sprites = {};

  BoardSnapshot? _undoSnapshot;
  bool _loaded = false;
  bool _busy = false;
  bool _wonShown = false;
  int _round = 0;

  double _cell = 0;
  double _gap = 0;
  Vector2 _origin = Vector2.zero();

  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadSprites(series.value);
    _loaded = true;
  }

  // ------------------------------------------------------------------
  // Layout
  // ------------------------------------------------------------------

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _computeLayout();
    for (final t in _logic.tiles) {
      final comp = _tiles[t.id];
      if (comp == null) continue;
      comp.size = Vector2.all(_cell);
      comp.position = _cellCenter(t.row, t.col);
    }
  }

  void _computeLayout() {
    const margin = 12.0;
    final side = max(0.0, min(size.x, size.y) - margin * 2);
    _gap = side * 0.025;
    _cell = max(0.0, (side - _gap * (GameLogic.size + 1)) / GameLogic.size);
    _origin = Vector2((size.x - side) / 2, (size.y - side) / 2);
  }

  Vector2 _cellCenter(int row, int col) => Vector2(
    _origin.x + _gap + col * (_cell + _gap) + _cell / 2,
    _origin.y + _gap + row * (_cell + _gap) + _cell / 2,
  );

  @override
  void render(Canvas canvas) {
    if (_cell > 0) {
      final side = _cell * GameLogic.size + _gap * (GameLogic.size + 1);
      final frame = RRect.fromRectAndRadius(
        Rect.fromLTWH(_origin.x, _origin.y, side, side),
        Radius.circular(side * 0.03),
      );
      canvas.drawRRect(frame, Paint()..color = const Color(0xFF0F3D44));
      final slot = Paint()..color = const Color(0xFF2A6B75);
      for (var r = 0; r < GameLogic.size; r++) {
        for (var c = 0; c < GameLogic.size; c++) {
          final center = _cellCenter(r, c);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(center.x, center.y),
                width: _cell,
                height: _cell,
              ),
              Radius.circular(_cell * 0.14),
            ),
            slot,
          );
        }
      }
    }
    super.render(canvas);
  }

  // ------------------------------------------------------------------
  // Sprites
  // ------------------------------------------------------------------

  Future<void> _loadSprites(DinoSeries s) async {
    for (final path in s.images) {
      if (_sprites.containsKey(path)) continue;
      try {
        _sprites[path] = Sprite(await images.load(path));
      } catch (_) {
        // Archivo inexistente: la ficha se dibuja solo con el número.
      }
    }
  }

  Sprite? _spriteFor(int value) {
    final path = series.value.imageForValue(value);
    return path == null ? null : _sprites[path];
  }

  Future<void> setSeries(DinoSeries s) async {
    await _loadSprites(s);
    series.value = s; // las fichas leen el sprite en cada frame
  }

  // ------------------------------------------------------------------
  // Control de partida (lo llama la botonera de Flutter)
  // ------------------------------------------------------------------

  /// INICIO: empieza una partida, o reanuda si estaba en pausa.
  void start() {
    switch (status.value) {
      case GameStatus.idle:
      case GameStatus.gameOver:
        _newRound();
      case GameStatus.paused:
        status.value = GameStatus.playing;
      case GameStatus.playing:
      case GameStatus.won:
        break;
    }
  }

  void pause() {
    if (status.value == GameStatus.playing) status.value = GameStatus.paused;
  }

  void togglePause() {
    if (status.value == GameStatus.playing) {
      status.value = GameStatus.paused;
    } else if (status.value == GameStatus.paused) {
      status.value = GameStatus.playing;
    }
  }

  /// REINICIAR: vuelve a empezar con la misma serie.
  void restart() => _newRound();

  /// NUEVA: empieza de cero con otra serie.
  Future<void> newGame(DinoSeries s) async {
    await setSeries(s);
    _newRound();
  }

  /// Después de llegar a 2048, seguir jugando.
  void keepPlaying() {
    if (status.value == GameStatus.won) status.value = GameStatus.playing;
  }

  void _newRound() {
    if (!_loaded) return;
    _logic.reset();
    score.value = 0;
    _undoSnapshot = null;
    canUndo.value = false;
    _wonShown = false;
    _rebuild(animate: true);
    status.value = GameStatus.playing;
  }

  // ------------------------------------------------------------------
  // Movimiento
  // ------------------------------------------------------------------

  void swipe(MoveDirection direction) {
    if (status.value != GameStatus.playing || _busy || !_loaded) return;

    final before = _logic.snapshot();
    final result = _logic.move(direction);
    if (!result.moved) return;
    onValidSwipe?.call();
    if (result.slides.any((slide) => slide.absorbedInto != null)) {
      onEvolution?.call();
    }

    _undoSnapshot = before;
    canUndo.value = true;
    _busy = true;
    score.value = _logic.score;
    _updateBest();

    for (final slide in result.slides) {
      final comp = _tiles[slide.tileId];
      if (comp == null) continue;
      final target = _cellCenter(slide.toRow, slide.toCol);
      final absorbedInto = slide.absorbedInto;
      if (absorbedInto == null && comp.position.distanceTo(target) < 0.5) {
        continue;
      }
      comp.add(
        MoveToEffect(
          target,
          EffectController(duration: _slideTime, curve: Curves.easeOut),
          onComplete: absorbedInto == null
              ? null
              : () {
                  _tiles.remove(slide.tileId);
                  comp.removeFromParent();
                  _tiles[absorbedInto]?.mergeTo(slide.newValue!);
                },
        ),
      );
    }

    final round = _round;
    add(
      TimerComponent(
        period: _slideTime + 0.02,
        removeOnFinish: true,
        onTick: () {
          if (round != _round) return; // la partida cambió mientras animaba
          final spawned = result.spawned;
          if (spawned != null) _addTile(spawned, animate: true);
          _busy = false;
          _checkEnd();
        },
      ),
    );
  }

  void _checkEnd() {
    if (!_wonShown && _logic.maxValue >= 2048) {
      _wonShown = true;
      status.value = GameStatus.won;
      return;
    }
    if (!_logic.canMove) {
      onGameOver?.call();
      status.value = GameStatus.gameOver;
    }
  }

  void _updateBest() {
    if (score.value > bestScore.value) {
      bestScore.value = score.value;
      onBestScoreChanged?.call(bestScore.value);
    }
  }

  // ------------------------------------------------------------------
  // Poderes (devuelven true si se aplicaron: recién ahí se cobra)
  // ------------------------------------------------------------------

  bool get _canUsePowerUp =>
      status.value == GameStatus.playing && !_busy && _loaded;

  bool undo() {
    final snap = _undoSnapshot;
    if (!_canUsePowerUp || snap == null) return false;
    _logic.restore(snap);
    score.value = _logic.score;
    _undoSnapshot = null;
    canUndo.value = false;
    _rebuild(animate: false);
    return true;
  }

  bool shuffleBoard() {
    if (!_canUsePowerUp || _logic.tiles.length < 2) return false;
    _saveUndo();
    _logic.shuffle();
    _rebuild(animate: true);
    return true;
  }

  /// Elimina las 3 fichas más chicas.
  bool cleanSmallest() {
    if (!_canUsePowerUp || _logic.tiles.length < 4) return false;
    _saveUndo();
    _logic.removeSmallest(3);
    _rebuild(animate: false);
    return true;
  }

  bool applyPowerUp(PowerUp p) => switch (p) {
    PowerUp.undo => undo(),
    PowerUp.shuffle => shuffleBoard(),
    PowerUp.clean => cleanSmallest(),
  };

  /// Después de perder: borra las 4 fichas más chicas y sigue.
  bool continueAfterGameOver() {
    if (status.value != GameStatus.gameOver) return false;
    _logic.removeSmallest(4);
    _undoSnapshot = null;
    canUndo.value = false;
    _rebuild(animate: false);
    status.value = GameStatus.playing;
    return true;
  }

  void _saveUndo() {
    _undoSnapshot = _logic.snapshot();
    canUndo.value = true;
  }

  // ------------------------------------------------------------------
  // Componentes
  // ------------------------------------------------------------------

  void _rebuild({required bool animate}) {
    _round++;
    _busy = false;
    removeAll(_tiles.values.toList());
    _tiles.clear();
    for (final t in _logic.tiles) {
      _addTile(t, animate: animate);
    }
  }

  void _addTile(TileData t, {required bool animate}) {
    if (_cell <= 0) _computeLayout();
    final comp = TileComponent(
      tileId: t.id,
      value: t.value,
      spriteFor: _spriteFor,
      size: Vector2.all(_cell),
      position: _cellCenter(t.row, t.col),
    );
    if (animate) {
      comp.scale = Vector2.zero();
      comp.add(
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.18, curve: Curves.easeOutBack),
        ),
      );
    }
    _tiles[t.id] = comp;
    add(comp);
  }
}

/// Ficha visual: fondo de color + imagen del dino + número.
class TileComponent extends PositionComponent {
  TileComponent({
    required this.tileId,
    required this.value,
    required this.spriteFor,
    required Vector2 size,
    required Vector2 position,
  }) : super(size: size, position: position, anchor: Anchor.center);

  final int tileId;
  int value;
  final Sprite? Function(int value) spriteFor;

  TextPainter? _label;
  String _labelKey = '';

  void mergeTo(int newValue) {
    value = newValue;
    add(
      ScaleEffect.to(
        Vector2.all(1.18),
        EffectController(
          duration: 0.09,
          alternate: true,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.16),
    );
    final stage = min(max(value.bitLength - 2, 0), _tileColors.length - 1);
    canvas.drawRRect(rrect, Paint()..color = _tileColors[stage]);

    final sprite = spriteFor(value);
    if (sprite != null) {
      final avail = w * 0.84;
      final src = sprite.srcSize;
      final k = min(avail / src.x, avail / src.y);
      final dw = src.x * k;
      final dh = src.y * k;
      sprite.render(
        canvas,
        position: Vector2((w - dw) / 2, (h - dh) / 2 - h * 0.03),
        size: Vector2(dw, dh),
      );
    }

    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF000000),
    );
    _drawLabel(canvas, big: sprite == null);
  }

  void _drawLabel(Canvas canvas, {required bool big}) {
    final fontSize = big ? size.x * 0.38 : size.x * 0.19;
    final key = '$value-$big-${fontSize.round()}';
    if (_label == null || _labelKey != key) {
      _labelKey = key;
      _label = TextPainter(
        text: TextSpan(
          text: '$value',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: big ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    final tp = _label!;
    if (big) {
      tp.paint(
        canvas,
        Offset((size.x - tp.width) / 2, (size.y - tp.height) / 2),
      );
      return;
    }
    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        (size.x - tp.width) / 2 - 6,
        size.y - tp.height - 5,
        tp.width + 12,
        tp.height + 2,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(pill, Paint()..color = const Color(0xFF000000));
    tp.paint(canvas, Offset(pill.left + 6, pill.top + 1));
  }
}

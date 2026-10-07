import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flame/game.dart' hide Matrix4;
import 'package:audioplayers/audioplayers.dart';

import 'dino_game.dart';
import 'dino_series.dart';
import 'game_logic.dart';

void main() {
  runApp(const Dino2048App());
}

class AppColors {
  final bool isDark;

  const AppColors(this.isDark);

  Color get background =>
      isDark ? const Color(0xFF17172E) : const Color(0xFFCBF3F0);
  Color get header =>
      isDark ? const Color(0xFF34345B) : const Color(0xFFFFBF69);
  Color get panel => isDark ? const Color(0xFF292943) : const Color(0xFFFFF3B0);
  Color get foreground => isDark ? Colors.white : Colors.black;
  Color get outline => isDark ? const Color(0xFF090912) : Colors.black;
  Color get shadow => isDark ? const Color(0xFF080811) : Colors.black;
  Color get startButton =>
      isDark ? const Color(0xFF45E0C0) : const Color(0xFF2EC4B6);
  Color get pauseButton =>
      isDark ? const Color(0xFFFFD27A) : const Color(0xFFFFBF69);
  Color get restartButton =>
      isDark ? const Color(0xFFFF8994) : const Color(0xFFFF6B6B);
  Color get newButton =>
      isDark ? const Color(0xFFC29AFF) : const Color(0xFF9B5DE5);
}

const _diamondPackBackground = Color(0xFF9FEAF6);

class Dino2048App extends StatefulWidget {
  const Dino2048App({super.key});

  @override
  State<Dino2048App> createState() => _Dino2048AppState();
}

class _Dino2048AppState extends State<Dino2048App> {
  late final GameAudio _audio;

  @override
  void initState() {
    super.initState();
    _audio = GameAudio();
    unawaited(_audio.startMusic());
  }

  @override
  void dispose() {
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dino 2048',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFCBF3F0),
        fontFamily: 'sans-serif-rounded',
        brightness: Brightness.light,
      ),
      home: SplashScreen(audio: _audio),
    );
  }
}

class GameAudio {
  final AudioPlayer _music = AudioPlayer();
  final AudioPlayer _swipe = AudioPlayer();
  final AudioPlayer _evolution = AudioPlayer();
  final AudioPlayer _gameOver = AudioPlayer();
  bool _disposed = false;
  Future<void>? _startFuture;

  Future<void> startMusic() => _startFuture ??= _startMusic();

  Future<void> _startMusic() async {
    try {
      final audioContext = AudioContext(
        android: const AudioContextAndroid(
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      );
      await Future.wait([
        _music.setAudioContext(audioContext),
        _swipe.setAudioContext(audioContext),
        _evolution.setAudioContext(audioContext),
        _gameOver.setAudioContext(audioContext),
      ]);
      if (_disposed) return;
      await _music.setReleaseMode(ReleaseMode.loop);
      await _music.play(AssetSource('sounds/sanpomichi.mp3'));
    } catch (error, stackTrace) {
      _reportError('starting background music', error, stackTrace);
    }
  }

  void playSwipe() => unawaited(_playEffect(_swipe, 'sounds/swipe.mp3'));

  void playEvolution() =>
      unawaited(_playEffect(_evolution, 'sounds/evolucion.mp3'));

  void playGameOver() =>
      unawaited(_playEffect(_gameOver, 'sounds/gameover.mp3'));

  Future<void> _playEffect(AudioPlayer player, String asset) async {
    if (_disposed) return;
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (error, stackTrace) {
      _reportError('playing $asset', error, stackTrace);
    }
  }

  void _reportError(String action, Object error, StackTrace stackTrace) {
    debugPrint('Audio error while $action: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  Future<void> dispose() async {
    _disposed = true;
    await (_startFuture ?? Future<void>.value());
    await Future.wait([
      _music.dispose(),
      _swipe.dispose(),
      _evolution.dispose(),
      _gameOver.dispose(),
    ]);
  }
}

class GameScreen extends StatefulWidget {
  final GameAudio audio;

  const GameScreen({super.key, required this.audio});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _diamonds = 50;
  bool _isDarkMode = false;
  AccountType _accountType = AccountType.basic;
  
  late final DinoGame _game;
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _game = DinoGame(series: kDinoSeries.first);
    _game.onValidSwipe = widget.audio.playSwipe;
    _game.onEvolution = widget.audio.playEvolution;
    _game.onGameOver = widget.audio.playGameOver;
    _game.status.addListener(_onGameStatusChanged);
  }

  @override
  void dispose() {
    _game.status.removeListener(_onGameStatusChanged);
    super.dispose();
  }

  void _onGameStatusChanged() {
    final status = _game.status.value;
    
    if (status == GameStatus.paused) {
      _game.overlays.add('PauseOverlay');
    } else {
      _game.overlays.remove('PauseOverlay');
    }

    if (status == GameStatus.gameOver) {
      _game.overlays.add('GameOverOverlay');
    } else {
      _game.overlays.remove('GameOverOverlay');
    }
  }

  void _setDarkMode(bool isDarkMode) {
    setState(() => _isDarkMode = isDarkMode);
  }

  void _toggleAccountType() {
    setState(() {
      _accountType = _accountType == AccountType.basic
          ? AccountType.pro
          : AccountType.basic;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cuenta cambiada a ${_accountType.label}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors(_isDarkMode);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeader(colors),
              const SizedBox(height: 12),
              _buildPowerUps(colors),
              const SizedBox(height: 12),
              _buildBoardPlaceholder(),
              const SizedBox(height: 24),
              _buildControls(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.header,
        border: Border.all(color: colors.foreground, width: 4),
        boxShadow: [BoxShadow(color: colors.shadow, offset: const Offset(6, 6))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'USUARIO: miguelito',
                style: TextStyle(
                  color: colors.foreground, fontWeight: FontWeight.w900, fontSize: 16,
                ),
              ),
              GestureDetector(
                onTap: _toggleAccountType,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accountType == AccountType.pro 
                        ? const Color(0xFFFF6B6B) 
                        : const Color(0xFFB0BEC5),
                    border: Border.all(color: colors.outline, width: 3),
                  ),
                  child: Text(
                    _accountType.label,
                    style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<int>(
                valueListenable: _game.score,
                builder: (context, score, child) {
                  return Text(
                    'SCORE: $score',
                    style: TextStyle(
                      color: colors.foreground, fontWeight: FontWeight.w900, fontSize: 22,
                    ),
                  );
                },
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ThemeToggleButton(
                    isDarkMode: _isDarkMode,
                    onPressed: () => _setDarkMode(!_isDarkMode),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: const Color(0xFF2EC4B6),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openDiamondShop,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 3),
                        ),
                        child: const Icon(Icons.add, size: 28, weight: 900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      const SizedBox(
                        width: 27, height: 27, child: CustomPaint(painter: DiamondIconPainter()),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$_diamonds',
                        style: TextStyle(
                          color: colors.foreground, fontWeight: FontWeight.w900, fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUps(AppColors colors) {
    return ValueListenableBuilder<GameStatus>(
      valueListenable: _game.status,
      builder: (context, status, _) {
        final isActive = status == GameStatus.playing;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: PowerUp.values.map((power) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton.icon(
                  onPressed: isActive ? () => _usePowerUp(power) : null,
                  icon: const SizedBox(
                    width: 14, height: 14, 
                    child: CustomPaint(painter: DiamondIconPainter())
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${power.cost} ${power.label}')
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    foregroundColor: colors.foreground, 
                    disabledForegroundColor: colors.foreground,
                    backgroundColor: colors.panel,
                    disabledBackgroundColor: colors.panel.withOpacity(0.5),
                    side: BorderSide(color: colors.foreground, width: 2),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }
    );
  }

  void _usePowerUp(PowerUp power) {
    if (_diamonds < power.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes diamantes suficientes.')),
      );
      return;
    }
    final applied = _game.applyPowerUp(power);
    if (applied) {
      setState(() => _diamonds -= power.cost);
    }
  }

Widget _buildBoardPlaceholder() {
    return Expanded(
      child: GestureDetector(
        onPanStart: (details) {
          _dragStart = details.localPosition; // Guardamos dónde apoyó el dedo
        },
        onPanUpdate: (details) {
          if (_dragStart == null) return;
          
          final delta = details.localPosition - _dragStart!;
          
          // Si el deslizamiento supera los 40 píxeles, lo registramos
          if (delta.distance > 40) {
            if (delta.dx.abs() > delta.dy.abs()) {
              _game.swipe(delta.dx > 0 ? MoveDirection.right : MoveDirection.left);
            } else {
              _game.swipe(delta.dy > 0 ? MoveDirection.down : MoveDirection.up);
            }
            // Reiniciamos a null para que no se mueva varias veces en un solo gesto
            _dragStart = null; 
          }
        },
        onPanEnd: (_) {
          _dragStart = null; // Limpiamos al levantar el dedo
        },
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: const Color(0xFF1A535C),
            border: Border.all(color: Colors.black, width: 6),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(8, 8))],
          ),
          child: GameWidget(
            game: _game,
            overlayBuilderMap: {
              'PauseOverlay': (context, DinoGame game) => _buildOverlay('PAUSA'),
              'GameOverOverlay': (context, DinoGame game) => _buildGameOverOverlay(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(String text) {
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 4,
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'FIN DEL JUEGO',
            style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_diamonds >= kContinueCost) {
                setState(() => _diamonds -= kContinueCost);
                _game.continueAfterGameOver();
                _game.overlays.remove('GameOverOverlay');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Diamantes insuficientes')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2EC4B6),
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black, width: 3),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('SEGUIR JUGANDO (', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(width: 16, height: 16, child: CustomPaint(painter: DiamondIconPainter())),
                Text(' $kContinueCost)', style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildControls(AppColors colors) {
    return ValueListenableBuilder<GameStatus>(
      valueListenable: _game.status,
      builder: (context, status, child) {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: BrutalistButton(
                    text: 'INICIO', 
                    color: colors.startButton,
                    onPressed: () => _game.start(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BrutalistButton(
                    text: status == GameStatus.paused ? 'REANUDAR' : 'PAUSA', 
                    color: colors.pauseButton,
                    onPressed: () => _game.togglePause(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: BrutalistButton(
                    text: 'REINICIAR',
                    color: colors.restartButton,
                    onPressed: () {
                      _showAdvertisement().then((_) {
                        _game.overlays.remove('GameOverOverlay');
                        _game.restart();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BrutalistButton(
                    text: 'NUEVA',
                    color: colors.newButton,
                    textColor: _isDarkMode ? Colors.black : Colors.white,
                    onPressed: _showSeriesSelector,
                  ),
                ),
              ],
            ),
          ],
        );
      }
    );
  }

  void _showSeriesSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors(_isDarkMode).panel,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'ELEGÍ TU SERIE',
                  style: TextStyle(
                    fontSize: 20, 
                    fontWeight: FontWeight.w900,
                    color: AppColors(_isDarkMode).foreground
                  ),
                ),
              ),
              ...kDinoSeries.map((serie) {
                final allowed = serie.isAllowedFor(_accountType);
                return ListTile(
                  leading: CircleAvatar(backgroundColor: serie.color),
                  title: Text(
                    serie.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: allowed ? AppColors(_isDarkMode).foreground : Colors.grey,
                    ),
                  ),
                  trailing: allowed ? null : const Icon(Icons.lock, color: Colors.grey),
                  onTap: allowed ? () {
                    Navigator.pop(ctx);
                    _game.newGame(serie);
                  } : null,
                );
              }),
            ],
          ),
        );
      }
    );
  }

  Future<void> _openDiamondShop() async {
    final purchasedDiamonds = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => DiamondShopScreen(
          isDarkMode: _isDarkMode,
          onThemeChanged: _setDarkMode,
        ),
      ),
    );

    if (!mounted || purchasedDiamonds == null) return;

    setState(() => _diamonds += purchasedDiamonds);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Genial! Sumaste $purchasedDiamonds diamantes.'),
        backgroundColor: _isDarkMode
            ? const Color(0xFF34345B)
            : const Color(0xFF1A535C),
      ),
    );
  }

  Future<void> _showAdvertisement() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DinoBitesAdvertisement(),
    );
  }
}

class _DinoBitesAdvertisement extends StatefulWidget {
  const _DinoBitesAdvertisement();
  @override
  State<_DinoBitesAdvertisement> createState() => _DinoBitesAdvertisementState();
}

class _DinoBitesAdvertisementState extends State<_DinoBitesAdvertisement> {
  static const _adDuration = 8;
  late final Timer _countdownTimer;
  int _secondsRemaining = _adDuration;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _close() {
    if (_secondsRemaining != 0) return;
    final route = ModalRoute.of(context);
    if (route != null) {
      Navigator.of(context, rootNavigator: true).removeRoute(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _secondsRemaining == 0;
    return PopScope(
      canPop: canContinue,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE45E),
            border: Border.all(color: Colors.black, width: 4),
            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(7, 7))],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: canContinue ? 'Cerrar anuncio' : null,
                    onPressed: canContinue ? _close : null,
                    icon: const Icon(Icons.close, size: 30),
                  ),
                ),
                Container(
                  width: 112, height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 4),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: CustomPaint(painter: _DinosaurCookiePainter()),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DINO BITES',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),
                const Text(
                  '¡DINO BITES A TAN SOLO \$1200 ARS!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 23, height: 1.12, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Conseguí tus galletitas de dinosaurios favoritas en la tienda más cercana',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, height: 1.3),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canContinue ? _close : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2EC4B6),
                      disabledBackgroundColor: const Color(0xFF9DDDD7),
                      foregroundColor: Colors.black,
                      minimumSize: const Size(0, 54),
                      side: const BorderSide(color: Colors.black, width: 3),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                    child: Text(
                      canContinue ? '¡A JUGAR!' : 'ESPERÁ $_secondsRemaining SEG.',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DinosaurCookiePainter extends CustomPainter {
  const _DinosaurCookiePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 100);
    final cookie = Paint()..color = const Color(0xFFC87935);
    final outline = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 4..strokeJoin = StrokeJoin.round;
    final silhouette = Path()
      ..moveTo(8, 59)..lineTo(27, 52)..cubicTo(31, 39, 46, 36, 58, 42)..lineTo(62, 25)
      ..cubicTo(63, 17, 72, 14, 78, 20)..lineTo(83, 27)..lineTo(96, 28)
      ..cubicTo(103, 29, 104, 37, 96, 39)..lineTo(83, 39)..lineTo(79, 51)
      ..cubicTo(95, 56, 97, 68, 86, 73)..lineTo(82, 84)..lineTo(68, 84)..lineTo(65, 72)
      ..lineTo(48, 70)..lineTo(45, 84)..lineTo(31, 84)..lineTo(30, 72)..lineTo(20, 72)..close();
    canvas.drawPath(silhouette, cookie); canvas.drawPath(silhouette, outline);
    final spikes = Path()..moveTo(43, 40)..lineTo(47, 29)..lineTo(54, 41)..lineTo(59, 30)..lineTo(64, 43)..close();
    canvas.drawPath(spikes, Paint()..color = const Color(0xFFE8A34A)); canvas.drawPath(spikes, outline);
    final chips = Paint()..color = const Color(0xFF75421F);
    for (final chip in [const Offset(33, 58), const Offset(48, 52), const Offset(73, 47), const Offset(59, 62), const Offset(77, 64), const Offset(40, 67)]) {
      canvas.drawCircle(chip, 2.4, chips);
    }
    canvas.drawCircle(const Offset(88, 32), 2, Paint()..color = Colors.black);
    canvas.restore();
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ThemeToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onPressed;
  const _ThemeToggleButton({required this.isDarkMode, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    final label = isDarkMode ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro';
    return Tooltip(
      message: label,
      child: Semantics(
        button: true, label: label,
        child: Material(
          color: const Color(0xFFFFE45E),
          shape: const CircleBorder(side: BorderSide(color: Colors.black, width: 3)),
          elevation: 3, shadowColor: Colors.black,
          child: InkWell(
            customBorder: const CircleBorder(), onTap: onPressed,
            child: SizedBox(
              width: 40, height: 40,
              child: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.black, size: 23),
            ),
          ),
        ),
      ),
    );
  }
}

class DiamondPack {
  final String name;
  final int amount;
  final String price;
  final String imageAsset;
  const DiamondPack({required this.name, required this.amount, required this.price, required this.imageAsset});
}

const _diamondPacks = [
  DiamondPack(name: 'PUÑADO', amount: 10, price: r'$500', imageAsset: 'assets/images/diamantes1.jpg'),
  DiamondPack(name: 'BOLSA', amount: 25, price: r'$1.200', imageAsset: 'assets/images/diamantes2.jpg'),
  DiamondPack(name: 'CAJA', amount: 50, price: r'$2.500', imageAsset: 'assets/images/diamantes3.jpg'),
  DiamondPack(name: 'CAJÓN', amount: 100, price: r'$5.200', imageAsset: 'assets/images/diamantes4.jpg'),
  DiamondPack(name: 'CARRETILLA', amount: 200, price: r'$10.500', imageAsset: 'assets/images/diamantes5.jpg'),
  DiamondPack(name: 'LLUVIA', amount: 500, price: r'$25.000', imageAsset: 'assets/images/diamantes6.jpg'),
];

enum PackIllustrationType { handful, backpack, box, crate, wheelbarrow, diamondRain }

class DiamondIconPainter extends CustomPainter {
  const DiamondIconPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final outline = Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 7..strokeJoin = StrokeJoin.round;
    final gem = Path()..moveTo(17, 34)..lineTo(34, 13)..lineTo(68, 13)..lineTo(85, 34)..lineTo(51, 88)..close();
    canvas.drawPath(gem, Paint()..color = const Color(0xFF52D7F2)); canvas.drawPath(gem, outline);
    final facets = Paint()..color = const Color(0xFF1A535C)..style = PaintingStyle.stroke..strokeWidth = 4;
    canvas.drawLine(const Offset(17, 34), const Offset(85, 34), facets);
    canvas.drawLine(const Offset(34, 13), const Offset(42, 34), facets);
    canvas.drawLine(const Offset(68, 13), const Offset(60, 34), facets);
    canvas.drawLine(const Offset(42, 34), const Offset(51, 88), facets);
    canvas.drawLine(const Offset(60, 34), const Offset(51, 88), facets);
    canvas.restore();
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PackIllustration extends StatelessWidget {
  final PackIllustrationType type;
  const PackIllustration({super.key, required this.type});
  @override Widget build(BuildContext context) => CustomPaint(painter: _PackIllustrationPainter(type), child: const SizedBox.expand());
}

class _PackIllustrationPainter extends CustomPainter {
  final PackIllustrationType type;
  const _PackIllustrationPainter(this.type);
  final Color _ink = Colors.black;
  final Color _gemBlue = const Color(0xFF52D7F2);
  final Color _gemPink = const Color(0xFFF15BB5);
  final Color _gemYellow = const Color(0xFFFFE45E);

  Paint _paint(Color color, {bool stroke = false, double width = 3}) => Paint()..color = color..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill..strokeWidth = width..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
  void _line(Canvas canvas, Offset a, Offset b, {double width = 4}) => canvas.drawLine(a, b, _paint(_ink, stroke: true, width: width));
  void _gem(Canvas canvas, double x, double y, double scale, Color color) {
    final gem = Path()..moveTo(x - 12 * scale, y - 5 * scale)..lineTo(x - 6 * scale, y - 13 * scale)..lineTo(x + 6 * scale, y - 13 * scale)..lineTo(x + 12 * scale, y - 5 * scale)..lineTo(x, y + 13 * scale)..close();
    canvas.drawPath(gem, _paint(color)); canvas.drawPath(gem, _paint(_ink, stroke: true, width: 2.5 * scale));
    _line(canvas, Offset(x - 12 * scale, y - 5 * scale), Offset(x + 12 * scale, y - 5 * scale), width: 1.8 * scale);
    _line(canvas, Offset(x - 6 * scale, y - 13 * scale), Offset(x - 3 * scale, y - 5 * scale), width: 1.5 * scale);
    _line(canvas, Offset(x + 6 * scale, y - 13 * scale), Offset(x + 3 * scale, y - 5 * scale), width: 1.5 * scale);
  }
  void _drawHandful(Canvas canvas) {
    final skin = _paint(const Color(0xFFFFC18C)); final outline = _paint(_ink, stroke: true, width: 4);
    for (final finger in [const Rect.fromLTWH(37, 31, 14, 37), const Rect.fromLTWH(51, 22, 14, 42), const Rect.fromLTWH(65, 24, 14, 40), const Rect.fromLTWH(79, 32, 14, 34)]) {
      final shape = RRect.fromRectAndRadius(finger, const Radius.circular(8)); canvas.drawRRect(shape, skin); canvas.drawRRect(shape, outline);
    }
    final palm = Path()..moveTo(34, 55)..quadraticBezierTo(35, 43, 46, 43)..lineTo(84, 43)..quadraticBezierTo(94, 44, 95, 54)..lineTo(89, 72)..quadraticBezierTo(85, 83, 72, 84)..lineTo(48, 80)..quadraticBezierTo(35, 77, 34, 66)..close();
    canvas.drawPath(palm, skin); canvas.drawPath(palm, outline);
    final thumb = Path()..moveTo(38, 58)..quadraticBezierTo(29, 53, 23, 61)..quadraticBezierTo(20, 67, 28, 72)..lineTo(43, 78)..lineTo(50, 67)..close();
    canvas.drawPath(thumb, skin); canvas.drawPath(thumb, outline);
    _gem(canvas, 63, 50, 1.22, _gemBlue); _line(canvas, const Offset(43, 72), const Offset(53, 74), width: 2.5); _line(canvas, const Offset(73, 75), const Offset(83, 72), width: 2.5);
  }
  void _drawBackpack(Canvas canvas) {
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(27, 29, 66, 64), const Radius.circular(17));
    canvas.drawRRect(body, _paint(const Color(0xFFEF476F))); canvas.drawRRect(body, _paint(_ink, stroke: true, width: 4));
    final straps = _paint(const Color(0xFFFFBF69), stroke: true, width: 7);
    canvas.drawArc(const Rect.fromLTWH(20, 38, 22, 48), 1.2, 3.9, false, straps); canvas.drawArc(const Rect.fromLTWH(78, 38, 22, 48), 4.3, 3.9, false, straps);
    canvas.drawArc(const Rect.fromLTWH(43, 12, 34, 31), 3.15, 3.0, false, _paint(_ink, stroke: true, width: 5));
    final pocket = RRect.fromRectAndRadius(const Rect.fromLTWH(37, 58, 46, 27), const Radius.circular(9));
    canvas.drawRRect(pocket, _paint(const Color(0xFFFFBF69))); canvas.drawRRect(pocket, _paint(_ink, stroke: true, width: 3));
    _gem(canvas, 49, 70, 0.65, _gemBlue); _gem(canvas, 68, 70, 0.65, _gemYellow); _gem(canvas, 53, 43, 0.7, _gemPink); _gem(canvas, 70, 43, 0.7, _gemBlue);
  }
  void _drawBox(Canvas canvas) {
    final box = Path()..moveTo(28, 45)..lineTo(92, 45)..lineTo(87, 91)..lineTo(33, 91)..close();
    final lid = Path()..moveTo(24, 45)..lineTo(37, 27)..lineTo(83, 27)..lineTo(96, 45)..close();
    canvas.drawPath(box, _paint(const Color(0xFFFFBF69))); canvas.drawPath(box, _paint(_ink, stroke: true, width: 4));
    canvas.drawPath(lid, _paint(const Color(0xFFFFD166))); canvas.drawPath(lid, _paint(_ink, stroke: true, width: 4));
    _line(canvas, const Offset(39, 49), const Offset(43, 89), width: 3); _line(canvas, const Offset(81, 49), const Offset(77, 89), width: 3);
    _gem(canvas, 44, 57, 0.62, _gemBlue); _gem(canvas, 62, 55, 0.62, _gemPink); _gem(canvas, 79, 57, 0.62, _gemYellow);
    _gem(canvas, 50, 35, 0.46, _gemYellow); _gem(canvas, 71, 35, 0.46, _gemBlue);
  }
  void _drawCrate(Canvas canvas) {
    final top = Path()..moveTo(23, 35)..lineTo(43, 22)..lineTo(101, 31)..lineTo(82, 44)..close();
    final front = Path()..moveTo(23, 35)..lineTo(82, 44)..lineTo(82, 88)..lineTo(23, 77)..close();
    final side = Path()..moveTo(82, 44)..lineTo(101, 31)..lineTo(101, 75)..lineTo(82, 88)..close();
    canvas.drawPath(top, _paint(const Color(0xFFFFD166))); canvas.drawPath(top, _paint(_ink, stroke: true, width: 4));
    canvas.drawPath(front, _paint(const Color(0xFFB56536))); canvas.drawPath(front, _paint(_ink, stroke: true, width: 4));
    canvas.drawPath(side, _paint(const Color(0xFF8D4E2F))); canvas.drawPath(side, _paint(_ink, stroke: true, width: 4));
    for (var x = 39.0; x <= 67; x += 14) _line(canvas, Offset(x, 39 + (x - 23) * 0.15), Offset(x, 80 + (x - 23) * 0.15), width: 3);
    _line(canvas, const Offset(86, 43), const Offset(86, 85), width: 3); _line(canvas, const Offset(97, 35), const Offset(97, 78), width: 3);
    canvas.drawPath(Path()..moveTo(20, 34)..lineTo(43, 19)..lineTo(104, 29)..lineTo(82, 46)..close(), _paint(const Color(0xFFFFBF69), stroke: true, width: 4));
    _gem(canvas, 52, 31, 0.7, _gemBlue); _gem(canvas, 69, 34, 0.7, _gemPink); _gem(canvas, 85, 33, 0.7, _gemYellow);
  }
  void _drawWheelbarrow(Canvas canvas) {
    final tray = Path()..moveTo(30, 36)..lineTo(102, 43)..lineTo(87, 68)..lineTo(45, 63)..close();
    canvas.drawPath(tray, _paint(const Color(0xFFFF6B6B))); canvas.drawPath(tray, _paint(_ink, stroke: true, width: 4));
    _line(canvas, const Offset(40, 42), const Offset(91, 47), width: 2.5);
    _line(canvas, const Offset(49, 63), const Offset(39, 80), width: 5); _line(canvas, const Offset(72, 66), const Offset(64, 83), width: 5);
    _line(canvas, const Offset(71, 65), const Offset(107, 83), width: 5); _line(canvas, const Offset(78, 59), const Offset(114, 76), width: 5);
    canvas.drawCircle(const Offset(34, 78), 12, _paint(const Color(0xFF455A64))); canvas.drawCircle(const Offset(34, 78), 12, _paint(_ink, stroke: true, width: 3.5));
    canvas.drawCircle(const Offset(34, 78), 5, _paint(const Color(0xFFFFE45E))); canvas.drawCircle(const Offset(34, 78), 2, _paint(const Color(0xFF455A64)));
    _gem(canvas, 49, 42, 0.68, _gemBlue); _gem(canvas, 67, 44, 0.68, _gemYellow); _gem(canvas, 85, 46, 0.68, _gemPink); _gem(canvas, 100, 41, 0.58, _gemBlue);
  }
  void _drawDiamondRain(Canvas canvas) {
    final cloudPath = Path()..moveTo(28, 43)..cubicTo(13, 43, 12, 25, 26, 21)..cubicTo(31, 7, 51, 8, 58, 21)..cubicTo(73, 11, 91, 20, 89, 35)..cubicTo(105, 35, 105, 52, 90, 53)..lineTo(29, 53)..close();
    canvas.drawPath(cloudPath, _paint(Colors.white)); canvas.drawPath(cloudPath, _paint(_ink, stroke: true, width: 4));
    final drops = [const Offset(25, 70), const Offset(43, 83), const Offset(59, 68), const Offset(76, 86), const Offset(94, 69), const Offset(38, 56)];
    final colors = [_gemBlue, _gemPink, _gemYellow, _gemBlue, _gemPink, _gemYellow];
    for (var i = 0; i < drops.length; i++) _gem(canvas, drops[i].dx, drops[i].dy, 0.7, colors[i]);
  }
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save(); canvas.scale(size.width / 120, size.height / 100);
    switch (type) {
      case PackIllustrationType.handful: _drawHandful(canvas); break;
      case PackIllustrationType.backpack: _drawBackpack(canvas); break;
      case PackIllustrationType.box: _drawBox(canvas); break;
      case PackIllustrationType.crate: _drawCrate(canvas); break;
      case PackIllustrationType.wheelbarrow: _drawWheelbarrow(canvas); break;
      case PackIllustrationType.diamondRain: _drawDiamondRain(canvas); break;
    }
    canvas.restore();
  }
  @override bool shouldRepaint(covariant _PackIllustrationPainter oldDelegate) => oldDelegate.type != type;
}

class DiamondShopScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  const DiamondShopScreen({super.key, required this.isDarkMode, required this.onThemeChanged});
  @override State<DiamondShopScreen> createState() => _DiamondShopScreenState();
}

class _DiamondShopScreenState extends State<DiamondShopScreen> {
  late bool _isDarkMode;
  @override void initState() { super.initState(); _isDarkMode = widget.isDarkMode; }
  void _toggleTheme() { setState(() => _isDarkMode = !_isDarkMode); widget.onThemeChanged(_isDarkMode); }
  @override
  Widget build(BuildContext context) {
    final colors = AppColors(_isDarkMode);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.header, foregroundColor: colors.foreground, elevation: 0,
        title: const Text('TIENDA DE DIAMANTES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        leading: IconButton(tooltip: 'Volver al juego', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        actions: [Padding(padding: const EdgeInsets.only(right: 8), child: _ThemeToggleButton(isDarkMode: _isDarkMode, onPressed: _toggleTheme))],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 10.0 : 16.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: colors.panel, border: Border.all(color: colors.outline, width: 3), boxShadow: [BoxShadow(color: colors.shadow, offset: const Offset(4, 4))]),
                    child: Text('¡ELEGÍ TU TESORO!\n¡Consigue más diamantes y diviértete!', textAlign: TextAlign.center, style: TextStyle(color: colors.foreground, fontWeight: FontWeight.w900, fontSize: 18, height: 1.25)),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _diamondPacks.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 26, mainAxisExtent: 250),
                    itemBuilder: (context, index) => _DiamondPackCard(pack: _diamondPacks[index], colors: colors, onTap: () => Navigator.of(context).pop(_diamondPacks[index].amount)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DiamondPackCard extends StatelessWidget {
  final DiamondPack pack;
  final AppColors colors;
  final VoidCallback onTap;
  const _DiamondPackCard({required this.pack, required this.colors, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: _diamondPackBackground, border: Border.all(color: Colors.black, width: 3), boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))]),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Column(
          children: [
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Image.asset(pack.imageAsset, fit: BoxFit.contain))),
            FittedBox(fit: BoxFit.scaleDown, child: Text(pack.name, maxLines: 1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.3))),
            const SizedBox(height: 2),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(width: 19, height: 19, child: CustomPaint(painter: DiamondIconPainter())), const SizedBox(width: 4), Text('${pack.amount}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17))]),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(backgroundColor: colors.panel, foregroundColor: colors.foreground, padding: const EdgeInsets.symmetric(vertical: 10), minimumSize: const Size(0, 48), side: BorderSide(color: colors.outline, width: 3), shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero)),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text('${pack.price} ARS', maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrutalistButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;
  const BrutalistButton({super.key, required this.text, required this.color, this.textColor = Colors.black, this.onPressed});
  @override State<BrutalistButton> createState() => _BrutalistButtonState();
}

class _BrutalistButtonState extends State<BrutalistButton> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true), onTapUp: (_) => setState(() => _isPressed = false), onTapCancel: () => setState(() => _isPressed = false), onTap: widget.onPressed,
      child: Transform.translate(
        offset: _isPressed ? const Offset(4, 4) : Offset.zero,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: widget.color, border: Border.all(color: Colors.black, width: 3), boxShadow: _isPressed ? const [] : const [BoxShadow(color: Colors.black, offset: Offset(6, 6))]),
          child: Center(child: Text(widget.text, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final GameAudio audio;

  const SplashScreen({super.key, required this.audio});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Espera 3 segundos y luego navega a la pantalla del juego
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => GameScreen(audio: widget.audio)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A535C), // Azul petróleo
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE45E), // Amarillo brutalista
                border: Border.all(color: Colors.black, width: 6),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(8, 8))
                ],
              ),
              child: const Text(
                'DINO\n2048',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  height: 1.1,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              color: Color(0xFFFF6B6B), // Rojo coral
              strokeWidth: 6,
            ),
            const SizedBox(height: 20),
            const Text(
              'DINOSAURIOS EN MARCHA...',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            )
          ],
        ),
      ),
    );
  }
}
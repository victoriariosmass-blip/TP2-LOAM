import 'dart:math';

enum MoveDirection { up, down, left, right }

/// una ficha lógica del tablero, tiene id estable para que Flame pueda
/// animar el mismo componente de una celda a otra
class TileData {
  final int id;
  int value;
  int row;
  int col;

  TileData(this.id, this.value, this.row, this.col);

  TileData copy() => TileData(id, value, row, col);
}

/// describe cómo se mueve una ficha en un turno
/// si [absorbedInto] != null, la ficha se fusiona con esa otra y desaparece
/// al llegar, [newValue] es el valor que pasa a tener la ficha que sobrevive
class TileSlide {
  final int tileId;
  final int toRow;
  final int toCol;
  final int? absorbedInto;
  final int? newValue;

  const TileSlide({
    required this.tileId,
    required this.toRow,
    required this.toCol,
    this.absorbedInto,
    this.newValue,
  });
}

class MoveResult {
  final bool moved;
  final int scoreGained;
  final List<TileSlide> slides;
  final TileData? spawned;

  const MoveResult({
    required this.moved,
    required this.scoreGained,
    required this.slides,
    required this.spawned,
  });
}

class BoardSnapshot {
  final List<TileData> tiles;
  final int score;
  final int nextId;

  const BoardSnapshot({
    required this.tiles,
    required this.score,
    required this.nextId,
  });
}

class GameLogic {
  static const int size = 4;

  final Random _rng;
  final List<List<TileData?>> _grid = List.generate(
    size,
    (_) => List<TileData?>.filled(size, null),
  );

  int score = 0;
  int _nextId = 1;

  GameLogic({Random? rng}) : _rng = rng ?? Random();

  List<TileData> get tiles => [
    for (final row in _grid)
      for (final t in row)
        if (t != null) t,
  ];

  int get maxValue => tiles.fold(0, (m, t) => max(m, t.value));

  void reset() {
    _clearGrid();
    score = 0;
    _nextId = 1;
    spawnRandom();
    spawnRandom();
  }

  void _clearGrid() {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        _grid[r][c] = null;
      }
    }
  }

  /// crea una ficha (90% un 2, 10% un 4) en una celda vacía
  TileData? spawnRandom() {
    final empty = <(int, int)>[
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++)
          if (_grid[r][c] == null) (r, c),
    ];
    if (empty.isEmpty) return null;
    final p = empty[_rng.nextInt(empty.length)];
    final tile = TileData(_nextId++, _rng.nextDouble() < 0.9 ? 2 : 4, p.$1, p.$2);
    _grid[p.$1][p.$2] = tile;
    return tile;
  }

  /// posiciones de una línea, ordenadas desde el borde hacia donde se mueven
  /// las fichas
  List<(int, int)> _line(MoveDirection dir, int i) {
    switch (dir) {
      case MoveDirection.left:
        return [for (var c = 0; c < size; c++) (i, c)];
      case MoveDirection.right:
        return [for (var c = size - 1; c >= 0; c--) (i, c)];
      case MoveDirection.up:
        return [for (var r = 0; r < size; r++) (r, i)];
      case MoveDirection.down:
        return [for (var r = size - 1; r >= 0; r--) (r, i)];
    }
  }

  MoveResult move(MoveDirection dir) {
    final slides = <TileSlide>[];
    var gained = 0;
    var moved = false;

    for (var i = 0; i < size; i++) {
      final line = _line(dir, i);
      final placed = <TileData>[];
      var lastMerged = false;

      for (final p in line) {
        final tile = _grid[p.$1][p.$2];
        if (tile == null) continue;

        if (placed.isNotEmpty && !lastMerged && placed.last.value == tile.value) {
          // fusión: una sola por ficha y por movimiento.
          final survivor = placed.last;
          final dest = line[placed.length - 1];
          survivor.value *= 2;
          gained += survivor.value;
          slides.add(
            TileSlide(
              tileId: tile.id,
              toRow: dest.$1,
              toCol: dest.$2,
              absorbedInto: survivor.id,
              newValue: survivor.value,
            ),
          );
          lastMerged = true;
          moved = true;
        } else {
          final dest = line[placed.length];
          if (tile.row != dest.$1 || tile.col != dest.$2) moved = true;
          slides.add(TileSlide(tileId: tile.id, toRow: dest.$1, toCol: dest.$2));
          tile.row = dest.$1;
          tile.col = dest.$2;
          placed.add(tile);
          lastMerged = false;
        }
      }

      for (final p in line) {
        _grid[p.$1][p.$2] = null;
      }
      for (var k = 0; k < placed.length; k++) {
        final p = line[k];
        _grid[p.$1][p.$2] = placed[k];
      }
    }

    score += gained;
    final spawned = moved ? spawnRandom() : null;
    return MoveResult(
      moved: moved,
      scoreGained: gained,
      slides: slides,
      spawned: spawned,
    );
  }

  bool get canMove {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        final t = _grid[r][c];
        if (t == null) return true;
        if (c + 1 < size && _grid[r][c + 1]?.value == t.value) return true;
        if (r + 1 < size && _grid[r + 1][c]?.value == t.value) return true;
      }
    }
    return false;
  }

  // deshacer

  BoardSnapshot snapshot() => BoardSnapshot(
    tiles: [for (final t in tiles) t.copy()],
    score: score,
    nextId: _nextId,
  );

  void restore(BoardSnapshot s) {
    _clearGrid();
    for (final t in s.tiles) {
      final c = t.copy();
      _grid[c.row][c.col] = c;
    }
    score = s.score;
    _nextId = s.nextId;
  }

  // poderes que cuestan diamantes

  /// reubica todas las fichas en celdas al azar
  void shuffle() {
    final ts = tiles;
    final cells = <(int, int)>[
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++) (r, c),
    ]..shuffle(_rng);
    _clearGrid();
    for (var i = 0; i < ts.length; i++) {
      ts[i].row = cells[i].$1;
      ts[i].col = cells[i].$2;
      _grid[ts[i].row][ts[i].col] = ts[i];
    }
  }

  /// elimina las [count] fichas de menor valor (deja siempre al menos una)
  int removeSmallest(int count) {
    final ts = tiles
      ..sort((a, b) {
        final c = a.value.compareTo(b.value);
        return c != 0 ? c : a.id.compareTo(b.id);
      });
    final n = max(0, min(count, ts.length - 1));
    for (var i = 0; i < n; i++) {
      _grid[ts[i].row][ts[i].col] = null;
    }
    return n;
  }
}

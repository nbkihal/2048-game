import 'position.dart';
import 'tile.dart';

/// An immutable `size x size` grid of tiles.
///
/// Cells are stored row-major in a flat list so that indexing stays cheap and
/// `copyWith` only ever copies one list. Blocked cells (a stage twist) are
/// stored as flat indices and behave as permanent walls: no tile can rest on
/// them and no tile can slide through them.
class Board {
  Board({
    required this.size,
    required List<Tile?> cells,
    Set<int> blockedIndices = const {},
  }) : assert(size > 0, 'grid size must be positive'),
       assert(cells.length == size * size, 'cells must hold size * size slots'),
       cells = List<Tile?>.unmodifiable(cells),
       blockedIndices = Set<int>.unmodifiable(blockedIndices);

  /// An empty board, optionally with some cells walled off.
  factory Board.empty(int size, {Set<Position> blocked = const {}}) {
    return Board(
      size: size,
      cells: List<Tile?>.filled(size * size, null),
      blockedIndices: blocked.map((p) => p.row * size + p.col).toSet(),
    );
  }

  /// Test/debug helper: build a board from a value matrix, `0` meaning empty.
  /// Tile ids are assigned sequentially in reading order starting at 1.
  factory Board.fromValues(
    List<List<int>> values, {
    Set<Position> blocked = const {},
  }) {
    final size = values.length;
    assert(
      values.every((row) => row.length == size),
      'fromValues expects a square matrix',
    );
    final cells = List<Tile?>.filled(size * size, null);
    var nextId = 1;
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final value = values[row][col];
        if (value == 0) continue;
        cells[row * size + col] = Tile(
          id: nextId++,
          value: value,
          row: row,
          col: col,
        );
      }
    }
    return Board(
      size: size,
      cells: cells,
      blockedIndices: blocked.map((p) => p.row * size + p.col).toSet(),
    );
  }

  final int size;

  /// Row-major, length `size * size`. `null` means the cell is empty.
  final List<Tile?> cells;

  /// Flat indices of permanently unusable cells.
  final Set<int> blockedIndices;

  int indexOf(int row, int col) => row * size + col;

  bool contains(int row, int col) =>
      row >= 0 && row < size && col >= 0 && col < size;

  Tile? tileAt(int row, int col) => cells[indexOf(row, col)];

  Tile? tileAtPosition(Position p) => tileAt(p.row, p.col);

  bool isBlocked(int row, int col) =>
      blockedIndices.contains(indexOf(row, col));

  bool isBlockedPosition(Position p) => isBlocked(p.row, p.col);

  /// Cells that a tile could legally occupy right now.
  List<Position> get emptyCells {
    final result = <Position>[];
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        final index = indexOf(row, col);
        if (cells[index] == null && !blockedIndices.contains(index)) {
          result.add(Position(row, col));
        }
      }
    }
    return result;
  }

  Iterable<Tile> get tiles => cells.whereType<Tile>();

  int get tileCount => tiles.length;

  /// True when no usable cell is free. A full board is not necessarily a loss —
  /// merges may still be available (see `game_rules.canMove`).
  bool get isFull => emptyCells.isEmpty;

  /// Largest value on the board, or 0 when empty.
  int get highestValue =>
      tiles.fold(0, (best, tile) => tile.value > best ? tile.value : best);

  /// Blocked cells as positions, for rendering walls.
  Set<Position> get blockedPositions =>
      blockedIndices.map((i) => Position(i ~/ size, i % size)).toSet();

  Board copyWith({List<Tile?>? cells, Set<int>? blockedIndices}) {
    return Board(
      size: size,
      cells: cells ?? this.cells,
      blockedIndices: blockedIndices ?? this.blockedIndices,
    );
  }

  /// Same board with every tile's animation flag cleared. Called before a new
  /// move so the previous move's spawn/merge effects do not replay.
  Board withoutAnimationFlags() {
    return copyWith(
      cells: cells.map((tile) => tile?.withoutAnimationFlags()).toList(),
    );
  }

  /// Value matrix, `0` for empty. Mirrors [Board.fromValues].
  List<List<int>> toValues() {
    return List.generate(
      size,
      (row) => List.generate(size, (col) => tileAt(row, col)?.value ?? 0),
    );
  }

  @override
  String toString() => toValues().map((row) => row.join('\t')).join('\n');
}

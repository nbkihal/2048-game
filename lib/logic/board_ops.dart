import 'dart:math';

import '../models/board.dart';
import '../models/tile.dart';

/// Board transformations that are not moves.
///
/// Everything here is a pure function of a board: the twists (rotation, bomb
/// fuses) and the power-ups (hammer, shuffle) all produce a new board and
/// nothing else, so they are as testable as the slide itself.

/// Turns the board a quarter turn clockwise, tiles and walls alike.
///
/// Tiles keep their ids, so the UI animates every one of them travelling to its
/// new cell rather than the board blinking into a new arrangement.
Board rotateBoardClockwise(Board board) {
  final size = board.size;
  final cells = List<Tile?>.filled(size * size, null);

  for (var row = 0; row < size; row++) {
    for (var col = 0; col < size; col++) {
      final tile = board.tileAt(row, col);
      if (tile == null) continue;
      // Clockwise: (row, col) -> (col, size - 1 - row).
      final newRow = col;
      final newCol = size - 1 - row;
      cells[newRow * size + newCol] = tile.copyWith(
        row: newRow,
        col: newCol,
        isNew: false,
        mergedFrom: false,
      );
    }
  }

  final blocked = <int>{
    for (final index in board.blockedIndices)
      (index % size) * size + (size - 1 - index ~/ size),
  };

  return Board(size: size, cells: cells, blockedIndices: blocked);
}

/// Burns one move off every fuse on the board.
///
/// Fuses are allowed to reach zero rather than being clamped: zero is exactly
/// the state `game_rules.hasDetonated` looks for.
Board tickFuses(Board board) {
  if (!board.tiles.any((tile) => tile.isBomb)) return board;
  return board.copyWith(
    cells: [
      for (final tile in board.cells)
        tile == null || !tile.isBomb
            ? tile
            : tile.copyWith(fuse: tile.fuse! - 1),
    ],
  );
}

/// Turns the tile with [tileId] into a bomb with [fuse] moves on its counter.
Board armBomb(Board board, int tileId, int fuse) {
  return board.copyWith(
    cells: [
      for (final tile in board.cells)
        tile == null || tile.id != tileId ? tile : tile.copyWith(fuse: fuse),
    ],
  );
}

/// True when a bomb is already ticking, so a stage never runs two at once.
bool hasArmedBomb(Board board) => board.tiles.any((tile) => tile.isBomb);

/// Power-up: removes one tile from the board.
Board removeTile(Board board, int tileId) {
  if (!board.tiles.any((tile) => tile.id == tileId)) return board;
  return board.copyWith(
    cells: [
      for (final tile in board.cells)
        tile != null && tile.id == tileId ? null : tile,
    ],
  );
}

/// Power-up: deals the same tiles back out across the same number of cells.
///
/// Values move, ids stay with their value so the UI animates each tile to its
/// new home. A bomb keeps its fuse — a shuffle is a way out of a jam, not a way
/// to launder a bomb.
Board shuffleTiles(Board board, Random random) {
  final tiles = board.tiles.toList();
  if (tiles.length < 2) return board;

  final free = [
    for (var row = 0; row < board.size; row++)
      for (var col = 0; col < board.size; col++)
        if (!board.isBlocked(row, col)) row * board.size + col,
  ]..shuffle(random);

  final cells = List<Tile?>.filled(board.size * board.size, null);
  for (var i = 0; i < tiles.length; i++) {
    final index = free[i];
    cells[index] = tiles[i].copyWith(
      row: index ~/ board.size,
      col: index % board.size,
      isNew: false,
      mergedFrom: false,
    );
  }

  return board.copyWith(cells: cells);
}

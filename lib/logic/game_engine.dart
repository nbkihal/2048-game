import '../models/board.dart';
import '../models/direction.dart';
import '../models/position.dart';
import '../models/tile.dart';
import 'merge_logic.dart';

/// Everything a single move produced. Pure data — no Flutter, no side effects.
class MoveResult {
  const MoveResult({
    required this.board,
    required this.gainedScore,
    required this.moved,
    required this.mergedTileIds,
    required this.mergedAwayTiles,
  });

  /// The board after the move. Identical to the input board when [moved] is
  /// false.
  final Board board;

  final int gainedScore;

  /// A move only counts when at least one tile slid or merged. An invalid move
  /// must not change the score and must not trigger a spawn.
  final bool moved;

  /// Ids of tiles that are the product of a merge, for the pop animation.
  final List<int> mergedTileIds;

  /// Tiles that were absorbed by a merge, already carrying the coordinates
  /// they travelled to so the UI can animate them out.
  final List<Tile> mergedAwayTiles;
}

/// Applies one swipe to [board].
///
/// Rather than writing the slide/merge rules four times, each direction is
/// expressed as an ordering of the board's cells: the line always runs from the
/// wall the tiles pile up against toward the far edge, and `merge_logic` only
/// ever slides "toward index 0".
MoveResult move(Board board, Direction direction) {
  final lines = lineCoordinates(board.size, direction);
  final cells = List<Tile?>.filled(board.size * board.size, null);
  final mergedTileIds = <int>[];
  final mergedAwayTiles = <Tile>[];
  var gainedScore = 0;
  var moved = false;

  for (final line in lines) {
    final lineTiles = [for (final p in line) board.tileAtPosition(p)];
    final walls = [for (final p in line) board.isBlockedPosition(p)];

    final result = slideLine(lineTiles, blocked: walls);
    if (result.changed) moved = true;
    gainedScore += result.gainedScore;
    mergedTileIds.addAll(result.mergedTileIds);

    for (var i = 0; i < line.length; i++) {
      final tile = result.tiles[i];
      if (tile == null) continue;
      final position = line[i];
      cells[board.indexOf(position.row, position.col)] = tile.copyWith(
        row: position.row,
        col: position.col,
      );
    }

    for (final entry in result.absorbed) {
      final position = line[entry.destIndex];
      mergedAwayTiles.add(
        entry.tile.copyWith(row: position.row, col: position.col),
      );
    }
  }

  if (!moved) {
    return MoveResult(
      board: board,
      gainedScore: 0,
      moved: false,
      mergedTileIds: const [],
      mergedAwayTiles: const [],
    );
  }

  return MoveResult(
    board: board.copyWith(cells: cells),
    gainedScore: gainedScore,
    moved: true,
    mergedTileIds: mergedTileIds,
    mergedAwayTiles: mergedAwayTiles,
  );
}

/// Cheap check for "would this swipe do anything?" without building a board.
bool canMoveInDirection(Board board, Direction direction) =>
    move(board, direction).moved;

/// The board's cells grouped into lines, ordered so that index 0 of every line
/// is the cell nearest the edge the tiles are pushed against.
List<List<Position>> lineCoordinates(int size, Direction direction) {
  return List.generate(size, (major) {
    return List.generate(size, (minor) {
      switch (direction) {
        case Direction.left:
          return Position(major, minor);
        case Direction.right:
          return Position(major, size - 1 - minor);
        case Direction.up:
          return Position(minor, major);
        case Direction.down:
          return Position(size - 1 - minor, major);
      }
    });
  });
}

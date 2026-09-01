import 'dart:math';

import '../core/constants.dart';
import '../models/board.dart';
import '../models/position.dart';
import '../models/tile.dart';

/// Result of dropping a tile onto the board.
class SpawnResult {
  const SpawnResult({required this.board, required this.tile});

  final Board board;

  /// The tile that was placed, or `null` when there was no free cell.
  final Tile? tile;

  bool get spawned => tile != null;
}

/// Places one new tile in a random empty cell.
///
/// Blocked cells are never candidates. The value is [kSpawnLowValue] with
/// [kSpawnTwoProbability], otherwise [kSpawnHighValue]. [random] is injected so
/// tests can be deterministic.
SpawnResult spawnTile(
  Board board, {
  required int id,
  required Random random,
  int? forcedValue,
  Position? forcedPosition,
}) {
  final candidates = board.emptyCells;
  if (candidates.isEmpty) {
    return SpawnResult(board: board, tile: null);
  }

  final position =
      forcedPosition ?? candidates[random.nextInt(candidates.length)];
  assert(
    candidates.contains(position),
    'forcedPosition must point at a free, unblocked cell',
  );

  final value = forcedValue ?? randomSpawnValue(random);
  final tile = Tile(
    id: id,
    value: value,
    row: position.row,
    col: position.col,
    isNew: true,
  );

  final cells = List<Tile?>.from(board.cells);
  cells[board.indexOf(position.row, position.col)] = tile;

  return SpawnResult(
    board: board.copyWith(cells: cells),
    tile: tile,
  );
}

/// `2` with [kSpawnTwoProbability], otherwise `4`.
int randomSpawnValue(Random random) =>
    random.nextDouble() < kSpawnTwoProbability
    ? kSpawnLowValue
    : kSpawnHighValue;

/// Places [count] tiles, used when a stage starts. Returns the board and the
/// next free tile id.
({Board board, int nextId}) spawnInitialTiles(
  Board board, {
  required int firstId,
  required Random random,
  int count = kInitialTileCount,
}) {
  var current = board;
  var nextId = firstId;
  for (var i = 0; i < count; i++) {
    final result = spawnTile(current, id: nextId, random: random);
    if (!result.spawned) break;
    current = result.board;
    nextId++;
  }
  return (board: current, nextId: nextId);
}

/// Picks [count] distinct free cells to wall off when a stage starts.
Set<Position> pickRandomBlockedCells(
  int gridSize, {
  required int count,
  required Random random,
  Set<Position> exclude = const {},
}) {
  final available = <Position>[
    for (var row = 0; row < gridSize; row++)
      for (var col = 0; col < gridSize; col++)
        if (!exclude.contains(Position(row, col))) Position(row, col),
  ];
  // Never wall off the whole board: leave room for the opening tiles.
  final limit = count.clamp(
    0,
    (available.length - kInitialTileCount).clamp(0, available.length),
  );
  final picked = <Position>{};
  while (picked.length < limit && available.isNotEmpty) {
    picked.add(available.removeAt(random.nextInt(available.length)));
  }
  return picked;
}

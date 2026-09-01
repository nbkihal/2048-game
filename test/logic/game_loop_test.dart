import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/logic/game_engine.dart';
import 'package:game_2048/logic/game_rules.dart';
import 'package:game_2048/logic/spawn.dart';
import 'package:game_2048/models/board.dart';
import 'package:game_2048/models/direction.dart';
import 'package:game_2048/models/game_status.dart';
import 'package:game_2048/models/position.dart';
import 'package:game_2048/models/stage.dart';

/// Plays a stage to its conclusion with random legal swipes, asserting the
/// invariants that must hold after *every* move. This is the cheapest way to
/// catch a rule that only breaks in some board configuration.
({GameStatus status, int score, int moves}) playRandomGame(
  Stage stage, {
  required Random random,
  int maxMoves = 5000,
}) {
  final blocked = <Position>{
    ...stage.blockedCells,
    ...pickRandomBlockedCells(
      stage.gridSize,
      count: stage.randomBlockedCells,
      random: random,
      exclude: stage.blockedCells.toSet(),
    ),
  };

  var nextId = 1;
  final start = spawnInitialTiles(
    Board.empty(stage.gridSize, blocked: blocked),
    firstId: nextId,
    random: random,
  );
  var board = start.board;
  nextId = start.nextId;

  var score = 0;
  var moves = 0;
  var status = evaluateStatus(board: board, stage: stage, movesUsed: moves);

  while (status.isPlayable && moves < maxMoves) {
    final options = Direction.values
        .where((d) => canMoveInDirection(board, d))
        .toList();
    expect(options, isNotEmpty, reason: 'canMove said the game was playable');

    final before = board;
    final sumBefore = before.tiles.fold(0, (sum, t) => sum + t.value);

    final result = move(before, options[random.nextInt(options.length)]);
    expect(result.moved, isTrue);

    final spawn = spawnTile(result.board, id: nextId, random: random);
    board = spawn.board;
    if (spawn.spawned) nextId++;
    score += result.gainedScore;
    moves++;

    // --- Invariants -------------------------------------------------------
    // Merging conserves the total value on the board, so the only growth
    // comes from the tile that just spawned.
    final sumAfter = board.tiles.fold(0, (sum, t) => sum + t.value);
    expect(sumAfter, sumBefore + (spawn.tile?.value ?? 0));

    // One merge removes exactly one tile; one spawn adds one.
    expect(
      board.tileCount,
      before.tileCount - result.mergedTileIds.length + (spawn.spawned ? 1 : 0),
    );

    // Ids stay unique, otherwise the animation layer would reuse a widget.
    final ids = board.tiles.map((t) => t.id).toList();
    expect(ids.toSet(), hasLength(ids.length));

    // Every tile sits where the board says it does, and never on a wall.
    for (final tile in board.tiles) {
      expect(board.tileAt(tile.row, tile.col)!.id, tile.id);
      expect(board.isBlocked(tile.row, tile.col), isFalse);
      expect(tile.value.isEven, isTrue);
    }

    // Walls are never disturbed.
    expect(board.blockedPositions, blocked);

    status = evaluateStatus(board: board, stage: stage, movesUsed: moves);
  }

  expect(moves, lessThan(maxMoves), reason: 'the game never terminated');
  return (status: status, score: score, moves: moves);
}

void main() {
  group('full game loop', () {
    test('a 4x4 stage always terminates with a definite outcome', () {
      for (var seed = 0; seed < 25; seed++) {
        const stage = Stage(
          id: 1,
          name: 'First Steps',
          gridSize: 4,
          targetTile: 64,
        );

        final outcome = playRandomGame(stage, random: Random(seed));

        expect(outcome.status.isOver, isTrue, reason: 'seed $seed');
        expect(outcome.score, greaterThanOrEqualTo(0));
      }
    });

    test('runs on every grid size the stage table uses', () {
      for (final size in [3, 4, 5]) {
        final stage = Stage(
          id: size,
          name: '${size}x$size',
          gridSize: size,
          targetTile: 64,
        );

        final outcome = playRandomGame(stage, random: Random(size * 31));

        expect(outcome.status.isOver, isTrue, reason: 'grid $size');
        expect(outcome.moves, greaterThan(0));
      }
    });

    test('an endless stage runs until the board deadlocks', () {
      const stage = Stage(
        id: 10,
        name: 'Endless',
        gridSize: 4,
        targetTile: null,
      );

      final outcome = playRandomGame(stage, random: Random(99));

      expect(outcome.status, GameStatus.lost);
    });

    test('a move-limited stage never exceeds its budget', () {
      const stage = Stage(
        id: 6,
        name: 'Move Budget',
        gridSize: 4,
        targetTile: 2048,
        moveLimit: 12,
      );

      final outcome = playRandomGame(stage, random: Random(4));

      expect(outcome.moves, lessThanOrEqualTo(12));
      expect(outcome.status, GameStatus.lost);
    });

    test('a stage with walls keeps them for the whole game', () {
      const stage = Stage(
        id: 8,
        name: 'Frozen Tile',
        gridSize: 4,
        targetTile: 128,
        randomBlockedCells: 1,
      );

      for (var seed = 0; seed < 10; seed++) {
        final outcome = playRandomGame(stage, random: Random(seed));
        expect(outcome.status.isOver, isTrue, reason: 'seed $seed');
      }
    });
  });
}

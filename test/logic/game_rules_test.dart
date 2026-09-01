import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/logic/game_rules.dart';
import 'package:game_2048/models/board.dart';
import 'package:game_2048/models/game_status.dart';
import 'package:game_2048/models/position.dart';
import 'package:game_2048/models/stage.dart';

/// A plain 4x4 stage with no twist.
const plainStage = Stage(id: 1, name: 'Test', gridSize: 4, targetTile: 64);

/// A board with no equal neighbours anywhere — genuinely stuck.
Board deadlockedBoard() => Board.fromValues([
  [2, 4, 2, 4],
  [4, 2, 4, 2],
  [2, 4, 2, 4],
  [4, 2, 4, 2],
]);

void main() {
  group('hasReachedTarget', () {
    test('false while every tile is below the target', () {
      final board = Board.fromValues([
        [2, 4, 8, 16],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      expect(hasReachedTarget(board, 64), isFalse);
    });

    test('true as soon as a tile hits the target', () {
      final board = Board.fromValues([
        [2, 4, 8, 64],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      expect(hasReachedTarget(board, 64), isTrue);
    });

    test('true when a tile is past the target', () {
      final board = Board.fromValues([
        [128, 0],
        [0, 0],
      ]);

      expect(hasReachedTarget(board, 64), isTrue);
    });

    test('an endless stage is never won', () {
      final board = Board.fromValues([
        [4096, 0],
        [0, 0],
      ]);

      expect(hasReachedTarget(board, null), isFalse);
    });
  });

  group('canMove', () {
    test('true while an empty cell remains', () {
      final board = Board.fromValues([
        [2, 4, 8, 16],
        [4, 8, 16, 32],
        [8, 16, 32, 64],
        [16, 32, 64, 0],
      ]);

      expect(canMove(board), isTrue);
    });

    test('true on a full board that still has a merge', () {
      final board = Board.fromValues([
        [2, 2, 4, 8],
        [4, 8, 16, 32],
        [8, 16, 32, 64],
        [16, 32, 64, 128],
      ]);

      expect(board.isFull, isTrue);
      expect(canMove(board), isTrue);
    });

    test('false only when the board is full with no merge anywhere', () {
      final board = deadlockedBoard();

      expect(board.isFull, isTrue);
      expect(canMove(board), isFalse);
    });

    test('walls can create a deadlock on a board that has free cells', () {
      // The two free cells are walled off, and no neighbours match.
      final board = Board.fromValues(
        [
          [2, 4, 0],
          [4, 2, 4],
          [2, 4, 2],
        ],
        blocked: {const Position(0, 2)},
      );

      expect(canMove(board), isFalse);
    });
  });

  group('move-limit twist', () {
    const budgetStage = Stage(
      id: 6,
      name: 'Move Budget',
      gridSize: 4,
      targetTile: 256,
      moveLimit: 3,
    );

    test('hasMovesLeft counts down to the limit', () {
      expect(hasMovesLeft(budgetStage, 0), isTrue);
      expect(hasMovesLeft(budgetStage, 2), isTrue);
      expect(hasMovesLeft(budgetStage, 3), isFalse);
      expect(hasMovesLeft(budgetStage, 4), isFalse);
    });

    test('an unlimited stage always has moves left', () {
      expect(hasMovesLeft(plainStage, 9999), isTrue);
      expect(movesRemaining(plainStage, 9999), isNull);
    });

    test('movesRemaining never goes negative', () {
      expect(movesRemaining(budgetStage, 0), 3);
      expect(movesRemaining(budgetStage, 3), 0);
      expect(movesRemaining(budgetStage, 5), 0);
    });
  });

  group('evaluateStatus', () {
    final openBoard = Board.fromValues([
      [2, 4, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);

    test('idle before the first move', () {
      final status = evaluateStatus(
        board: openBoard,
        stage: plainStage,
        movesUsed: 0,
      );

      expect(status, GameStatus.idle);
      expect(status.isPlayable, isTrue);
    });

    test('playing once the player has moved', () {
      expect(
        evaluateStatus(board: openBoard, stage: plainStage, movesUsed: 1),
        GameStatus.playing,
      );
    });

    test('won when the target is on the board', () {
      final board = Board.fromValues([
        [64, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      final status = evaluateStatus(
        board: board,
        stage: plainStage,
        movesUsed: 8,
      );

      expect(status, GameStatus.won);
      expect(status.isOver, isTrue);
    });

    test('lost only when truly stuck', () {
      expect(
        evaluateStatus(
          board: deadlockedBoard(),
          stage: plainStage,
          movesUsed: 20,
        ),
        GameStatus.lost,
      );
    });

    test('a full board with a merge left is still playing', () {
      // Full, one merge available, and nothing has reached the 64 target yet.
      final board = Board.fromValues([
        [2, 2, 4, 8],
        [4, 8, 16, 32],
        [8, 16, 32, 16],
        [16, 32, 16, 32],
      ]);

      expect(
        evaluateStatus(board: board, stage: plainStage, movesUsed: 30),
        GameStatus.playing,
      );
    });

    test('an endless stage only ever ends by getting stuck', () {
      const endless = Stage(
        id: 10,
        name: 'Endless',
        gridSize: 4,
        targetTile: null,
      );

      expect(
        evaluateStatus(board: openBoard, stage: endless, movesUsed: 50),
        GameStatus.playing,
      );
      expect(
        evaluateStatus(board: deadlockedBoard(), stage: endless, movesUsed: 50),
        GameStatus.lost,
      );
    });

    group('with a move budget', () {
      const budgetStage = Stage(
        id: 6,
        name: 'Move Budget',
        gridSize: 4,
        targetTile: 64,
        moveLimit: 5,
      );

      test('lost when the budget runs out short of the target', () {
        expect(
          evaluateStatus(board: openBoard, stage: budgetStage, movesUsed: 5),
          GameStatus.lost,
        );
      });

      test('still playing with moves to spare', () {
        expect(
          evaluateStatus(board: openBoard, stage: budgetStage, movesUsed: 4),
          GameStatus.playing,
        );
      });

      test('reaching the target on the final move still wins', () {
        final board = Board.fromValues([
          [64, 4, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]);

        expect(
          evaluateStatus(board: board, stage: budgetStage, movesUsed: 5),
          GameStatus.won,
        );
      });
    });

    test('blocked cells can end the game early', () {
      const wallStage = Stage(
        id: 8,
        name: 'Frozen Tile',
        gridSize: 3,
        targetTile: 512,
        blockedCells: [Position(0, 2)],
      );
      final board = Board.fromValues(
        [
          [2, 4, 0],
          [4, 2, 4],
          [2, 4, 2],
        ],
        blocked: {const Position(0, 2)},
      );

      expect(
        evaluateStatus(board: board, stage: wallStage, movesUsed: 12),
        GameStatus.lost,
      );
    });
  });

  group('targetProgress', () {
    test('advances one step per doubling', () {
      Board withHighest(int value) => Board.fromValues([
        [value, 0],
        [0, 0],
      ]);

      // Target 64 is five doublings away from 2.
      expect(targetProgress(withHighest(2), 64), closeTo(0.0, 0.001));
      expect(targetProgress(withHighest(8), 64), closeTo(0.4, 0.001));
      expect(targetProgress(withHighest(64), 64), 1.0);
      expect(targetProgress(withHighest(128), 64), 1.0);
    });

    test('an empty board has made no progress', () {
      expect(targetProgress(Board.empty(4), 64), 0.0);
    });

    test('an endless stage reports no progress bar', () {
      final board = Board.fromValues([
        [1024, 0],
        [0, 0],
      ]);

      expect(targetProgress(board, null), 0.0);
    });
  });

  group('Stage metadata', () {
    test('reports its twists', () {
      const plain = Stage(id: 1, name: 'A', gridSize: 4, targetTile: 64);
      const budget = Stage(
        id: 2,
        name: 'B',
        gridSize: 4,
        targetTile: 64,
        moveLimit: 20,
      );
      const walls = Stage(
        id: 3,
        name: 'C',
        gridSize: 4,
        targetTile: 64,
        randomBlockedCells: 1,
      );
      const endless = Stage(id: 4, name: 'D', gridSize: 4, targetTile: null);

      expect(plain.hasTwist, isFalse);
      expect(budget.hasTwist, isTrue);
      expect(budget.hasMoveLimit, isTrue);
      expect(walls.hasTwist, isTrue);
      expect(walls.hasBlockedCells, isTrue);
      expect(endless.isEndless, isTrue);
      expect(plain.isEndless, isFalse);
    });
  });
}

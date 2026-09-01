import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/logic/board_ops.dart';
import 'package:game_2048/logic/game_engine.dart';
import 'package:game_2048/logic/game_rules.dart';
import 'package:game_2048/models/board.dart';
import 'package:game_2048/models/direction.dart';
import 'package:game_2048/models/game_status.dart';
import 'package:game_2048/models/position.dart';
import 'package:game_2048/models/stage.dart';

void main() {
  group('rotateBoardClockwise', () {
    test('turns the value matrix a quarter turn', () {
      final board = Board.fromValues([
        [2, 4],
        [8, 16],
      ]);

      expect(rotateBoardClockwise(board).toValues(), [
        [8, 2],
        [16, 4],
      ]);
    });

    test('keeps every tile id, so the UI can animate the turn', () {
      final board = Board.fromValues([
        [2, 4],
        [8, 16],
      ]);
      final before = {for (final t in board.tiles) t.id: t.value};

      final after = {
        for (final t in rotateBoardClockwise(board).tiles) t.id: t.value,
      };

      expect(after, before);
    });

    test('carries the walls round with the tiles', () {
      final board = Board.fromValues(
        [
          [2, 0],
          [0, 0],
        ],
        blocked: {const Position(0, 0)},
      );

      final rotated = rotateBoardClockwise(board);

      expect(rotated.isBlocked(0, 1), isTrue);
      expect(rotated.isBlocked(0, 0), isFalse);
    });

    test('four turns are the identity', () {
      final board = Board.fromValues([
        [2, 4, 8],
        [16, 0, 32],
        [64, 128, 0],
      ]);

      var turned = board;
      for (var i = 0; i < 4; i++) {
        turned = rotateBoardClockwise(turned);
      }

      expect(turned.toValues(), board.toValues());
    });
  });

  group('fuses', () {
    final stage = const Stage(
      id: 1,
      name: 'Bomb',
      gridSize: 2,
      targetTile: 2048,
      bombFuse: 3,
    );

    test('a board with no bomb is returned untouched', () {
      final board = Board.fromValues([
        [2, 4],
        [0, 0],
      ]);
      expect(identical(tickFuses(board), board), isTrue);
    });

    test('arming marks exactly one tile', () {
      final board = Board.fromValues([
        [2, 4],
        [0, 0],
      ]);
      final armed = armBomb(board, board.tiles.first.id, 3);

      expect(hasArmedBomb(armed), isTrue);
      expect(armed.tiles.where((t) => t.isBomb).length, 1);
      expect(armed.tiles.first.fuse, 3);
    });

    test('each tick burns one move off the fuse', () {
      final board = armBomb(
        Board.fromValues([
          [2, 0],
          [0, 0],
        ]),
        1,
        3,
      );

      expect(tickFuses(board).tiles.first.fuse, 2);
      expect(tickFuses(tickFuses(board)).tiles.first.fuse, 1);
    });

    test('a fuse at zero ends the attempt', () {
      var board = armBomb(
        Board.fromValues([
          [2, 0],
          [0, 4],
        ]),
        1,
        1,
      );
      expect(hasDetonated(board), isFalse);

      board = tickFuses(board);

      expect(hasDetonated(board), isTrue);
      expect(
        evaluateStatus(board: board, stage: stage, movesUsed: 5),
        GameStatus.lost,
      );
    });

    test('reaching the target beats a bomb landing on the same move', () {
      final board = armBomb(
        Board.fromValues([
          [2048, 0],
          [0, 4],
        ]),
        2,
        0,
      );

      expect(
        evaluateStatus(board: board, stage: stage, movesUsed: 5),
        GameStatus.won,
      );
    });
  });

  group('the hammer', () {
    test('takes exactly one tile off the board', () {
      final board = Board.fromValues([
        [2, 4],
        [8, 16],
      ]);
      final target = board.tileAt(0, 1)!;

      final after = removeTile(board, target.id);

      expect(after.tileCount, 3);
      expect(after.tileAt(0, 1), isNull);
      expect(after.toValues(), [
        [2, 0],
        [8, 16],
      ]);
    });

    test('an unknown id changes nothing', () {
      final board = Board.fromValues([
        [2, 4],
        [0, 0],
      ]);
      expect(identical(removeTile(board, 999), board), isTrue);
    });

    test('can open a board that had no move left', () {
      final board = Board.fromValues([
        [2, 4],
        [8, 16],
      ]);
      expect(canMove(board), isFalse);

      expect(canMove(removeTile(board, board.tileAt(1, 1)!.id)), isTrue);
    });
  });

  group('the shuffle', () {
    test('keeps every tile, only moving it', () {
      final board = Board.fromValues([
        [2, 4, 8],
        [16, 32, 64],
        [128, 0, 0],
      ]);

      final after = shuffleTiles(board, Random(7));

      expect(after.tileCount, board.tileCount);
      expect(
        after.tiles.map((t) => t.value).toList()..sort(),
        board.tiles.map((t) => t.value).toList()..sort(),
      );
    });

    test('never lands a tile on a wall', () {
      final board = Board.fromValues(
        [
          [2, 4, 8],
          [16, 32, 64],
          [128, 0, 0],
        ],
        blocked: {const Position(2, 2)},
      );

      final after = shuffleTiles(board, Random(3));

      expect(after.tileAt(2, 2), isNull);
      expect(after.blockedIndices, board.blockedIndices);
    });

    test('a tile keeps its own coordinates in sync with its cell', () {
      final board = Board.fromValues([
        [2, 4],
        [8, 16],
      ]);

      final after = shuffleTiles(board, Random(11));

      for (var row = 0; row < after.size; row++) {
        for (var col = 0; col < after.size; col++) {
          final tile = after.tileAt(row, col);
          if (tile == null) continue;
          expect(tile.row, row);
          expect(tile.col, col);
        }
      }
    });

    test('a bomb keeps its fuse through the re-deal', () {
      final board = armBomb(
        Board.fromValues([
          [2, 4],
          [8, 16],
        ]),
        1,
        5,
      );

      final after = shuffleTiles(board, Random(5));

      expect(after.tiles.where((t) => t.isBomb).length, 1);
      expect(after.tiles.firstWhere((t) => t.isBomb).fuse, 5);
    });
  });

  group('merging a bomb', () {
    // The merge product is a fresh tile, so the fuse must not ride along on it.
    // Which of the pair carried the bomb depends on the swipe direction, and
    // both orders have to defuse.
    test('defuses it when the bomb is the tile that stays put', () {
      final board = armBomb(
        Board.fromValues([
          [2, 2, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
        1,
        4,
      );

      final after = move(board, Direction.left).board;

      expect(after.toValues()[0][0], 4);
      expect(after.tiles.any((t) => t.isBomb), isFalse);
      expect(hasDetonated(after), isFalse);
    });

    test('defuses it when the bomb is the tile that is absorbed', () {
      final board = armBomb(
        Board.fromValues([
          [2, 2, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
        2,
        4,
      );

      final after = move(board, Direction.left).board;

      expect(after.toValues()[0][0], 4);
      expect(after.tiles.any((t) => t.isBomb), isFalse);
    });

    test('a bomb that only slides keeps ticking', () {
      final board = armBomb(
        Board.fromValues([
          [0, 0, 0, 2],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ]),
        1,
        4,
      );

      final after = tickFuses(move(board, Direction.left).board);

      expect(after.tiles.single.fuse, 3);
    });
  });
}

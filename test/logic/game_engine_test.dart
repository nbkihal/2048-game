import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/logic/game_engine.dart';
import 'package:game_2048/models/board.dart';
import 'package:game_2048/models/direction.dart';
import 'package:game_2048/models/position.dart';

void main() {
  group('move — direction handling on 4x4', () {
    final board = Board.fromValues([
      [2, 0, 0, 2],
      [0, 4, 4, 0],
      [0, 0, 0, 0],
      [8, 0, 0, 0],
    ]);

    test('left', () {
      final result = move(board, Direction.left);

      expect(result.board.toValues(), [
        [4, 0, 0, 0],
        [8, 0, 0, 0],
        [0, 0, 0, 0],
        [8, 0, 0, 0],
      ]);
      expect(result.gainedScore, 12);
      expect(result.moved, isTrue);
    });

    test('right', () {
      final result = move(board, Direction.right);

      expect(result.board.toValues(), [
        [0, 0, 0, 4],
        [0, 0, 0, 8],
        [0, 0, 0, 0],
        [0, 0, 0, 8],
      ]);
      expect(result.gainedScore, 12);
    });

    test('up', () {
      final result = move(board, Direction.up);

      expect(result.board.toValues(), [
        [2, 4, 4, 2],
        [8, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      expect(result.gainedScore, 0);
    });

    test('down', () {
      final result = move(board, Direction.down);

      expect(result.board.toValues(), [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [2, 0, 0, 0],
        [8, 4, 4, 2],
      ]);
      expect(result.gainedScore, 0);
    });
  });

  group('move — validity', () {
    test('a blocked move changes nothing and scores nothing', () {
      final board = Board.fromValues([
        [2, 4, 2, 4],
        [4, 2, 4, 2],
        [2, 4, 2, 4],
        [4, 2, 4, 2],
      ]);

      final result = move(board, Direction.left);

      expect(result.moved, isFalse);
      expect(result.gainedScore, 0);
      expect(result.mergedTileIds, isEmpty);
      expect(result.mergedAwayTiles, isEmpty);
      expect(identical(result.board, board), isTrue);
    });

    test('a move is valid when a single tile slides', () {
      final board = Board.fromValues([
        [0, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      expect(move(board, Direction.left).moved, isTrue);
      expect(move(board, Direction.up).moved, isFalse);
    });

    test('canMoveInDirection agrees with move', () {
      final board = Board.fromValues([
        [2, 0],
        [0, 0],
      ]);

      expect(canMoveInDirection(board, Direction.right), isTrue);
      expect(canMoveInDirection(board, Direction.left), isFalse);
      expect(canMoveInDirection(board, Direction.up), isFalse);
      expect(canMoveInDirection(board, Direction.down), isTrue);
    });
  });

  group('move — works for any grid size', () {
    test('3x3', () {
      final board = Board.fromValues([
        [2, 2, 2],
        [0, 0, 0],
        [4, 0, 4],
      ]);

      final result = move(board, Direction.left);

      expect(result.board.toValues(), [
        [4, 2, 0],
        [0, 0, 0],
        [8, 0, 0],
      ]);
      expect(result.gainedScore, 12);
    });

    test('5x5', () {
      final board = Board.fromValues([
        [2, 2, 2, 2, 2],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0],
        [0, 0, 0, 0, 16],
      ]);

      final result = move(board, Direction.left);

      expect(result.board.toValues().first, [4, 4, 2, 0, 0]);
      expect(result.board.toValues().last, [16, 0, 0, 0, 0]);
      expect(result.gainedScore, 8);
    });

    test('6x6 keeps the one-merge-per-tile cap on a long line', () {
      final board = Board.fromValues([
        [2, 2, 2, 2, 2, 2],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0],
      ]);

      final result = move(board, Direction.left);

      expect(result.board.toValues().first, [4, 4, 4, 0, 0, 0]);
      expect(result.gainedScore, 12);
    });
  });

  group('move — tile identity and animation data', () {
    test('a sliding tile keeps its id and gets new coordinates', () {
      final board = Board.fromValues([
        [0, 0, 0, 8],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      final original = board.tileAt(0, 3)!;

      final moved = move(board, Direction.left).board.tileAt(0, 0)!;

      expect(moved.id, original.id);
      expect(moved.value, 8);
      expect(moved.row, 0);
      expect(moved.col, 0);
    });

    test('merged tiles are reported for the pop animation', () {
      final board = Board.fromValues([
        [2, 2, 0, 0],
        [4, 4, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);

      final result = move(board, Direction.left);

      expect(result.mergedTileIds, hasLength(2));
      expect(result.mergedTileIds.toSet(), {
        board.tileAt(0, 0)!.id,
        board.tileAt(1, 0)!.id,
      });
      expect(result.board.tileAt(0, 0)!.mergedFrom, isTrue);
    });

    test('absorbed tiles carry the coordinates they travelled to', () {
      final board = Board.fromValues([
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 2, 2],
      ]);
      final absorbedSource = board.tileAt(3, 3)!;

      final result = move(board, Direction.left);

      expect(result.mergedAwayTiles, hasLength(1));
      final away = result.mergedAwayTiles.single;
      expect(away.id, absorbedSource.id);
      expect(away.row, 3);
      expect(away.col, 0);
      // The absorbed tile is gone from the board itself.
      expect(result.board.tiles.map((t) => t.id), isNot(contains(away.id)));
    });

    test('the resulting board never keeps stale animation flags', () {
      var board = Board.fromValues([
        [2, 2, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ]);
      board = move(board, Direction.left).board;
      expect(board.tileAt(0, 0)!.mergedFrom, isTrue);

      // A follow-up move that only slides must clear the merge flag.
      final next = move(board, Direction.down).board;
      expect(next.tileAt(3, 0)!.mergedFrom, isFalse);
    });
  });

  group('move — blocked cells', () {
    test('a tile stops just past the wall instead of reaching the edge', () {
      final board = Board.fromValues(
        [
          [0, 0, 0, 2],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
        blocked: {const Position(0, 1)},
      );

      final result = move(board, Direction.left);

      expect(result.board.toValues().first, [0, 0, 2, 0]);
      expect(result.moved, isTrue);
    });

    test('tiles never merge across a wall', () {
      final board = Board.fromValues(
        [
          [2, 0, 0, 2],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
        blocked: {const Position(0, 2)},
      );

      final result = move(board, Direction.left);

      expect(result.board.toValues().first, [2, 0, 0, 2]);
      expect(result.moved, isFalse);
      expect(result.gainedScore, 0);
    });

    test('walls survive a move', () {
      final board = Board.fromValues(
        [
          [0, 0, 0],
          [0, 0, 0],
          [4, 0, 0],
        ],
        blocked: {const Position(1, 1)},
      );

      final result = move(board, Direction.up);

      expect(result.board.isBlocked(1, 1), isTrue);
      expect(result.board.blockedPositions, {const Position(1, 1)});
    });

    test('a wall can make an otherwise valid swipe illegal', () {
      final board = Board.fromValues(
        [
          [4, 0, 0, 4],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
          [0, 0, 0, 0],
        ],
        blocked: {const Position(0, 1), const Position(0, 2)},
      );

      final result = move(board, Direction.right);

      expect(result.board.toValues().first, [4, 0, 0, 4]);
      expect(result.moved, isFalse);
    });
  });

  group('lineCoordinates', () {
    test('left lines start at column 0', () {
      final lines = lineCoordinates(3, Direction.left);

      expect(lines, hasLength(3));
      expect(lines.first.first, const Position(0, 0));
      expect(lines.first.last, const Position(0, 2));
    });

    test('down lines start at the bottom row', () {
      final lines = lineCoordinates(3, Direction.down);

      expect(lines.first.first, const Position(2, 0));
      expect(lines.first.last, const Position(0, 0));
    });

    test('every direction covers every cell exactly once', () {
      for (final direction in Direction.values) {
        final all = lineCoordinates(4, direction).expand((l) => l).toSet();
        expect(all, hasLength(16), reason: '$direction');
      }
    });
  });
}

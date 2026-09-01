import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/core/constants.dart';
import 'package:game_2048/logic/spawn.dart';
import 'package:game_2048/models/board.dart';
import 'package:game_2048/models/position.dart';

import 'test_helpers.dart';

void main() {
  group('spawnTile — placement', () {
    test('only ever lands on an empty cell', () {
      final board = Board.fromValues([
        [2, 4, 8],
        [16, 0, 32],
        [64, 128, 256],
      ]);
      final random = Random(7);

      for (var attempt = 0; attempt < 200; attempt++) {
        final result = spawnTile(board, id: 100, random: random);

        expect(result.spawned, isTrue);
        expect(result.tile!.row, 1);
        expect(result.tile!.col, 1);
      }
    });

    test('never lands on a blocked cell', () {
      // Only (0,0) is free; (0,1) is walled, the rest is occupied.
      final board = Board.fromValues(
        [
          [0, 0],
          [2, 4],
        ],
        blocked: {const Position(0, 1)},
      );
      final random = Random(3);

      for (var attempt = 0; attempt < 200; attempt++) {
        final tile = spawnTile(board, id: 1, random: random).tile!;
        expect(Position(tile.row, tile.col), const Position(0, 0));
      }
    });

    test('spawning does not disturb existing tiles', () {
      final board = Board.fromValues([
        [2, 0],
        [0, 4],
      ]);

      final result = spawnTile(board, id: 99, random: Random(1));

      expect(result.board.tileAt(0, 0)!.value, 2);
      expect(result.board.tileAt(1, 1)!.value, 4);
      expect(result.board.tileCount, 3);
    });

    test('reports no spawn when the board is full', () {
      final board = Board.fromValues([
        [2, 4],
        [8, 16],
      ]);

      final result = spawnTile(board, id: 1, random: Random(1));

      expect(result.spawned, isFalse);
      expect(result.tile, isNull);
      expect(identical(result.board, board), isTrue);
    });

    test('reports no spawn when every free cell is blocked', () {
      final board = Board.fromValues(
        [
          [0, 4],
          [8, 16],
        ],
        blocked: {const Position(0, 0)},
      );

      expect(spawnTile(board, id: 1, random: Random(1)).spawned, isFalse);
    });

    test('a spawned tile is flagged for the spawn animation', () {
      final board = Board.empty(4);

      final tile = spawnTile(board, id: 42, random: Random(1)).tile!;

      expect(tile.isNew, isTrue);
      expect(tile.mergedFrom, isFalse);
      expect(tile.id, 42);
    });
  });

  group('spawnTile — value distribution', () {
    test('spawns a 2 below the probability threshold', () {
      final board = Board.empty(4);
      final random = FixedRandom(doubleValue: kSpawnTwoProbability - 0.01);

      expect(spawnTile(board, id: 1, random: random).tile!.value, 2);
    });

    test('spawns a 4 at or above the probability threshold', () {
      final board = Board.empty(4);
      final random = FixedRandom(doubleValue: kSpawnTwoProbability);

      expect(spawnTile(board, id: 1, random: random).tile!.value, 4);
    });

    test('only ever produces 2 or 4', () {
      final random = Random(11);

      for (var i = 0; i < 500; i++) {
        expect(randomSpawnValue(random), anyOf(2, 4));
      }
    });

    test('roughly matches the configured 90/10 split over many runs', () {
      final random = Random(2048);
      const runs = 20000;
      var twos = 0;

      for (var i = 0; i < runs; i++) {
        if (randomSpawnValue(random) == 2) twos++;
      }

      final ratio = twos / runs;
      expect(ratio, closeTo(kSpawnTwoProbability, 0.02));
    });
  });

  group('spawnInitialTiles', () {
    test('places the requested number of tiles with distinct ids', () {
      final result = spawnInitialTiles(
        Board.empty(4),
        firstId: 1,
        random: Random(5),
      );

      expect(result.board.tileCount, kInitialTileCount);
      expect(result.nextId, 1 + kInitialTileCount);
      expect(
        result.board.tiles.map((t) => t.id).toSet(),
        hasLength(kInitialTileCount),
      );
    });

    test('stops early when the board runs out of room', () {
      final board = Board.fromValues([
        [0, 2],
        [4, 8],
      ]);

      final result = spawnInitialTiles(
        board,
        firstId: 10,
        random: Random(5),
        count: 3,
      );

      expect(result.board.isFull, isTrue);
      expect(result.nextId, 11);
    });
  });

  group('pickRandomBlockedCells', () {
    test('returns the requested number of distinct cells', () {
      final picked = pickRandomBlockedCells(4, count: 3, random: Random(9));

      expect(picked, hasLength(3));
    });

    test('honours the exclusion set', () {
      final excluded = {const Position(0, 0), const Position(0, 1)};

      final picked = pickRandomBlockedCells(
        3,
        count: 7,
        random: Random(9),
        exclude: excluded,
      );

      expect(picked.intersection(excluded), isEmpty);
    });

    test('always leaves room for the opening tiles', () {
      final picked = pickRandomBlockedCells(3, count: 99, random: Random(9));

      expect(picked, hasLength(9 - kInitialTileCount));
    });

    test('a count of zero walls nothing off', () {
      expect(pickRandomBlockedCells(4, count: 0, random: Random(9)), isEmpty);
    });
  });
}

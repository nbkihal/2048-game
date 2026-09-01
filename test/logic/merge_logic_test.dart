import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/logic/merge_logic.dart';
import 'package:game_2048/models/tile.dart';

import 'test_helpers.dart';

void main() {
  group('slideLine — compacting', () {
    test('removes gaps without merging', () {
      final result = slideLine(lineOf([0, 2, 0, 4]));

      expect(valuesOf(result.tiles), [2, 4, 0, 0]);
      expect(result.gainedScore, 0);
      expect(result.mergedTileIds, isEmpty);
      expect(result.changed, isTrue);
    });

    test('an already-packed line with no merges is unchanged', () {
      final result = slideLine(lineOf([2, 4, 2, 4]));

      expect(valuesOf(result.tiles), [2, 4, 2, 4]);
      expect(result.changed, isFalse);
      expect(result.gainedScore, 0);
    });

    test('an empty line is unchanged', () {
      final result = slideLine(lineOf([0, 0, 0, 0]));

      expect(valuesOf(result.tiles), [0, 0, 0, 0]);
      expect(result.changed, isFalse);
    });
  });

  group('slideLine — merging', () {
    test('merges a single pair and scores the new value', () {
      final result = slideLine(lineOf([2, 2, 0, 0]));

      expect(valuesOf(result.tiles), [4, 0, 0, 0]);
      expect(result.gainedScore, 4);
      expect(result.mergedTileIds, hasLength(1));
      expect(result.changed, isTrue);
    });

    test('merges across a gap', () {
      final result = slideLine(lineOf([2, 0, 0, 2]));

      expect(valuesOf(result.tiles), [4, 0, 0, 0]);
      expect(result.gainedScore, 4);
    });

    test('caps merges at one per tile: [2,2,2,2] -> [4,4]', () {
      final result = slideLine(lineOf([2, 2, 2, 2]));

      expect(valuesOf(result.tiles), [4, 4, 0, 0]);
      expect(result.gainedScore, 8);
      expect(result.mergedTileIds, hasLength(2));
    });

    test('a merge result never re-merges in the same move', () {
      // [4,4,8] would become [8,8] and must NOT collapse further to [16].
      final result = slideLine(lineOf([4, 4, 8, 0]));

      expect(valuesOf(result.tiles), [8, 8, 0, 0]);
      expect(result.gainedScore, 8);
    });

    test('merges the leading pair first', () {
      final result = slideLine(lineOf([2, 2, 2, 0]));

      expect(valuesOf(result.tiles), [4, 2, 0, 0]);
      expect(result.gainedScore, 4);
    });

    test('leaves an unmatched leader alone', () {
      final result = slideLine(lineOf([4, 2, 2, 0]));

      expect(valuesOf(result.tiles), [4, 4, 0, 0]);
      expect(result.gainedScore, 4);
    });

    test('scores every merge in the line', () {
      final result = slideLine(lineOf([4, 4, 8, 8]));

      expect(valuesOf(result.tiles), [8, 16, 0, 0]);
      expect(result.gainedScore, 24);
    });
  });

  group('slideLine — tile identity', () {
    test('a sliding tile keeps its id', () {
      final line = lineOf([0, 0, 0, 8]);
      final result = slideLine(line);

      expect(result.tiles.first!.id, line[3]!.id);
    });

    test('a merged tile keeps the leading tile id and is flagged', () {
      final line = lineOf([2, 2, 0, 0]);
      final result = slideLine(line);

      final merged = result.tiles.first!;
      expect(merged.id, line[0]!.id);
      expect(merged.mergedFrom, isTrue);
      expect(merged.isNew, isFalse);
      expect(result.mergedTileIds, [line[0]!.id]);
    });

    test('the absorbed tile is reported with the cell it travelled into', () {
      final line = lineOf([0, 2, 0, 2]);
      final result = slideLine(line);

      expect(result.absorbed, hasLength(1));
      expect(result.absorbed.single.tile.id, line[3]!.id);
      expect(result.absorbed.single.destIndex, 0);
    });

    test('animation flags from a previous move are cleared', () {
      final line = <Tile?>[
        null,
        const Tile(id: 1, value: 2, row: 0, col: 1, isNew: true),
        const Tile(id: 2, value: 4, row: 0, col: 2, mergedFrom: true),
        null,
      ];

      final result = slideLine(line);

      expect(result.tiles[0]!.isNew, isFalse);
      expect(result.tiles[1]!.mergedFrom, isFalse);
    });
  });

  group('slideLine — blocked cells', () {
    test('a wall keeps tiles on their own side', () {
      // [2, wall, 2] -> nothing can move, no merge across the wall.
      final result = slideLine(
        lineOf([2, 0, 2]),
        blocked: [false, true, false],
      );

      expect(valuesOf(result.tiles), [2, 0, 2]);
      expect(result.changed, isFalse);
      expect(result.gainedScore, 0);
    });

    test('each side of a wall compacts independently', () {
      final result = slideLine(
        lineOf([0, 2, 0, 2, 2]),
        blocked: [false, false, true, false, false],
      );

      expect(valuesOf(result.tiles), [2, 0, 0, 4, 0]);
      expect(result.gainedScore, 4);
      expect(result.changed, isTrue);
    });

    test('a tile never comes to rest on a wall', () {
      final result = slideLine(
        lineOf([0, 0, 4]),
        blocked: [true, false, false],
      );

      expect(valuesOf(result.tiles), [0, 4, 0]);
    });
  });
}

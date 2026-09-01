import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/data/skins_data.dart';
import 'package:game_2048/data/stages_data.dart';

/// The stage tables are pure data, and every screen trusts their shape. These
/// guard the invariants the rest of the app assumes.
void main() {
  group('the campaign', () {
    test('ids are unique across every board, campaign and endless', () {
      final ids = kAllStages.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('opens on a stage that needs no unlock', () {
      expect(kStages.first.unlockedByDefault, isTrue);
    });

    test('every campaign stage has a target to reach', () {
      for (final stage in kStages) {
        expect(stage.targetTile, isNotNull, reason: '${stage.name} is endless');
      }
    });

    test('covers a spread of board sizes', () {
      // No 3x3: the smallest target on the ladder is 1024, whose chain needs
      // ten cells and a 3x3 only has nine. That board lives in Endless.
      expect(kStages.map((s) => s.gridSize).toSet(), {4, 5, 6});
      expect(kEndlessStages.map((s) => s.gridSize), contains(3));
    });

    test('nothing on the ladder asks for less than 2^10', () {
      for (final stage in kStages) {
        expect(
          stage.targetTile,
          greaterThanOrEqualTo(1024),
          reason: '${stage.name} is below the floor',
        );
      }
    });

    test('a move budget leaves room to reach the target', () {
      // A spawn is worth ~1.1 twos, so a target of N needs about N/2.2 spawns
      // at absolute best. Anything under that is unwinnable by arithmetic.
      for (final stage in kStages.where((s) => s.hasMoveLimit)) {
        final floor = stage.targetTile! / 2.2;
        expect(
          stage.moveLimit,
          greaterThan(floor),
          reason: '${stage.name} cannot be cleared inside its budget',
        );
      }
    });

    test('walls never take more than a quarter of the board', () {
      for (final stage in kStages) {
        final walls = stage.blockedCells.length + stage.randomBlockedCells;
        expect(walls * 4, lessThanOrEqualTo(stage.gridSize * stage.gridSize));
      }
    });

    test('every target can physically be held on its own board', () {
      // Building N means owning the whole descending chain N, N/2, ... 2 at
      // once at the worst moment, one tile per cell. It is a floor, not a
      // difficulty rating — but a target whose chain cannot fit is simply
      // unreachable, however well the stage is played.
      for (final stage in kStages) {
        final chain = _chainLength(stage.targetTile!);
        final usable =
            stage.gridSize * stage.gridSize -
            stage.blockedCells.length -
            stage.randomBlockedCells;
        expect(
          chain,
          lessThanOrEqualTo(usable),
          reason:
              '${stage.name} asks for ${stage.targetTile} on '
              '${stage.gridSize}x${stage.gridSize}: needs $chain cells, '
              'has $usable',
        );
      }
    });

    test('the ladder opens on its smallest target and ends on its largest', () {
      final targets = [for (final s in kStages) s.targetTile!];
      expect(targets.first, targets.reduce((a, b) => a < b ? a : b));
      expect(targets.last, targets.reduce((a, b) => a > b ? a : b));
    });

    test('the climb spans 2^10 to 2^15', () {
      expect(kStages.first.targetTile, 1024);
      expect(kStages.last.targetTile, 32768);
      expect(kStages.last.targetTile! ~/ kStages.first.targetTile!, 32);
    });

    test('every target has a colour of its own in every skin', () {
      // Past the end of a ramp `styleFor` recycles its tail, which would paint
      // 16384 in the 2048 colour. The ramps have to reach the ladder's ceiling.
      final ceiling = kStages
          .map((s) => s.targetTile!)
          .reduce((a, b) => a > b ? a : b);
      final rungs = _chainLength(ceiling);
      for (final skin in kSkins) {
        expect(
          skin.ramp.length,
          greaterThanOrEqualTo(rungs),
          reason: '${skin.name} runs out of colours before $ceiling',
        );
      }
    });
  });

  group('endless boards', () {
    test('have no target and are never locked', () {
      for (final stage in kEndlessStages) {
        expect(stage.isEndless, isTrue);
        expect(stage.unlockedByDefault, isTrue);
      }
    });

    test('are excluded from the campaign chain', () {
      for (final stage in kEndlessStages) {
        expect(isCampaignStage(stage.id), isFalse);
        expect(nextStageAfter(stage.id), isNull);
        expect(stageNumber(stage.id), 0);
      }
    });

    test('are still resolvable by id, like any other board', () {
      for (final stage in kEndlessStages) {
        expect(stageById(stage.id), same(stage));
      }
    });

    test('label themselves by grid instead of by ladder position', () {
      expect(stageLabel(kEndlessStages.first), contains('ENDLESS'));
      expect(stageLabel(kStages.first), 'STAGE 1 / ${kStages.length}');
    });
  });
}

/// Tiles in the chain 2, 4, ... [target] — i.e. how many cells a board must be
/// able to hold at once for the target to be buildable at all.
int _chainLength(int target) {
  var count = 0;
  var value = target;
  while (value > 1) {
    count++;
    value ~/= 2;
  }
  return count;
}

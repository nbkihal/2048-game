import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/core/constants.dart';
import 'package:game_2048/data/stages_data.dart';
import 'package:game_2048/models/board.dart';
import 'package:game_2048/models/game_status.dart';
import 'package:game_2048/state/game_state.dart';

/// The tools are uncapped for now. The counts are still carried on the state,
/// so these pin the sentinel's behaviour rather than the current setting.
void main() {
  group('charges', () {
    test('an unlimited tool is always usable and never runs down', () {
      expect(hasCharges(kUnlimitedCharges), isTrue);
      expect(spendCharge(kUnlimitedCharges), kUnlimitedCharges);
    });

    test('a counted tool runs down and then locks out', () {
      var charges = 2;
      expect(hasCharges(charges), isTrue);

      charges = spendCharge(charges);
      expect(charges, 1);

      charges = spendCharge(charges);
      expect(charges, 0);
      expect(hasCharges(charges), isFalse);
    });

    test('the current build hands out unlimited tools', () {
      expect(toolsAreUnlimited, isTrue);
      expect(kUndoAllowance, kUnlimitedCharges);
      expect(kHammerAllowance, kUnlimitedCharges);
      expect(kShuffleAllowance, kUnlimitedCharges);
    });

    test('a fresh state starts on the configured allowance', () {
      final state = GameState(
        stage: kStages.first,
        board: Board.empty(4),
        score: 0,
        bestScore: 0,
        status: GameStatus.idle,
        movesUsed: 0,
        nextTileId: 1,
      );

      expect(state.undosLeft, kUndoAllowance);
      expect(state.canHammer, isTrue);
      expect(state.canShuffle, isTrue);
    });

    test('a spent tool reports itself unusable whatever the allowance', () {
      final state = GameState(
        stage: kStages.first,
        board: Board.empty(4),
        score: 0,
        bestScore: 0,
        status: GameStatus.playing,
        movesUsed: 3,
        nextTileId: 1,
        hammersLeft: 0,
        shufflesLeft: 0,
      );

      expect(state.canHammer, isFalse);
      expect(state.canShuffle, isFalse);
    });
  });
}

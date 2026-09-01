import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/data/daily.dart';
import 'package:game_2048/data/stages_data.dart';
import 'package:game_2048/logic/board_ops.dart';
import 'package:game_2048/models/board.dart';
import 'package:game_2048/models/game_status.dart';
import 'package:game_2048/models/medal.dart';
import 'package:game_2048/models/position.dart';
import 'package:game_2048/state/game_state.dart';

void main() {
  GameState sample() => GameState(
    stage: kStages[7], // Frozen Tile: has a wall to carry through the round trip
    board: armBomb(
      Board.fromValues([
        [2, 4, 0, 0],
        [8, 16, 0, 0],
        [0, 0, 32, 0],
        [0, 0, 0, 64],
      ], blocked: {const Position(3, 0)}),
      3,
      6,
    ),
    score: 1234,
    bestScore: 900,
    status: GameStatus.playing,
    movesUsed: 42,
    nextTileId: 19,
    undosLeft: 2,
    hammersLeft: 0,
    shufflesLeft: 1,
    usedUndo: true,
    moveSerial: 42,
  );

  group('the saved run', () {
    test('survives a round trip through JSON', () {
      final before = sample();

      final after = GameState.fromJson(
        jsonDecode(jsonEncode(before.toJson())) as Map<String, dynamic>,
        best: before.bestScore,
      )!;

      expect(after.stage.id, before.stage.id);
      expect(after.board.toValues(), before.board.toValues());
      expect(after.score, before.score);
      expect(after.movesUsed, before.movesUsed);
      expect(after.nextTileId, before.nextTileId);
      expect(after.undosLeft, 2);
      expect(after.hammersLeft, 0);
      expect(after.shufflesLeft, 1);
      expect(after.usedUndo, isTrue);
    });

    test('carries the walls, so the board is not quietly widened', () {
      final after = GameState.fromJson(
        jsonDecode(jsonEncode(sample().toJson())) as Map<String, dynamic>,
        best: 0,
      )!;

      expect(after.board.isBlocked(3, 0), isTrue);
      expect(after.board.blockedIndices.length, 1);
    });

    test('carries a ticking bomb and its fuse', () {
      final after = GameState.fromJson(
        jsonDecode(jsonEncode(sample().toJson())) as Map<String, dynamic>,
        best: 0,
      )!;

      expect(after.armedBomb, isNotNull);
      expect(after.armedBomb!.fuse, 6);
    });

    test('a stage that no longer exists loads as nothing rather than crashing',
        () {
      final json = sample().toJson()..['stage'] = 9999;
      expect(GameState.fromJson(json, best: 0), isNull);
    });

    test('a board whose size no longer matches its stage is rejected', () {
      final json = sample().toJson();
      json['board'] = Board.fromValues([
        [2, 0],
        [0, 4],
      ]).toJson();

      expect(GameState.fromJson(json, best: 0), isNull);
    });

    test('only an attempt in progress is worth resuming', () {
      expect(sample().isResumable, isTrue);
      expect(sample().copyWith(movesUsed: 0).isResumable, isFalse);
      expect(
        sample().copyWith(status: GameStatus.lost).isResumable,
        isFalse,
      );
      expect(sample().copyWith(status: GameStatus.won).isResumable, isFalse);
    });
  });

  group('medals', () {
    final stage = kStages.first; // target 64 -> par 47

    test('a clear inside par with no undo takes all three', () {
      expect(
        medalsForAttempt(
          cleared: true,
          movesUsed: 20,
          parMoves: stage.parMoves,
          usedUndo: false,
        ),
        {Medal.cleared, Medal.efficient, Medal.clean},
      );
    });

    test('a rewind costs the clean medal but not the clear', () {
      final earned = medalsForAttempt(
        cleared: true,
        movesUsed: 20,
        parMoves: stage.parMoves,
        usedUndo: true,
      );

      expect(earned, contains(Medal.cleared));
      expect(earned, isNot(contains(Medal.clean)));
    });

    test('going over par costs only the efficiency medal', () {
      final earned = medalsForAttempt(
        cleared: true,
        movesUsed: stage.parMoves! + 1,
        parMoves: stage.parMoves,
        usedUndo: false,
      );

      expect(earned, {Medal.cleared, Medal.clean});
    });

    test('a lost attempt earns nothing at all', () {
      expect(
        medalsForAttempt(
          cleared: false,
          movesUsed: 5,
          parMoves: stage.parMoves,
          usedUndo: false,
        ),
        isEmpty,
      );
    });

    test('a stage with no target has nothing to be efficient about', () {
      expect(kEndlessStages.first.parMoves, isNull);
      expect(
        medalsForAttempt(
          cleared: true,
          movesUsed: 1,
          parMoves: null,
          usedUndo: false,
        ),
        {Medal.cleared, Medal.clean},
      );
    });

    test('pack and unpack round-trip every combination', () {
      for (final set in [
        <Medal>{},
        {Medal.cleared},
        {Medal.cleared, Medal.clean},
        {Medal.cleared, Medal.efficient, Medal.clean},
      ]) {
        expect(unpackMedals(packMedals(set)), set);
      }
    });
  });

  group('the daily challenge', () {
    test('the seed is the calendar date', () {
      expect(dailySeed(DateTime(2026, 9, 1)), 20260901);
      expect(dailySeed(DateTime(2026, 12, 31)), 20261231);
    });

    test('two players on the same day get the same seed', () {
      expect(
        dailySeed(DateTime(2026, 5, 4, 8, 30)),
        dailySeed(DateTime(2026, 5, 4, 23, 59)),
      );
    });

    test('the next day is a different board', () {
      expect(
        dailySeed(DateTime(2026, 5, 4)) == dailySeed(DateTime(2026, 5, 5)),
        isFalse,
      );
    });

    test('it is playable without unlocking anything, and never clears', () {
      expect(kDailyStage.unlockedByDefault, isTrue);
      expect(kDailyStage.isEndless, isTrue);
      expect(isCampaignStage(kDailyStageId), isFalse);
      expect(stageLabel(kDailyStage), 'DAILY CHALLENGE');
    });
  });
}

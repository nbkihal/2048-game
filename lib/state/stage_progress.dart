import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/skin.dart';
import '../data/daily.dart';
import '../data/persistence.dart';
import '../data/skins_data.dart';
import '../data/stages_data.dart';
import '../models/medal.dart';
import '../models/stage.dart';

/// What the player has unlocked, their best scores and their medals.
class StageProgress {
  const StageProgress({
    required this.clearedStageIds,
    required this.bestScores,
    required this.highScore,
    required this.medals,
    required this.dailySeed,
    required this.dailyBest,
    this.newlyEarnedMedals = const {},
  });

  const StageProgress.empty()
    : clearedStageIds = const {},
      bestScores = const {},
      highScore = 0,
      medals = const {},
      dailySeed = 0,
      dailyBest = 0,
      newlyEarnedMedals = const {};

  final Set<int> clearedStageIds;

  /// Best score per stage id.
  final Map<int, int> bestScores;

  final int highScore;

  /// Medals per stage id, as a packed bitmask.
  final Map<int, int> medals;

  /// The day the recorded [dailyBest] belongs to.
  final int dailySeed;
  final int dailyBest;

  /// Medals the most recent attempt added, for the outcome panel to celebrate.
  /// Transient: it says nothing about the stage, only about the last run.
  final Set<Medal> newlyEarnedMedals;

  int get clearedCount => clearedStageIds.length;

  bool isCleared(int stageId) => clearedStageIds.contains(stageId);

  int bestScoreFor(int stageId) => bestScores[stageId] ?? 0;

  Set<Medal> medalsFor(int stageId) => unpackMedals(medals[stageId] ?? 0);

  int get medalCount =>
      kStages.fold(0, (total, stage) => total + medalsFor(stage.id).length);

  int get medalTotal => kStages.length * Medal.values.length;

  /// Today's best, or 0 once the date has rolled over.
  int bestForDay(int seed) => dailySeed == seed ? dailyBest : 0;

  /// A stage is playable when it says so itself or when the stage before it in
  /// the table has been cleared. Progression is therefore a property of the
  /// data, not of a hardcoded list of ids.
  bool isUnlocked(Stage stage) {
    if (stage.unlockedByDefault) return true;
    final index = kStages.indexWhere((s) => s.id == stage.id);
    if (index <= 0) return true;
    return clearedStageIds.contains(kStages[index - 1].id);
  }

  /// The furthest stage the player can play right now — where "Continue" goes
  /// when there is no run to resume.
  Stage get continueStage {
    for (final stage in kStages.reversed) {
      if (isUnlocked(stage)) return stage;
    }
    return kStages.first;
  }

  bool hasStarted() => clearedStageIds.isNotEmpty || highScore > 0;

  List<Skin> get unlockedSkins =>
      kSkins.where((s) => isSkinUnlocked(s, clearedCount)).toList();

  StageProgress copyWith({
    Set<int>? clearedStageIds,
    Map<int, int>? bestScores,
    int? highScore,
    Map<int, int>? medals,
    int? dailySeed,
    int? dailyBest,
    Set<Medal>? newlyEarnedMedals,
  }) => StageProgress(
    clearedStageIds: clearedStageIds ?? this.clearedStageIds,
    bestScores: bestScores ?? this.bestScores,
    highScore: highScore ?? this.highScore,
    medals: medals ?? this.medals,
    dailySeed: dailySeed ?? this.dailySeed,
    dailyBest: dailyBest ?? this.dailyBest,
    newlyEarnedMedals: newlyEarnedMedals ?? this.newlyEarnedMedals,
  );
}

class StageProgressNotifier extends StateNotifier<StageProgress> {
  StageProgressNotifier(this._store) : super(_read(_store));

  final Persistence _store;

  static StageProgress _read(Persistence store) {
    final seed = todaysSeed();
    return StageProgress(
      clearedStageIds: store.clearedStages,
      bestScores: {
        for (final stage in kAllStages)
          stage.id: store.bestScoreForStage(stage.id),
      },
      highScore: store.highScore,
      medals: {
        for (final stage in kStages) stage.id: store.medalsForStage(stage.id),
      },
      dailySeed: seed,
      dailyBest: store.dailyBestFor(seed),
    );
  }

  /// Records the result of an attempt.
  ///
  /// Everything the UI wants to celebrate (a new best, a freshly unlocked
  /// stage or skin) is derivable from the updated state; the one thing that is
  /// not is *which* medals are new, so that lands in the state as well.
  Future<void> recordAttempt({
    required Stage stage,
    required int score,
    required bool cleared,
    required int movesUsed,
    required bool usedUndo,
  }) async {
    if (stage.id == kDailyStageId) {
      await _recordDaily(score);
      return;
    }

    final wasCleared = state.isCleared(stage.id);
    final previousBest = state.bestScoreFor(stage.id);
    final isNewBest = score > previousBest;

    final clearedIds = {...state.clearedStageIds, if (cleared) stage.id};
    final bestScores = {...state.bestScores};
    if (isNewBest) bestScores[stage.id] = score;
    final highScore = score > state.highScore ? score : state.highScore;

    final had = state.medalsFor(stage.id);
    final earned = medalsForAttempt(
      cleared: cleared,
      movesUsed: movesUsed,
      parMoves: stage.parMoves,
      usedUndo: usedUndo,
    );
    final fresh = earned.difference(had);
    final all = had.union(earned);
    final medals = {...state.medals};
    if (fresh.isNotEmpty) medals[stage.id] = packMedals(all);

    state = state.copyWith(
      clearedStageIds: clearedIds,
      bestScores: bestScores,
      highScore: highScore,
      medals: medals,
      newlyEarnedMedals: fresh,
    );

    if (isNewBest) await _store.setBestScoreForStage(stage.id, score);
    if (highScore != _store.highScore) await _store.setHighScore(highScore);
    if (cleared && !wasCleared) await _store.setClearedStages(clearedIds);
    if (fresh.isNotEmpty) {
      await _store.setMedalsForStage(stage.id, packMedals(all));
    }
  }

  Future<void> _recordDaily(int score) async {
    final seed = todaysSeed();
    final best = state.bestForDay(seed);
    final highScore = score > state.highScore ? score : state.highScore;

    state = state.copyWith(
      dailySeed: seed,
      dailyBest: score > best ? score : best,
      highScore: highScore,
      newlyEarnedMedals: const {},
    );

    if (score > best) await _store.setDailyBest(seed, score);
    if (highScore != _store.highScore) await _store.setHighScore(highScore);
  }

  Future<void> resetAll() async {
    await _store.resetAll();
    state = const StageProgress.empty().copyWith(dailySeed: todaysSeed());
  }
}

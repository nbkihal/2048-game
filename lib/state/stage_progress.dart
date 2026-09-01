import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/persistence.dart';
import '../data/skins_data.dart';
import '../data/stages_data.dart';
import '../core/skin.dart';
import '../models/stage.dart';

/// What the player has unlocked and their best scores.
class StageProgress {
  const StageProgress({
    required this.clearedStageIds,
    required this.bestScores,
    required this.highScore,
  });

  const StageProgress.empty()
      : clearedStageIds = const {},
        bestScores = const {},
        highScore = 0;

  final Set<int> clearedStageIds;

  /// Best score per stage id.
  final Map<int, int> bestScores;

  final int highScore;

  int get clearedCount => clearedStageIds.length;

  bool isCleared(int stageId) => clearedStageIds.contains(stageId);

  int bestScoreFor(int stageId) => bestScores[stageId] ?? 0;

  /// A stage is playable when it says so itself or when the stage before it in
  /// the table has been cleared. Progression is therefore a property of the
  /// data, not of a hardcoded list of ids.
  bool isUnlocked(Stage stage) {
    if (stage.unlockedByDefault) return true;
    final index = kStages.indexWhere((s) => s.id == stage.id);
    if (index <= 0) return true;
    return clearedStageIds.contains(kStages[index - 1].id);
  }

  /// The furthest stage the player can play right now — where "Continue" goes.
  Stage get continueStage {
    for (final stage in kStages.reversed) {
      if (isUnlocked(stage)) return stage;
    }
    return kStages.first;
  }

  bool hasStarted() => clearedStageIds.isNotEmpty;

  List<Skin> get unlockedSkins =>
      kSkins.where((s) => isSkinUnlocked(s, clearedCount)).toList();

  StageProgress copyWith({
    Set<int>? clearedStageIds,
    Map<int, int>? bestScores,
    int? highScore,
  }) =>
      StageProgress(
        clearedStageIds: clearedStageIds ?? this.clearedStageIds,
        bestScores: bestScores ?? this.bestScores,
        highScore: highScore ?? this.highScore,
      );
}

class StageProgressNotifier extends StateNotifier<StageProgress> {
  StageProgressNotifier(this._store) : super(_read(_store));

  final Persistence _store;

  static StageProgress _read(Persistence store) {
    final cleared = store.clearedStages;
    return StageProgress(
      clearedStageIds: cleared,
      bestScores: {
        for (final stage in kStages) stage.id: store.bestScoreForStage(stage.id),
      },
      highScore: store.highScore,
    );
  }

  /// Records the result of an attempt. Everything the UI wants to celebrate
  /// (a new best, a freshly unlocked stage or skin) is derivable from the
  /// updated state, so nothing is returned.
  Future<void> recordAttempt({
    required Stage stage,
    required int score,
    required bool cleared,
  }) async {
    final wasCleared = state.isCleared(stage.id);
    final previousBest = state.bestScoreFor(stage.id);
    final isNewBest = score > previousBest;

    final clearedIds = {...state.clearedStageIds, if (cleared) stage.id};
    final bestScores = {...state.bestScores};
    if (isNewBest) bestScores[stage.id] = score;
    final highScore =
        score > state.highScore ? score : state.highScore;

    state = StageProgress(
      clearedStageIds: clearedIds,
      bestScores: bestScores,
      highScore: highScore,
    );

    if (isNewBest) await _store.setBestScoreForStage(stage.id, score);
    if (highScore != _store.highScore) await _store.setHighScore(highScore);
    if (cleared && !wasCleared) await _store.setClearedStages(clearedIds);
  }

  Future<void> resetAll() async {
    await _store.resetAll();
    state = const StageProgress.empty();
  }
}

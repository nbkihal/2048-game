import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_controller.dart';
import '../core/skin.dart';
import '../data/daily.dart';
import '../data/persistence.dart';
import '../data/skins_data.dart';
import '../data/stages_data.dart';
import '../models/game_status.dart';
import 'game_notifier.dart';
import 'game_state.dart';
import 'settings_state.dart';
import 'stage_progress.dart';

/// Injected at the root of the app once `SharedPreferences` has loaded.
/// Overridden in tests with an in-memory store.
final persistenceProvider = Provider<Persistence>(
  (ref) => throw UnimplementedError('persistenceProvider must be overridden'),
);

/// Seeded in tests so spawns are reproducible; `null` means each game builds a
/// fresh generator, which is what the real app wants.
final randomProvider = Provider<Random?>((ref) => null);

/// Overridden in widget tests with a silent controller.
final audioProvider = Provider<AudioController>((ref) {
  final controller = AudioController();
  ref.onDispose(controller.dispose);
  return controller;
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((
  ref,
) {
  return SettingsNotifier(
    ref.watch(persistenceProvider),
    ref.watch(audioProvider),
  );
});

final progressProvider =
    StateNotifierProvider<StageProgressNotifier, StageProgress>((ref) {
      return StageProgressNotifier(ref.watch(persistenceProvider));
    });

/// The skin currently in force. Falls back to the default if the selected skin
/// has been re-locked by a progress reset.
final skinProvider = Provider<Skin>((ref) {
  final selected = skinById(ref.watch(settingsProvider).skinId);
  final cleared = ref.watch(progressProvider).clearedCount;
  return isSkinUnlocked(selected, cleared) ? selected : skinById(kDefaultSkinId);
});

/// The run left open by a previous session, or `null` when there is none.
final savedRunProvider = StateNotifierProvider<SavedRunNotifier, GameState?>((
  ref,
) {
  return SavedRunNotifier(ref.watch(persistenceProvider));
});

/// Owns the snapshot on disk: reads it at startup, rewrites it after every
/// committed change and drops it the moment the attempt ends.
class SavedRunNotifier extends StateNotifier<GameState?> {
  SavedRunNotifier(this._store) : super(_read(_store));

  final Persistence _store;

  static GameState? _read(Persistence store) {
    final raw = store.savedRun;
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final stageId = json['stage'] as int?;
      final saved = GameState.fromJson(
        json,
        best: stageId == null ? 0 : store.bestScoreForStage(stageId),
      );
      return saved != null && saved.isResumable ? saved : null;
    } on FormatException {
      // A payload from an incompatible build is not worth crashing over.
      return null;
    }
  }

  /// Records or clears the snapshot, depending on whether [game] is still a run
  /// worth coming back to.
  void write(GameState game) {
    if (!game.isResumable) {
      clear();
      return;
    }
    state = game;
    _store.setSavedRun(jsonEncode(game.toJson()));
  }

  void clear() {
    if (state == null && _store.savedRun == null) return;
    state = null;
    _store.clearSavedRun();
  }
}

/// One game per stage, discarded when the screen goes away.
final gameProvider = StateNotifierProvider.autoDispose
    .family<GameNotifier, GameState, int>((ref, stageId) {
      final stage = stageById(stageId);
      final audio = ref.watch(audioProvider);
      final progress = ref.read(progressProvider.notifier);
      final saved = ref.read(savedRunProvider);
      final runs = ref.read(savedRunProvider.notifier);

      // The daily board is the same for everybody: the date seeds the whole
      // random stream, so the opening tiles and the spawns are reproducible.
      final random = stage.id == kDailyStageId
          ? Random(todaysSeed())
          : ref.watch(randomProvider);

      final best = stage.id == kDailyStageId
          ? ref.read(progressProvider).bestForDay(todaysSeed())
          : ref.read(progressProvider).bestScoreFor(stageId);

      return GameNotifier(
        stage: stage,
        bestScore: best,
        audio: audio,
        random: random,
        // Only resume into the screen the saved run actually belongs to.
        resumeFrom: saved != null && saved.stage.id == stageId
            ? saved.copyWith(bestScore: best)
            : null,
        onSnapshot: runs.write,
        onOutcome: (state) {
          progress.recordAttempt(
            stage: state.stage,
            score: state.score,
            cleared: state.status == GameStatus.won,
            movesUsed: state.movesUsed,
            usedUndo: state.usedUndo,
          );
        },
      );
    });

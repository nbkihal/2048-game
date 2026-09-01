import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/audio_controller.dart';
import '../data/persistence.dart';
import '../data/skins_data.dart';
import '../data/stages_data.dart';
import '../core/skin.dart';
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

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier(ref.watch(persistenceProvider), ref.watch(audioProvider));
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

/// One game per stage, discarded when the screen goes away.
final gameProvider = StateNotifierProvider.autoDispose
    .family<GameNotifier, GameState, int>((ref, stageId) {
  final stage = stageById(stageId);
  final audio = ref.watch(audioProvider);
  final progress = ref.read(progressProvider.notifier);

  return GameNotifier(
    stage: stage,
    bestScore: ref.read(progressProvider).bestScoreFor(stageId),
    audio: audio,
    random: ref.watch(randomProvider),
    onOutcome: (state) {
      progress.recordAttempt(
        stage: state.stage,
        score: state.score,
        cleared: state.status == GameStatus.won,
      );
    },
  );
});

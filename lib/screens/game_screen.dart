import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/audio_controller.dart';
import '../core/page_route.dart';
import '../core/skin.dart';
import '../data/skins_data.dart';
import '../data/stages_data.dart';
import '../logic/game_rules.dart';
import '../models/direction.dart';
import '../models/game_status.dart';
import '../models/game_tool.dart';
import '../state/game_state.dart';
import '../state/providers.dart';
import '../widgets/board_view.dart';
import '../widgets/outcome_dialog.dart';
import '../widgets/pause_menu.dart';
import '../widgets/score_board.dart';
import '../widgets/score_popup.dart';
import '../widgets/swipe_detector.dart';
import '../widgets/target_banner.dart';
import '../widgets/tool_bar.dart';
import '../widgets/ui_kit.dart';
import 'endless_screen.dart';
import 'settings_screen.dart';
import 'stage_select_screen.dart';

/// The board, its HUD, and the two overlays that can sit on top of it.
class GameScreen extends ConsumerWidget {
  const GameScreen({super.key, required this.stageId});

  final int stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinProvider);
    final game = ref.watch(gameProvider(stageId));
    final notifier = ref.read(gameProvider(stageId).notifier);
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(progressProvider);
    final audio = ref.watch(audioProvider);

    void leave() {
      audio.play(Sfx.tap);
      Navigator.of(context).pop();
    }

    return PopScope(
      // Back should open the pause menu mid-game rather than dumping the run.
      canPop: !game.acceptsInput || game.isPaused,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) notifier.pause();
      },
      child: Scaffold(
        backgroundColor: skin.stage,
        body: SafeArea(
          child: Stack(
            children: [
              _GameBody(
                stageId: stageId,
                skin: skin,
                game: game,
                onSwipe: notifier.swipe,
                onUndo: notifier.canUndo ? notifier.undo : null,
                onPause: notifier.pause,
                onBack: leave,
                onHammer: notifier.armHammer,
                onShuffle: notifier.useShuffle,
                onHammerTarget: notifier.useHammer,
                onDisarm: notifier.disarmTool,
              ),
              if (game.isPaused)
                Positioned.fill(
                  child: PauseMenu(
                    skin: skin,
                    stageName: game.stage.name,
                    stageLabel: stageLabel(game.stage),
                    score: game.score,
                    soundOn: settings.soundOn,
                    hapticsOn: settings.hapticsOn,
                    onToggleSound: ref
                        .read(settingsProvider.notifier)
                        .toggleSound,
                    onToggleHaptics: ref
                        .read(settingsProvider.notifier)
                        .toggleHaptics,
                    onResume: notifier.resume,
                    onRestart: () {
                      notifier.restart();
                      notifier.resume();
                    },
                    onSettings: () => Navigator.of(context)
                        .push(FadeThroughRoute(child: const SettingsScreen())),
                    onQuit: leave,
                  ),
                ),
              if (game.hasPendingOutcome)
                Positioned.fill(
                  child: _Outcome(
                    stageId: stageId,
                    skin: skin,
                    game: game,
                    stagesCleared: progress.clearedCount,
                    best: progress.bestScoreFor(stageId),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameBody extends StatelessWidget {
  const _GameBody({
    required this.stageId,
    required this.skin,
    required this.game,
    required this.onSwipe,
    required this.onUndo,
    required this.onPause,
    required this.onBack,
    required this.onHammer,
    required this.onShuffle,
    required this.onHammerTarget,
    required this.onDisarm,
  });

  final int stageId;
  final Skin skin;
  final GameState game;
  final ValueChanged<Direction> onSwipe;
  final VoidCallback? onUndo;
  final VoidCallback onPause;
  final VoidCallback onBack;
  final VoidCallback onHammer;
  final VoidCallback onShuffle;
  final ValueChanged<int> onHammerTarget;
  final VoidCallback onDisarm;

  @override
  Widget build(BuildContext context) {
    final stage = game.stage;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s16,
        AppSpacing.s20,
        AppSpacing.s20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconPill(
                icon: Icons.arrow_back_rounded,
                color: skin.onStage,
                tooltip: 'Back',
                onPressed: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.name.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body.copyWith(color: skin.onStage),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      stage.subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.monoLabel.copyWith(
                        color: skin.onStage.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconPill(
                icon: Icons.pause_rounded,
                color: skin.accent,
                tooltip: 'Pause',
                onPressed: onPause,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.elementGap),
          ScoreBoard(
            score: game.score,
            best: game.displayBestScore,
            skin: skin,
            movesUsed: game.movesUsed,
            moveLimit: stage.moveLimit,
          ),
          const SizedBox(height: 10),
          TargetBanner(
            skin: skin,
            targetTile: stage.targetTile,
            highestTile: game.board.highestValue,
            progress: targetProgress(game.board, stage.targetTile),
            stageLabel: stageLabel(stage),
          ),
          const SizedBox(height: 10),
          // The popup sits in its own fixed-height strip rather than over the
          // board, so a merge never covers the tiles it came from.
          SizedBox(
            height: 26,
            child: Center(
              child: ScorePopup(
                skin: skin,
                gain: game.lastGain,
                mergeCount: game.lastMergeCount,
                serial: game.moveSerial,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SwipeDetector(
                enabled: game.acceptsInput,
                onSwipe: onSwipe,
                child: BoardView(
                  board: game.board,
                  skin: skin,
                  mergedAwayTiles: game.mergedAwayTiles,
                  dimmed: game.isPaused,
                  picking: game.armedTool == GameTool.hammer,
                  onTileTap: (tile) => onHammerTarget(tile.id),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.elementGap),
          if (game.armedTool == GameTool.hammer)
            PickPrompt(skin: skin, onCancel: onDisarm)
          else
            ToolBar(
              skin: skin,
              undosLeft: game.undosLeft,
              hammersLeft: game.hammersLeft,
              shufflesLeft: game.shufflesLeft,
              hammerArmed: false,
              onUndo: game.acceptsInput ? onUndo : null,
              onHammer: game.acceptsTools && game.canHammer
                  ? onHammer
                  : null,
              onShuffle: game.acceptsTools && game.canShuffle
                  ? onShuffle
                  : null,
              onPause: onPause,
            ),
        ],
      ),
    );
  }
}

class _Outcome extends ConsumerWidget {
  const _Outcome({
    required this.stageId,
    required this.skin,
    required this.game,
    required this.stagesCleared,
    required this.best,
  });

  final int stageId;
  final Skin skin;
  final GameState game;
  final int stagesCleared;
  final int best;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(gameProvider(stageId).notifier);
    final progress = ref.watch(progressProvider);
    final won = game.status == GameStatus.won;
    final next = nextStageAfter(stageId);

    // The attempt was recorded before this panel was built, so the stage's
    // medals already include anything this run just earned.
    final medals = progress.medalsFor(stageId);
    final freshMedals = progress.newlyEarnedMedals;

    // The attempt has already been recorded, so anything gated on exactly this
    // many cleared stages is what this clear just opened up.
    final freshSkins = won
        ? kSkins
              .where((s) => s.unlockAfterStagesCleared == stagesCleared)
              .map((s) => s.name)
              .toList()
        : const <String>[];

    void act(OutcomeAction action) {
      notifier.acknowledgeOutcome();
      final navigator = Navigator.of(context);
      switch (action) {
        case OutcomeAction.keepGoing:
          notifier.keepGoing();
        case OutcomeAction.retry:
          notifier.restart();
        case OutcomeAction.nextStage:
          navigator.pushReplacement(
            FadeThroughRoute(child: GameScreen(stageId: next!.id)),
          );
        case OutcomeAction.stageSelect:
          // An endless run belongs to its own picker; sending the player to
          // the campaign ladder would be a different game.
          navigator.pushReplacement(
            FadeThroughRoute(
              child: isCampaignStage(stageId)
                  ? const StageSelectScreen()
                  : const EndlessScreen(),
            ),
          );
      }
    }

    return OutcomeDialog(
      skin: skin,
      won: won,
      stage: game.stage,
      score: game.score,
      best: best,
      isNewBest: game.score > game.bestScore,
      nextStage: won ? next : null,
      unlockedSkinNames: freshSkins,
      // The endless stage has no target to pass, so there is nothing to keep
      // going towards.
      canKeepGoing: !game.stage.isEndless && !game.keptGoing,
      lostToMoveLimit: !won && !hasMovesLeft(game.stage, game.movesUsed),
      stageSelectLabel: isCampaignStage(stageId)
          ? 'Stage select'
          : 'Endless boards',
      medals: medals,
      freshMedals: freshMedals,
      onAction: act,
    );
  }
}

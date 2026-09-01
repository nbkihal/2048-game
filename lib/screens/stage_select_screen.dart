import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/audio_controller.dart';
import '../core/page_route.dart';
import '../core/skin.dart';
import '../data/stages_data.dart';
import '../models/medal.dart';
import '../models/stage.dart';
import '../state/providers.dart';
import '../state/stage_progress.dart';
import '../widgets/medal_row.dart';
import '../widgets/ui_kit.dart';
import 'game_screen.dart';

/// The stage list, driven entirely by `kStages` and `StageProgress`.
class StageSelectScreen extends ConsumerWidget {
  const StageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinProvider);
    final progress = ref.watch(progressProvider);
    final audio = ref.watch(audioProvider);
    final furthest = progress.continueStage;

    return Scaffold(
      backgroundColor: skin.stage,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s16,
                AppSpacing.s20,
                AppSpacing.s16,
              ),
              child: Row(
                children: [
                  IconPill(
                    icon: Icons.arrow_back_rounded,
                    color: skin.onStage,
                    onPressed: () {
                      audio.play(Sfx.tap);
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'STAGES',
                    style: AppType.subheading.copyWith(color: skin.accent),
                  ),
                  const Spacer(),
                  MonoTag(
                    label: '${progress.clearedCount} / ${kStages.length}',
                    color: skin.onStage,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  0,
                  AppSpacing.s20,
                  AppSpacing.s40,
                ),
                itemCount: kStages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final stage = kStages[index];
                  return _StageCard(
                    stage: stage,
                    skin: skin,
                    unlocked: progress.isUnlocked(stage),
                    cleared: progress.isCleared(stage.id),
                    isNext:
                        stage.id == furthest.id &&
                        !progress.isCleared(stage.id),
                    bestScore: progress.bestScoreFor(stage.id),
                    medals: progress.medalsFor(stage.id),
                    requirement: _requirement(stage, progress),
                    onTap: () {
                      audio.play(Sfx.tap);
                      Navigator.of(context).push(
                        FadeThroughRoute(child: GameScreen(stageId: stage.id)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// What the player has to do to open a locked stage.
  String _requirement(Stage stage, StageProgress progress) {
    final index = kStages.indexWhere((s) => s.id == stage.id);
    if (index <= 0) return '';
    return 'CLEAR ${kStages[index - 1].name.toUpperCase()} FIRST';
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.skin,
    required this.unlocked,
    required this.cleared,
    required this.isNext,
    required this.bestScore,
    required this.medals,
    required this.requirement,
    required this.onTap,
  });

  final Stage stage;
  final Skin skin;
  final bool unlocked;
  final bool cleared;
  final bool isNext;
  final int bestScore;
  final Set<Medal> medals;
  final String requirement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The card the player should tap next is the loud one; everything else
    // stays on the nested surface so a scroll does not turn into confetti.
    final fill = isNext ? skin.accent : skin.boardSurface;
    final ink = isNext ? skin.onAccent : skin.onStage;
    final dim = ink.withValues(alpha: 0.7);

    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: RisoCard(
        color: fill,
        border: cleared ? skin.accent : null,
        onTap: unlocked ? onTap : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StageNumber(
              number: stageNumber(stage.id),
              skin: skin,
              ink: ink,
              locked: !unlocked,
              cleared: cleared,
            ),
            const SizedBox(width: AppSpacing.elementGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.name.toUpperCase(),
                    style: AppType.bodyLarge.copyWith(color: ink),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    unlocked ? stage.subtitle : requirement,
                    style: AppType.monoLabel.copyWith(color: dim),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      MonoTag(
                        label: '${stage.gridSize}×${stage.gridSize}',
                        color: ink,
                      ),
                      MonoTag(
                        label: stage.isEndless
                            ? 'NO TARGET'
                            : 'TARGET ${stage.targetTile}',
                        color: ink,
                      ),
                      if (stage.hasMoveLimit)
                        MonoTag(label: '${stage.moveLimit} MOVES', color: ink),
                      if (stage.hasBlockedCells)
                        MonoTag(label: _wallsLabel(stage), color: ink),
                      if (stage.hasBomb)
                        MonoTag(
                          label: 'BOMB — FUSE ${stage.bombFuse}',
                          color: ink,
                        ),
                      if (stage.rotates)
                        MonoTag(
                          label: 'TURNS EVERY ${stage.rotateEveryMoves}',
                          color: ink,
                        ),
                      if (bestScore > 0)
                        MonoTag(
                          label: 'BEST $bestScore',
                          color: isNext ? skin.onAccent : skin.accent,
                        ),
                    ],
                  ),
                  if (unlocked) ...[
                    const SizedBox(height: 12),
                    MedalRow(earned: medals, color: ink),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageNumber extends StatelessWidget {
  const _StageNumber({
    required this.number,
    required this.skin,
    required this.ink,
    required this.locked,
    required this.cleared,
  });

  final int number;
  final Skin skin;
  final Color ink;
  final bool locked;
  final bool cleared;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cleared ? skin.accent : skin.cell,
        borderRadius: AppRadius.cardRadius,
      ),
      child: locked
          ? Icon(
              Icons.lock_rounded,
              size: 20,
              color: ink.withValues(alpha: 0.8),
            )
          : cleared
          ? Icon(Icons.check_rounded, size: 24, color: skin.onAccent)
          : Text('$number', style: AppType.bodyLarge.copyWith(color: ink)),
    );
  }
}

/// "FROZEN CELL" or "2 FROZEN CELLS" — the count matters, because a second
/// wall changes the stage far more than the first one does.
String _wallsLabel(Stage stage) {
  final walls = stage.blockedCells.length + stage.randomBlockedCells;
  return walls == 1 ? 'FROZEN CELL' : '$walls FROZEN CELLS';
}

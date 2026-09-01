import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/audio_controller.dart';
import '../core/page_route.dart';
import '../core/skin.dart';
import '../data/stages_data.dart';
import '../models/stage.dart';
import '../state/providers.dart';
import '../widgets/ui_kit.dart';
import 'game_screen.dart';

/// The board picker for endless play.
///
/// Nothing here is locked and nothing is cleared — the only thing an endless
/// run leaves behind is a best score per board size.
class EndlessScreen extends ConsumerWidget {
  const EndlessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinProvider);
    final progress = ref.watch(progressProvider);
    final audio = ref.watch(audioProvider);

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
                    'ENDLESS',
                    style: AppType.subheading.copyWith(color: skin.accent),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                0,
                AppSpacing.s20,
                AppSpacing.s16,
              ),
              child: Text(
                'NO TARGET AND NO LOCK — PICK A BOARD AND PLAY UNTIL IT JAMS. '
                'EACH SIZE KEEPS ITS OWN BEST SCORE.',
                style: AppType.monoLabel.copyWith(
                  color: skin.onStage.withValues(alpha: 0.75),
                  height: 1.5,
                ),
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
                itemCount: kEndlessStages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final stage = kEndlessStages[index];
                  return _BoardCard(
                    stage: stage,
                    skin: skin,
                    best: progress.bestScoreFor(stage.id),
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
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.stage,
    required this.skin,
    required this.best,
    required this.onTap,
  });

  final Stage stage;
  final Skin skin;
  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RisoCard(
      color: skin.boardSurface,
      onTap: onTap,
      child: Row(
        children: [
          _GridMark(size: stage.gridSize, skin: skin),
          const SizedBox(width: AppSpacing.elementGap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.name.toUpperCase(),
                  style: AppType.bodyLarge.copyWith(color: skin.onStage),
                ),
                const SizedBox(height: 7),
                Text(
                  stage.subtitle,
                  style: AppType.monoLabel.copyWith(
                    color: skin.onStage.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                MonoTag(
                  label: best > 0 ? 'BEST $best' : 'NO RUN YET',
                  color: best > 0 ? skin.accent : skin.onStage,
                ),
              ],
            ),
          ),
          Icon(Icons.play_arrow_rounded, color: skin.accent),
        ],
      ),
    );
  }
}

/// A miniature of the board being offered — the size *is* the choice, so it is
/// drawn rather than spelled out.
class _GridMark extends StatelessWidget {
  const _GridMark({required this.size, required this.skin});

  final int size;
  final Skin skin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: skin.cell,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        children: [
          for (var row = 0; row < size; row++)
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < size; col++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(0.8),
                        decoration: BoxDecoration(
                          color: skin.onStage.withValues(alpha: 0.55),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(1.5),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/skin.dart';
import 'ui_kit.dart';

/// "Reach 512" plus a progress bar that advances one notch per doubling.
class TargetBanner extends StatelessWidget {
  const TargetBanner({
    super.key,
    required this.skin,
    required this.targetTile,
    required this.highestTile,
    required this.progress,
    required this.stageLabel,
  });

  final Skin skin;

  /// `null` on the endless stage.
  final int? targetTile;

  final int highestTile;
  final double progress;

  /// e.g. "STAGE 7 / 10".
  final String stageLabel;

  @override
  Widget build(BuildContext context) {
    final target = targetTile;

    return RisoCard(
      color: skin.boardSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MonoTag(label: stageLabel, color: skin.onStage),
              Text(
                target == null ? 'ENDLESS' : 'REACH $target',
                style: AppType.body.copyWith(color: skin.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (target == null)
            Text(
              'HIGHEST TILE $highestTile',
              style: AppType.monoLabel.copyWith(
                color: skin.onStage.withValues(alpha: 0.75),
              ),
            )
          else
            _ProgressBar(skin: skin, progress: progress),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.skin, required this.progress});

  final Skin skin;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: skin.cell,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
            AnimatedContainer(
              duration: kDialogDuration,
              curve: Curves.easeOut,
              height: 10,
              width: constraints.maxWidth * progress.clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: skin.accent,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/skin.dart';
import 'ui_kit.dart';

/// A labelled readout — score, best, moves. Flat block, mono label, display
/// number.
class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.label,
    required this.value,
    required this.skin,
    this.background,
    this.foreground,
    this.highlight = false,
  });

  final String label;
  final String value;
  final Skin skin;
  final Color? background;
  final Color? foreground;

  /// Draws attention to a value that just changed (a new best, the last move).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final fill = background ?? skin.boardSurface;
    final ink = foreground ?? skin.onStage;

    return RisoCard(
      color: highlight ? skin.accent : fill,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppType.monoLabel.copyWith(
              color: (highlight ? skin.onAccent : ink).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 7),
          AnimatedSwitcher(
            duration: kMergePopDuration,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            // Targets run to 8192, so a score can reach six digits in a block
            // a third of the screen wide. Shrinking beats clipping.
            child: FittedBox(
              key: ValueKey(value),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: AppType.bodyLarge.copyWith(
                  color: highlight ? skin.onAccent : ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The score row on the game screen.
class ScoreBoard extends StatelessWidget {
  const ScoreBoard({
    super.key,
    required this.score,
    required this.best,
    required this.skin,
    required this.movesUsed,
    this.moveLimit,
  });

  final int score;
  final int best;
  final Skin skin;
  final int movesUsed;
  final int? moveLimit;

  @override
  Widget build(BuildContext context) {
    final limit = moveLimit;
    return Row(
      children: [
        Expanded(
          child: StatBlock(label: 'Score', value: '$score', skin: skin),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatBlock(
            label: 'Best',
            value: '$best',
            skin: skin,
            highlight: score > 0 && score >= best,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatBlock(
            label: limit == null ? 'Moves' : 'Moves left',
            value: limit == null
                ? '$movesUsed'
                : '${(limit - movesUsed).clamp(0, limit)}',
            skin: skin,
            // A move budget running out is the thing to watch, so it turns
            // accent-coloured once it is nearly spent.
            highlight: limit != null && limit - movesUsed <= limit * 0.15,
          ),
        ),
      ],
    );
  }
}

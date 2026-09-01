import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/medal.dart';

/// The three medals a stage can hold, drawn as pips.
///
/// A filled pip is earned, a hollow one is still open — the row is the same
/// width either way, so a stage list reads as a column of progress rather than
/// a ragged edge.
class MedalRow extends StatelessWidget {
  const MedalRow({
    super.key,
    required this.earned,
    required this.color,
    this.size = 16,
    this.showLabels = false,
  });

  final Set<Medal> earned;

  /// Ink for both the filled pips and the hollow outlines.
  final Color color;

  final double size;

  /// Spells each medal out, for the outcome panel where there is room.
  final bool showLabels;

  static const _icons = {
    Medal.cleared: Icons.check_rounded,
    Medal.efficient: Icons.bolt_rounded,
    Medal.clean: Icons.workspace_premium_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final medal in Medal.values)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: showLabels
                ? _Labelled(
                    medal: medal,
                    has: earned.contains(medal),
                    color: color,
                  )
                : _Pip(
                    medal: medal,
                    has: earned.contains(medal),
                    color: color,
                    size: size,
                  ),
          ),
      ],
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({
    required this.medal,
    required this.has,
    required this.color,
    required this.size,
  });

  final Medal medal;
  final bool has;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: medal.label,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: has ? color : null,
          shape: BoxShape.circle,
          border: Border.all(
            color: has ? color : color.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _Labelled extends StatelessWidget {
  const _Labelled({
    required this.medal,
    required this.has,
    required this.color,
  });

  final Medal medal;
  final bool has;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ink = has ? color : color.withValues(alpha: 0.4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: ink, width: 1),
        borderRadius: AppRadius.pillRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(MedalRow._icons[medal], size: 13, color: ink),
          const SizedBox(width: 6),
          Text(
            medal.label,
            style: AppType.monoLabel.copyWith(color: ink, height: 1.0),
          ),
        ],
      ),
    );
  }
}

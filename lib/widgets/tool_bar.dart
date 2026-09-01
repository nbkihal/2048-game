import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/skin.dart';
import 'ui_kit.dart';

/// The row of spendable actions under the board.
///
/// Every one of them is finite, so each button carries its remaining count —
/// the number *is* the affordance, and a button at zero reads as spent rather
/// than as broken.
class ToolBar extends StatelessWidget {
  const ToolBar({
    super.key,
    required this.skin,
    required this.undosLeft,
    required this.hammersLeft,
    required this.shufflesLeft,
    required this.hammerArmed,
    required this.onUndo,
    required this.onHammer,
    required this.onShuffle,
    required this.onPause,
  });

  final Skin skin;
  final int undosLeft;
  final int hammersLeft;
  final int shufflesLeft;
  final bool hammerArmed;
  final VoidCallback? onUndo;
  final VoidCallback? onHammer;
  final VoidCallback? onShuffle;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Tool(
            skin: skin,
            icon: Icons.undo_rounded,
            label: 'Undo',
            count: undosLeft,
            onPressed: onUndo,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Tool(
            skin: skin,
            icon: Icons.gavel_rounded,
            label: hammerArmed ? 'Cancel' : 'Hammer',
            count: hammersLeft,
            active: hammerArmed,
            onPressed: onHammer,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Tool(
            skin: skin,
            icon: Icons.shuffle_rounded,
            label: 'Shuffle',
            count: shufflesLeft,
            onPressed: onShuffle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _Tool(
            skin: skin,
            icon: Icons.pause_rounded,
            label: 'Pause',
            onPressed: onPause,
          ),
        ),
      ],
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({
    required this.skin,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.count,
    this.active = false,
  });

  final Skin skin;
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Charges left, or `null` for an action that never runs out.
  final int? count;

  /// The tool is armed and waiting for a target.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final unlimited = count == kUnlimitedCharges;
    final spent = count == 0;
    final tint = active
        ? skin.onAccent
        : spent
        ? skin.onStage.withValues(alpha: 0.4)
        : skin.onStage;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: count == null
          ? label
          : unlimited
          ? '$label, unlimited'
          : '$label, $count left',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: active ? skin.accent : null,
            border: Border.all(color: tint, width: 2),
            borderRadius: AppRadius.pillRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: tint),
              const SizedBox(height: 6),
              Text(
                count == null
                    ? label.toUpperCase()
                    : unlimited
                    ? '∞'
                    : '$count',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.monoLabel.copyWith(color: tint, height: 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The banner that replaces the tool bar's instructions while the hammer waits
/// for a target.
class PickPrompt extends StatelessWidget {
  const PickPrompt({super.key, required this.skin, required this.onCancel});

  final Skin skin;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return RisoCard(
      color: skin.accent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.gavel_rounded, size: 18, color: skin.onAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'TAP A TILE TO SMASH IT',
              style: AppType.monoLabel.copyWith(color: skin.onAccent),
            ),
          ),
          UnderlineTextLink(
            label: 'Cancel',
            color: skin.onAccent,
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/skin.dart';
import 'ui_kit.dart';

/// The in-game pause panel.
///
/// It is an overlay rather than a route so the board stays visible (dimmed)
/// behind it — the player can see the position they are coming back to.
class PauseMenu extends StatefulWidget {
  const PauseMenu({
    super.key,
    required this.skin,
    required this.stageName,
    required this.stageLabel,
    required this.score,
    required this.onResume,
    required this.onRestart,
    required this.onSettings,
    required this.onQuit,
    required this.soundOn,
    required this.hapticsOn,
    required this.onToggleSound,
    required this.onToggleHaptics,
  });

  final Skin skin;
  final String stageName;
  final String stageLabel;
  final int score;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onSettings;
  final VoidCallback onQuit;
  final bool soundOn;
  final bool hapticsOn;
  final VoidCallback onToggleSound;
  final VoidCallback onToggleHaptics;

  @override
  State<PauseMenu> createState() => _PauseMenuState();
}

class _PauseMenuState extends State<PauseMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kDialogDuration,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    return FadeTransition(
      opacity: fade,
      child: Container(
        color: skin.scrim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s20),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: RisoCard(
                    color: skin.boardSurface,
                    padding: const EdgeInsets.all(AppSpacing.s20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            MonoTag(
                              label: widget.stageLabel,
                              color: skin.onStage,
                            ),
                            MonoTag(
                              label: '${widget.score} PTS',
                              color: skin.accent,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        Text(
                          'PAUSED',
                          style: AppType.subheading.copyWith(
                            color: skin.accent,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.stageName.toUpperCase(),
                          style: AppType.monoLabel.copyWith(
                            color: skin.onStage.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        PillButton(
                          label: 'Resume',
                          icon: Icons.play_arrow_rounded,
                          skin: skin,
                          expand: true,
                          onPressed: widget.onResume,
                        ),
                        const SizedBox(height: 10),
                        OutlinedActionButton(
                          label: 'Restart stage',
                          icon: Icons.refresh_rounded,
                          skin: skin,
                          expand: true,
                          onPressed: widget.onRestart,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _ToggleChip(
                                skin: skin,
                                label: 'Sound',
                                on: widget.soundOn,
                                icon: widget.soundOn
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                onTap: widget.onToggleSound,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _ToggleChip(
                                skin: skin,
                                label: 'Haptics',
                                on: widget.hapticsOn,
                                icon: widget.hapticsOn
                                    ? Icons.vibration_rounded
                                    : Icons.phonelink_erase_rounded,
                                onTap: widget.onToggleHaptics,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        OutlinedActionButton(
                          label: 'Settings',
                          icon: Icons.tune_rounded,
                          skin: skin,
                          expand: true,
                          color: skin.onStage,
                          onPressed: widget.onSettings,
                        ),
                        const SizedBox(height: AppSpacing.s16),
                        Center(
                          child: UnderlineTextLink(
                            label: 'Quit to stage select',
                            color: skin.onStage,
                            onPressed: widget.onQuit,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A settings toggle that reads as a stamped label, on or off.
class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.skin,
    required this.label,
    required this.on,
    required this.icon,
    required this.onTap,
  });

  final Skin skin;
  final String label;
  final bool on;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = on ? skin.onAccent : skin.onStage;
    return RisoCard(
      color: on ? skin.accent : skin.cell,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: tint),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: AppType.monoLabel.copyWith(color: tint),
            ),
          ),
        ],
      ),
    );
  }
}

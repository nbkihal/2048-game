import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/audio_controller.dart';
import '../core/page_route.dart';
import '../core/skin.dart';
import '../data/stages_data.dart';
import '../state/providers.dart';
import '../widgets/ui_kit.dart';
import 'how_to_play_screen.dart';
import 'skins_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinProvider);
    final settings = ref.watch(settingsProvider);
    final progress = ref.watch(progressProvider);
    final audio = ref.watch(audioProvider);

    return Scaffold(
      backgroundColor: skin.stage,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s16,
            AppSpacing.s20,
            AppSpacing.s40,
          ),
          children: [
            Row(
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
                  'SETTINGS',
                  style: AppType.subheading.copyWith(color: skin.accent),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            _SettingRow(
              skin: skin,
              label: 'Sound effects',
              detail: 'SLIDE, MERGE, WIN AND LOSE CUES',
              value: settings.soundOn,
              onChanged: ref.read(settingsProvider.notifier).toggleSound,
            ),
            const SizedBox(height: 10),
            _SettingRow(
              skin: skin,
              label: 'Haptics',
              detail: 'A TICK ON EVERY MOVE',
              value: settings.hapticsOn,
              onChanged: ref.read(settingsProvider.notifier).toggleHaptics,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text(
              'RULES',
              style: AppType.monoLabel.copyWith(
                color: skin.onStage.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            _LinkCard(
              skin: skin,
              label: 'How to play',
              detail: 'SWIPES, MERGES, TARGETS AND UNLOCKS',
              onTap: () {
                audio.play(Sfx.tap);
                Navigator.of(context)
                    .push(FadeThroughRoute(child: const HowToPlayScreen()));
              },
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text(
              'APPEARANCE',
              style: AppType.monoLabel.copyWith(
                color: skin.onStage.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            _LinkCard(
              skin: skin,
              label: 'Skin — ${skin.name}',
              detail: skin.tagline,
              onTap: () {
                audio.play(Sfx.tap);
                Navigator.of(context)
                    .push(FadeThroughRoute(child: const SkinsScreen()));
              },
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text(
              'PROGRESS',
              style: AppType.monoLabel.copyWith(
                color: skin.onStage.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            RisoCard(
              color: skin.boardSurface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProgressLine(
                    skin: skin,
                    label: 'Stages cleared',
                    value: '${progress.clearedCount} / ${kStages.length}',
                  ),
                  const SizedBox(height: 10),
                  _ProgressLine(
                    skin: skin,
                    label: 'All-time high score',
                    value: '${progress.highScore}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.elementGap),
            OutlinedActionButton(
              label: 'Reset all progress',
              icon: Icons.delete_outline_rounded,
              skin: skin,
              expand: true,
              color: AppColors.firecrackerRed,
              onPressed: () => _confirmReset(context, ref, skin),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Center(
              child: Text(
                'FULLY OFFLINE — NOTHING LEAVES THIS DEVICE',
                textAlign: TextAlign.center,
                style: AppType.monoLabel.copyWith(
                  color: skin.onStage.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    WidgetRef ref,
    Skin skin,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: skin.scrim,
      builder: (context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              color: Colors.transparent,
              child: RisoCard(
                color: skin.boardSurface,
                padding: const EdgeInsets.all(AppSpacing.s20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'RESET?',
                      style: AppType.subheading.copyWith(color: skin.accent),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'EVERY CLEARED STAGE, BEST SCORE AND UNLOCKED SKIN GOES '
                      'BACK TO ZERO. THIS CANNOT BE UNDONE.',
                      style: AppType.monoLabel.copyWith(
                        color: skin.onStage,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    PillButton(
                      label: 'Yes, reset',
                      skin: skin,
                      expand: true,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                    const SizedBox(height: 10),
                    OutlinedActionButton(
                      label: 'Cancel',
                      skin: skin,
                      expand: true,
                      color: skin.onStage,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    await ref.read(progressProvider.notifier).resetAll();
    ref.read(settingsProvider.notifier).reload();
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.skin,
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final Skin skin;
  final String label;
  final String detail;
  final bool value;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return RisoCard(
      color: skin.boardSurface,
      onTap: onChanged,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppType.body.copyWith(color: skin.onStage),
                ),
                const SizedBox(height: 7),
                Text(
                  detail,
                  style: AppType.monoLabel.copyWith(
                    color: skin.onStage.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Switch(skin: skin, on: value),
        ],
      ),
    );
  }
}

/// A flat pill switch — no elevation, no platform chrome.
class _Switch extends StatelessWidget {
  const _Switch({required this.skin, required this.on});

  final Skin skin;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: 56,
      height: 32,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: on ? skin.accent : skin.cell,
        borderRadius: AppRadius.pillRadius,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: on ? skin.onAccent : skin.onStage,
            borderRadius: AppRadius.pillRadius,
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.skin,
    required this.label,
    required this.value,
  });

  final Skin skin;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: AppType.monoLabel.copyWith(
            color: skin.onStage.withValues(alpha: 0.75),
          ),
        ),
        Text(value, style: AppType.body.copyWith(color: skin.accent)),
      ],
    );
  }
}

/// A row that opens another screen. Same shape as [_SettingRow] with a chevron
/// where the switch would be.
class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.skin,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final Skin skin;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RisoCard(
      color: skin.boardSurface,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppType.body.copyWith(color: skin.onStage),
                ),
                const SizedBox(height: 7),
                Text(
                  detail.toUpperCase(),
                  style: AppType.monoLabel.copyWith(
                    color: skin.onStage.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: skin.accent),
        ],
      ),
    );
  }
}

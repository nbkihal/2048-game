import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/audio_controller.dart';
import '../core/skin.dart';
import '../data/skins_data.dart';
import '../data/stages_data.dart';
import '../state/providers.dart';
import '../widgets/ui_kit.dart';

/// The skin picker. Each card previews the skin with a real mini board rather
/// than a swatch row, because what matters is how the tile ramp reads in play.
class SkinsScreen extends ConsumerWidget {
  const SkinsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinProvider);
    final settings = ref.watch(settingsProvider);
    final cleared = ref.watch(progressProvider).clearedCount;
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
                    'SKINS',
                    style: AppType.subheading.copyWith(color: skin.accent),
                  ),
                  const Spacer(),
                  MonoTag(
                    label:
                        '${kSkins.where((s) => isSkinUnlocked(s, cleared)).length} / ${kSkins.length}',
                    color: skin.onStage,
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
                'SKINS UNLOCK AS YOU CLEAR STAGES — NOTHING HERE COSTS MONEY.',
                style: AppType.monoLabel.copyWith(
                  color: skin.onStage.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s20,
                  0,
                  AppSpacing.s20,
                  AppSpacing.s40,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: kSkins.length,
                itemBuilder: (context, index) {
                  final entry = kSkins[index];
                  final unlocked = isSkinUnlocked(entry, cleared);
                  return _SkinCard(
                    skin: entry,
                    shellSkin: skin,
                    unlocked: unlocked,
                    selected: entry.id == settings.skinId,
                    onTap: unlocked
                        ? () => ref
                              .read(settingsProvider.notifier)
                              .selectSkin(entry.id)
                        : null,
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

class _SkinCard extends StatelessWidget {
  const _SkinCard({
    required this.skin,
    required this.shellSkin,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  /// The skin this card is advertising.
  final Skin skin;

  /// The skin currently in force, which draws the card's own chrome.
  final Skin shellSkin;

  final bool unlocked;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: unlocked ? 1 : 0.6,
      child: RisoCard(
        color: skin.stage,
        border: selected ? shellSkin.accent : null,
        onTap: onTap,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _MiniBoard(skin: skin)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    skin.name.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body.copyWith(color: skin.onStage),
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, size: 18, color: skin.accent)
                else if (!unlocked)
                  Icon(Icons.lock_rounded, size: 16, color: skin.onStage),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              unlocked
                  ? skin.tagline
                  : 'CLEAR ${skin.unlockAfterStagesCleared} OF '
                        '${kStages.length}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.monoLabel.copyWith(
                color: skin.onStage.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 2x2 sample of the skin's board, showing four rungs of the tile ramp.
class _MiniBoard extends StatelessWidget {
  const _MiniBoard({required this.skin});

  final Skin skin;

  static const _sample = [2, 8, 32, 512];

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: skin.boardSurface,
          borderRadius: AppRadius.cardRadius,
        ),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final value in _sample)
              LayoutBuilder(
                builder: (context, constraints) {
                  final style = skin.styleFor(value);
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: style.background,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                    child: FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '$value',
                          style: AppType.tile(
                            constraints.maxWidth,
                            '$value'.length,
                          ).copyWith(color: style.foreground),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/audio_controller.dart';
import '../core/page_route.dart';
import '../core/skin.dart';
import '../data/daily.dart';
import '../data/skins_data.dart';
import '../data/stages_data.dart';
import '../state/providers.dart';
import '../widgets/ui_kit.dart';
import 'endless_screen.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'settings_screen.dart';
import 'skins_screen.dart';
import 'stage_select_screen.dart';

/// The title screen: the mark, one line of status, one primary action.
///
/// Everything else the player might want is a small icon in the tray at the
/// bottom, so the screen only ever asks one question — play or not.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // A first-time player gets the rules before the title screen means
    // anything, so the intro opens itself once and never again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(persistenceProvider).introSeen) return;
      Navigator.of(context)
          .push(FadeThroughRoute(child: const HowToPlayScreen(isIntro: true)));
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinProvider);
    final progress = ref.watch(progressProvider);
    final audio = ref.watch(audioProvider);
    final saved = ref.watch(savedRunProvider);
    final continueStage = progress.continueStage;
    final started = progress.hasStarted() || saved != null;

    // A run left open by a previous session is what "Continue" means; without
    // one it falls back to the furthest stage the ladder has opened.
    final resumeStage = saved?.stage ?? continueStage;
    final seed = todaysSeed();

    void go(Widget screen) {
      audio.play(Sfx.tap);
      Navigator.of(context).push(FadeThroughRoute(child: screen));
    }

    return Scaffold(
      backgroundColor: skin.stage,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                // Without this the column is unbounded inside the scroll view
                // and the spacers collapse, stacking everything at the top.
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.s20,
                      AppSpacing.s20,
                      AppSpacing.s20,
                      AppSpacing.s20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 56,
                            height: 56,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s20),
                        _Hero(skin: skin),
                        const SizedBox(height: AppSpacing.s16),
                        // Where "Continue" leads and how far the player has got.
                        // The stage name lives here rather than in the button
                        // label, which a long name would truncate.
                        _Status(
                          skin: skin,
                          lines: started
                              ? [
                                  saved != null
                                      ? 'RESUME — ${resumeStage.name}'
                                      : 'NEXT — ${continueStage.name}',
                                  'BEST ${progress.highScore}   ·   '
                                      '${progress.clearedCount} OF '
                                      '${kStages.length} CLEARED   ·   '
                                      '${progress.medalCount} MEDALS',
                                ]
                              : [
                                  '${kStages.length} STAGES   ·   '
                                      '${kSkins.length} SKINS TO UNLOCK',
                                ],
                        ),
                        const Spacer(),
                        _DailyCard(
                          skin: skin,
                          best: progress.bestForDay(seed),
                          onTap: () =>
                              go(const GameScreen(stageId: kDailyStageId)),
                        ),
                        const SizedBox(height: 10),
                        PillButton(
                          label: saved != null
                              ? 'Resume'
                              : started
                              ? 'Continue'
                              : 'Play',
                          icon: Icons.play_arrow_rounded,
                          skin: skin,
                          expand: true,
                          onPressed: () => go(
                            GameScreen(
                              stageId: started
                                  ? resumeStage.id
                                  : kStages.first.id,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Half-width pills: the display face is wide enough
                        // that a label plus an icon would ellipsize, so these
                        // two carry the word alone.
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedActionButton(
                                label: 'Stages',
                                skin: skin,
                                expand: true,
                                onPressed: () => go(const StageSelectScreen()),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedActionButton(
                                label: 'Endless',
                                skin: skin,
                                expand: true,
                                color: skin.onStage,
                                onPressed: () => go(const EndlessScreen()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _TrayItem(
                              skin: skin,
                              icon: Icons.help_outline_rounded,
                              label: 'How to play',
                              onPressed: () => go(const HowToPlayScreen()),
                            ),
                            _TrayItem(
                              skin: skin,
                              icon: Icons.palette_outlined,
                              label: 'Skins',
                              onPressed: () => go(const SkinsScreen()),
                            ),
                            _TrayItem(
                              skin: skin,
                              icon: Icons.tune_rounded,
                              label: 'Settings',
                              onPressed: () => go(const SettingsScreen()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// "Hero Display Headline": type sized to bleed to the canvas edges, with the
/// colour alternating between Hi-Vis and Buttery per glyph.
class _Hero extends StatelessWidget {
  const _Hero({required this.skin});

  final Skin skin;

  @override
  Widget build(BuildContext context) {
    const digits = ['2', '0', '4', '8'];
    return FittedBox(
      fit: BoxFit.fitWidth,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < digits.length; i++)
            Text(
              digits[i],
              style: AppType.display.copyWith(
                color: i.isEven ? skin.accent : skin.accentSoft,
              ),
            ),
        ],
      ),
    );
  }
}

/// Today's challenge, offered above the campaign because it expires.
class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.skin,
    required this.best,
    required this.onTap,
  });

  final Skin skin;
  final int best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RisoCard(
      color: skin.boardSurface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.today_rounded, size: 20, color: skin.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'DAILY CHALLENGE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(color: skin.onStage),
                      ),
                    ),
                    Text(
                      dailyLabel(DateTime.now()),
                      style: AppType.monoLabel.copyWith(
                        color: skin.onStage.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  best > 0
                      ? "TODAY'S BEST $best"
                      : 'NOT PLAYED YET',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

/// The one line of state under the wordmark.
class _Status extends StatelessWidget {
  const _Status({required this.skin, required this.lines});

  final Skin skin;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Text(
              line.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppType.monoLabel.copyWith(
                color: skin.onStage.withValues(alpha: 0.8),
                height: 1.3,
              ),
            ),
          ),
      ],
    );
  }
}

/// One secondary destination: an outlined icon over its own caption.
class _TrayItem extends StatelessWidget {
  const _TrayItem({
    required this.skin,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Skin skin;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconPill(icon: icon, color: skin.onStage, onPressed: onPressed),
        const SizedBox(height: 9),
        Text(
          label.toUpperCase(),
          style: AppType.caption.copyWith(
            color: skin.onStage.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }
}

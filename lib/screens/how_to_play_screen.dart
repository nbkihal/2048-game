import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../core/audio_controller.dart';
import '../core/skin.dart';
import '../data/skins_data.dart';
import '../data/stages_data.dart';
import '../state/providers.dart';
import '../widgets/ui_kit.dart';

/// The rules, one idea per card.
///
/// The same screen is both the first-run intro and the "How to play" entry from
/// the home screen — only the closing button changes, so there is one place to
/// edit when a rule changes.
class HowToPlayScreen extends ConsumerStatefulWidget {
  const HowToPlayScreen({super.key, this.isIntro = false});

  /// True when this is the automatic first-run showing. Finishing it records
  /// that the player has seen the rules.
  final bool isIntro;

  @override
  ConsumerState<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends ConsumerState<HowToPlayScreen> {
  static const _count = 5;

  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    if (widget.isIntro) ref.read(persistenceProvider).setIntroSeen(true);
    ref.read(audioProvider).play(Sfx.tap);
    Navigator.of(context).pop();
  }

  void _next() {
    if (_index >= _count - 1) {
      _finish();
      return;
    }
    ref.read(audioProvider).play(Sfx.tap);
    _pages.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final skin = ref.watch(skinProvider);
    final last = _index == _count - 1;

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
                0,
              ),
              child: Row(
                children: [
                  IconPill(
                    icon: Icons.close_rounded,
                    color: skin.onStage,
                    tooltip: 'Close',
                    onPressed: _finish,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'HOW TO PLAY',
                      overflow: TextOverflow.ellipsis,
                      // Two words longer than any other screen title, so it
                      // steps down a size rather than losing its second half.
                      style: AppType.subheading.copyWith(
                        color: skin.accent,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  MonoTag(
                    label: '${_index + 1} / $_count',
                    color: skin.onStage,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _Card(
                    skin: skin,
                    title: 'SWIPE',
                    lines: const [
                      'SWIPE ANYWHERE ON THE BOARD. EVERY TILE SLIDES THAT WAY '
                          'UNTIL IT HITS A WALL OR ANOTHER TILE.',
                      'ONE NEW TILE APPEARS AFTER EVERY SWIPE THAT CHANGES '
                          'SOMETHING.',
                    ],
                    visual: _SwipeVisual(skin: skin),
                  ),
                  _Card(
                    skin: skin,
                    title: 'MERGE',
                    lines: const [
                      'TWO TILES WITH THE SAME NUMBER MERGE INTO ONE WORTH '
                          'DOUBLE. THE NEW NUMBER IS ADDED TO YOUR SCORE.',
                      'A TILE CAN ONLY MERGE ONCE PER SWIPE.',
                    ],
                    visual: _MergeVisual(skin: skin),
                  ),
                  _Card(
                    skin: skin,
                    title: 'HIT THE\nTARGET',
                    lines: [
                      'EVERY STAGE ASKS FOR ONE TILE — '
                          '${kStages.first.targetTile} FIRST, THEN HIGHER. '
                          'BUILD IT AND THE STAGE IS CLEARED.',
                      'LATER STAGES ADD TWISTS: A SMALLER BOARD, A MOVE '
                          'BUDGET, A FROZEN CELL.',
                    ],
                    visual: _TargetVisual(skin: skin),
                  ),
                  _Card(
                    skin: skin,
                    title: 'GAME\nOVER',
                    lines: const [
                      'WHEN THE GRID IS FULL AND NO SWIPE CAN MERGE ANYTHING, '
                          'THE RUN IS OVER AND THIS FACE APPEARS.',
                      'KEEP YOUR BIGGEST TILE IN ONE CORNER TO AVOID IT — OR '
                          'TAP UNDO AND TAKE THE MOVE BACK.',
                    ],
                    visual: _GameOverVisual(skin: skin),
                  ),
                  _Card(
                    skin: skin,
                    title: 'UNLOCKS',
                    lines: [
                      'CLEARING A STAGE UNLOCKS THE NEXT — '
                          '${kStages.length} IN TOTAL, ON BOARDS FROM 3×3 TO '
                          '6×6. SKINS UNLOCK ON THE COUNT YOU HAVE CLEARED.',
                      'ENDLESS MODE NEEDS NO UNLOCK: FOUR BOARD SIZES, NO '
                          'TARGET, JUST A HIGH SCORE.',
                    ],
                    visual: _UnlockVisual(skin: skin),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20,
                AppSpacing.s16,
                AppSpacing.s20,
                AppSpacing.s16,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _count; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _index ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? skin.accent
                                : skin.onStage.withValues(alpha: 0.3),
                            borderRadius: AppRadius.pillRadius,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.elementGap),
                  PillButton(
                    label: last
                        ? (widget.isIntro ? 'Start playing' : 'Done')
                        : 'Next',
                    icon: last
                        ? Icons.play_arrow_rounded
                        : Icons.arrow_forward_rounded,
                    skin: skin,
                    expand: true,
                    onPressed: _next,
                  ),
                  if (!last)
                    UnderlineTextLink(
                      label: 'Skip',
                      color: skin.onStage.withValues(alpha: 0.75),
                      onPressed: _finish,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One rule: a visual block on top, a headline, then the copy.
class _Card extends StatelessWidget {
  const _Card({
    required this.skin,
    required this.title,
    required this.lines,
    required this.visual,
  });

  final Skin skin;
  final String title;
  final List<String> lines;
  final Widget visual;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s20,
        AppSpacing.s16,
        AppSpacing.s20,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: RisoCard(
                  color: skin.boardSurface,
                  padding: const EdgeInsets.all(AppSpacing.s20),
                  child: visual,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.elementGap),
          Text(
            title,
            style: AppType.headingSmall.copyWith(
              color: skin.accent,
              fontSize: 42,
            ),
          ),
          const SizedBox(height: 14),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                line,
                style: AppType.monoLabel.copyWith(
                  color: skin.onStage.withValues(alpha: 0.85),
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A tile drawn in the active skin's own ramp, so the explainer always matches
/// the board the player is about to see.
class _Tile extends StatelessWidget {
  const _Tile({required this.skin, required this.value, this.size = 52});

  final Skin skin;
  final int value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = skin.styleFor(value);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: AppRadius.cardRadius,
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            '$value',
            style: AppType.tile(
              size,
              '$value'.length,
            ).copyWith(color: style.foreground),
          ),
        ),
      ),
    );
  }
}

/// A 4-wide sample board built from a value table, where 0 is an empty cell.
class _SampleBoard extends StatelessWidget {
  const _SampleBoard({required this.skin, required this.rows, this.size = 44});

  final Skin skin;
  final List<List<int>> rows;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final value in row)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: value == 0
                        ? Container(
                            width: size,
                            height: size,
                            decoration: BoxDecoration(
                              color: skin.cell,
                              borderRadius: AppRadius.cardRadius,
                            ),
                          )
                        : _Tile(skin: skin, value: value, size: size),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SwipeVisual extends StatelessWidget {
  const _SwipeVisual({required this.skin});

  final Skin skin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SampleBoard(
          skin: skin,
          rows: const [
            [0, 2, 0, 4],
            [0, 0, 8, 0],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final icon in const [
              Icons.arrow_back_rounded,
              Icons.arrow_upward_rounded,
              Icons.arrow_downward_rounded,
              Icons.arrow_forward_rounded,
            ])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(icon, color: skin.accent, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 14),
        MonoTag(label: 'SWIPE ANY DIRECTION', color: skin.onStage),
      ],
    );
  }
}

class _MergeVisual extends StatelessWidget {
  const _MergeVisual({required this.skin});

  final Skin skin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MergeRow(skin: skin, from: 2, to: 4),
        const SizedBox(height: 12),
        _MergeRow(skin: skin, from: 4, to: 8),
        const SizedBox(height: 16),
        MonoTag(label: '+4, THEN +8 ON YOUR SCORE', color: skin.onStage),
      ],
    );
  }
}

class _MergeRow extends StatelessWidget {
  const _MergeRow({required this.skin, required this.from, required this.to});

  final Skin skin;
  final int from;
  final int to;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Tile(skin: skin, value: from, size: 46),
        const SizedBox(width: 7),
        Icon(Icons.add_rounded, color: skin.onStage, size: 20),
        const SizedBox(width: 7),
        _Tile(skin: skin, value: from, size: 46),
        const SizedBox(width: 7),
        Icon(Icons.arrow_forward_rounded, color: skin.accent, size: 20),
        const SizedBox(width: 7),
        _Tile(skin: skin, value: to, size: 46),
      ],
    );
  }
}

class _TargetVisual extends StatelessWidget {
  const _TargetVisual({required this.skin});

  final Skin skin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Tile(skin: skin, value: 16, size: 46),
            const SizedBox(width: 7),
            Icon(Icons.arrow_forward_rounded, color: skin.onStage, size: 18),
            const SizedBox(width: 7),
            _Tile(skin: skin, value: 32, size: 46),
            const SizedBox(width: 7),
            Icon(Icons.arrow_forward_rounded, color: skin.onStage, size: 18),
            const SizedBox(width: 7),
            _Tile(skin: skin, value: 64, size: 46),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: SizedBox(
            height: 10,
            width: 214,
            child: Row(
              children: [
                Expanded(flex: 3, child: Container(color: skin.accent)),
                Expanded(child: Container(color: skin.cell)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        MonoTag(
          label: 'STAGE 1 TARGET — ${kStages.first.targetTile}',
          color: skin.onAccent,
          background: skin.accent,
          bordered: false,
        ),
      ],
    );
  }
}

class _GameOverVisual extends StatelessWidget {
  const _GameOverVisual({required this.skin});

  final Skin skin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.45,
              child: _SampleBoard(
                skin: skin,
                size: 38,
                rows: const [
                  [2, 4, 2, 4],
                  [4, 2, 4, 2],
                  [2, 4, 2, 4],
                ],
              ),
            ),
            StatusBadge(
              icon: Icons.sentiment_very_dissatisfied_rounded,
              color: AppColors.firecrackerRed,
              fill: skin.boardSurface,
            ),
          ],
        ),
        const SizedBox(height: 8),
        MonoTag(label: 'NO MOVES LEFT', color: AppColors.firecrackerRed),
      ],
    );
  }
}

class _UnlockVisual extends StatelessWidget {
  const _UnlockVisual({required this.skin});

  final Skin skin;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final entry in kSkins)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: entry.stage,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: entry.accent, width: 2),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: Text(
                    entry.name.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: AppType.monoLabel.copyWith(color: skin.onStage),
                  ),
                ),
                Text(
                  entry.isDefault
                      ? 'FROM THE START'
                      : 'CLEAR ${entry.unlockAfterStagesCleared} '
                            'STAGE${entry.unlockAfterStagesCleared == 1 ? '' : 'S'}',
                  style: AppType.monoLabel.copyWith(
                    color: skin.onStage.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

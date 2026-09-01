import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/skin.dart';
import '../models/medal.dart';
import '../models/stage.dart';
import 'confetti_overlay.dart';
import 'medal_row.dart';
import 'ui_kit.dart';

/// What the player can do from an end-of-attempt panel.
enum OutcomeAction { keepGoing, nextStage, retry, stageSelect }

/// Shared shell for the stage-clear and game-over panels.
///
/// Both are the same composition — a headline, a couple of stat blocks and a
/// stack of actions — so they live in one widget with different content rather
/// than two near-identical files.
class OutcomeDialog extends StatefulWidget {
  const OutcomeDialog({
    super.key,
    required this.skin,
    required this.won,
    required this.stage,
    required this.score,
    required this.best,
    required this.isNewBest,
    required this.nextStage,
    required this.unlockedSkinNames,
    required this.canKeepGoing,
    required this.onAction,
    required this.lostToMoveLimit,
    this.stageSelectLabel = 'Stage select',
    this.medals = const {},
    this.freshMedals = const {},
  });

  final Skin skin;
  final bool won;
  final Stage stage;
  final int score;
  final int best;
  final bool isNewBest;

  /// The stage this clear unlocked, if any.
  final Stage? nextStage;

  final List<String> unlockedSkinNames;

  /// False on the endless stage and once the player already chose to continue.
  final bool canKeepGoing;

  /// Distinguishes "you ran out of moves" from "the board is stuck", which are
  /// very different lessons for the player.
  final bool lostToMoveLimit;

  /// Label for the secondary way out — the campaign ladder for a stage, the
  /// board picker for an endless run.
  final String stageSelectLabel;

  /// Every medal the stage holds now, including ones earned long ago.
  final Set<Medal> medals;

  /// The subset this attempt just added, called out in the unlocks card.
  final Set<Medal> freshMedals;

  final ValueChanged<OutcomeAction> onAction;

  @override
  State<OutcomeDialog> createState() => _OutcomeDialogState();
}

class _OutcomeDialogState extends State<OutcomeDialog>
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

    return Stack(
      children: [
        FadeTransition(
          opacity: fade,
          child: Container(color: skin.scrim),
        ),
        if (widget.won) const Positioned.fill(child: ConfettiOverlay()),
        FadeTransition(
          opacity: fade,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s20),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1).animate(
                    CurvedAnimation(
                      parent: _controller,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _panel(skin),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _panel(Skin skin) {
    final headline = widget.won ? 'STAGE\nCLEAR' : 'GAME\nOVER';
    final blurb = widget.won
        ? 'YOU HIT ${widget.stage.targetTile}'
        : widget.lostToMoveLimit
        ? 'OUT OF MOVES'
        : 'NO MOVES LEFT';

    // The outcome has to read before a single word does, so each ending gets
    // its own mark: a cup for a clear, a stopped clock for a spent budget, and
    // the dead face for a board with nothing left to merge.
    final mark = widget.won
        ? Icons.emoji_events_rounded
        : widget.lostToMoveLimit
        ? Icons.timer_off_rounded
        : Icons.sentiment_very_dissatisfied_rounded;
    final markColor = widget.won ? skin.accent : AppColors.firecrackerRed;

    return RisoCard(
      color: skin.boardSurface,
      padding: const EdgeInsets.all(AppSpacing.s20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StatusBadge(icon: mark, color: markColor, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  headline,
                  style: AppType.headingSmall.copyWith(
                    color: widget.won ? skin.accent : skin.onStage,
                    fontSize: 46,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // The column stretches its children; a stamped tag has to hug its
          // own text or it reads as an empty input field.
          Align(
            alignment: Alignment.centerLeft,
            child: MonoTag(label: blurb, color: markColor),
          ),
          const SizedBox(height: AppSpacing.s20),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  skin: skin,
                  label: 'Score',
                  value: '${widget.score}',
                  highlight: widget.isNewBest,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  skin: skin,
                  label: widget.isNewBest ? 'New best' : 'Best',
                  value: '${widget.best}',
                ),
              ),
            ],
          ),
          if (widget.medals.isNotEmpty) ...[
            const SizedBox(height: 14),
            MedalRow(
              earned: widget.medals,
              color: skin.onStage,
              showLabels: true,
            ),
          ],
          if (widget.nextStage != null ||
              widget.unlockedSkinNames.isNotEmpty ||
              widget.freshMedals.isNotEmpty)
            ..._unlocks(skin),
          const SizedBox(height: AppSpacing.s20),
          if (widget.won && widget.nextStage != null)
            PillButton(
              label: 'Next: ${widget.nextStage!.name}',
              icon: Icons.arrow_forward_rounded,
              skin: skin,
              expand: true,
              onPressed: () => widget.onAction(OutcomeAction.nextStage),
            )
          else
            PillButton(
              label: widget.won ? 'Back to stages' : 'Try again',
              icon: widget.won
                  ? Icons.grid_view_rounded
                  : Icons.refresh_rounded,
              skin: skin,
              expand: true,
              onPressed: () => widget.onAction(
                widget.won ? OutcomeAction.stageSelect : OutcomeAction.retry,
              ),
            ),
          if (widget.won && widget.canKeepGoing) ...[
            const SizedBox(height: 10),
            OutlinedActionButton(
              label: 'Keep going',
              icon: Icons.all_inclusive_rounded,
              skin: skin,
              expand: true,
              onPressed: () => widget.onAction(OutcomeAction.keepGoing),
            ),
          ],
          if (!widget.won) ...[
            const SizedBox(height: 10),
            OutlinedActionButton(
              label: widget.stageSelectLabel,
              icon: Icons.grid_view_rounded,
              skin: skin,
              expand: true,
              color: skin.onStage,
              onPressed: () => widget.onAction(OutcomeAction.stageSelect),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _unlocks(Skin skin) {
    final lines = <String>[
      if (widget.nextStage != null)
        'STAGE UNLOCKED — ${widget.nextStage!.name}',
      for (final name in widget.unlockedSkinNames) 'SKIN UNLOCKED — $name',
      for (final medal in widget.freshMedals) 'MEDAL — ${medal.label}',
    ];
    return [
      const SizedBox(height: 10),
      RisoCard(
        color: skin.accent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  line.toUpperCase(),
                  style: AppType.monoLabel.copyWith(color: skin.onAccent),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.skin,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final Skin skin;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final ink = highlight ? skin.onAccent : skin.onStage;
    return RisoCard(
      color: highlight ? skin.accent : skin.cell,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppType.monoLabel.copyWith(
              color: ink.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 7),
          Text(value, style: AppType.bodyLarge.copyWith(color: ink)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/skin.dart';

/// The "+128" that floats off a merge, plus the chain count when a single
/// swipe collapsed more than one pair.
///
/// It is keyed on the move serial rather than the amount, so two identical
/// gains in a row still play twice.
class ScorePopup extends StatefulWidget {
  const ScorePopup({
    super.key,
    required this.skin,
    required this.gain,
    required this.mergeCount,
    required this.serial,
  });

  final Skin skin;
  final int gain;
  final int mergeCount;

  /// Increments once per valid move.
  final int serial;

  @override
  State<ScorePopup> createState() => _ScorePopupState();
}

class _ScorePopupState extends State<ScorePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kScorePopupDuration,
  );

  @override
  void initState() {
    super.initState();
    if (widget.gain > 0) _controller.forward(from: 0);
  }

  @override
  void didUpdateWidget(ScorePopup old) {
    super.didUpdateWidget(old);
    if (widget.serial != old.serial && widget.gain > 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.skin;
    final chain = widget.mergeCount >= kChainThreshold;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          if (t == 0 || t == 1) return const SizedBox.shrink();
          // Rises and fades: fully opaque for the first third, gone by the end.
          final opacity = t < 0.3 ? 1.0 : 1 - ((t - 0.3) / 0.7);
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -26 * t),
              child: child,
            ),
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+${widget.gain}',
              style: AppType.bodyLarge.copyWith(color: skin.accent),
            ),
            if (chain) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: skin.accent,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  '${widget.mergeCount} CHAIN',
                  style: AppType.monoLabel.copyWith(
                    color: skin.onAccent,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/skin.dart';
import '../models/tile.dart';

/// One numbered tile.
///
/// The slide is handled by the parent (an `AnimatedPositioned` keyed on the
/// tile id). What lives here is what happens *to* the tile in place: the
/// scale-in of a spawn and the pop of a merge.
class TileView extends StatefulWidget {
  const TileView({
    super.key,
    required this.tile,
    required this.skin,
    required this.size,
  });

  final Tile tile;
  final Skin skin;
  final double size;

  @override
  State<TileView> createState() => _TileViewState();
}

class _TileViewState extends State<TileView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    // A tile that exists on the first frame of a board was not spawned by a
    // move — only flagged tiles get an entrance.
    if (widget.tile.isNew) {
      _playSpawn();
    } else if (widget.tile.mergedFrom) {
      _playPop();
    } else {
      _scale = const AlwaysStoppedAnimation(1);
    }
  }

  @override
  void didUpdateWidget(TileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The same tile id merging again means a fresh pop, so compare the value
    // rather than the flag alone.
    final merged = widget.tile.mergedFrom &&
        (!oldWidget.tile.mergedFrom ||
            oldWidget.tile.value != widget.tile.value);
    if (merged) _playPop();
  }

  void _playSpawn() {
    _controller
      ..stop()
      ..duration = kSpawnDuration;
    _scale = Tween<double>(begin: kSpawnStartScale, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward(from: 0);
  }

  void _playPop() {
    _controller
      ..stop()
      ..duration = kMergePopDuration;
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: kMergePopScale)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: kMergePopScale, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_controller);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.skin.styleFor(widget.tile.value);
    final label = widget.tile.value.toString();

    return ScaleTransition(
      scale: _scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: AppRadius.cardRadius,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.size * 0.06),
            child: FittedBox(
              child: Text(
                label,
                maxLines: 1,
                style: AppType.tile(widget.size, label.length).copyWith(
                  color: style.foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

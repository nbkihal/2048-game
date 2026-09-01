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
    this.picking = false,
  });

  final Tile tile;
  final Skin skin;
  final double size;

  /// The hammer is armed and this tile is a legal target, so it advertises
  /// itself as tappable.
  final bool picking;

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

    final fuse = widget.tile.fuse;
    // A bomb has to be findable at a glance on a busy board, so it takes a red
    // edge on top of whatever colour its value earned it.
    final border = widget.picking
        ? Border.all(color: widget.skin.accent, width: 3)
        : fuse != null
        ? Border.all(color: AppColors.firecrackerRed, width: 3)
        : null;

    return ScaleTransition(
      scale: _scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: AppRadius.cardRadius,
          border: border,
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.size * 0.06),
                child: FittedBox(
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppType.tile(
                      widget.size,
                      label.length,
                    ).copyWith(color: style.foreground),
                  ),
                ),
              ),
            ),
            if (fuse != null)
              Positioned(
                top: widget.size * 0.04,
                right: widget.size * 0.04,
                child: _Fuse(count: fuse, size: widget.size),
              ),
            if (widget.picking)
              Center(
                child: Icon(
                  Icons.close_rounded,
                  size: widget.size * 0.4,
                  color: widget.skin.accent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The moves a bomb has left, stamped in its corner.
class _Fuse extends StatelessWidget {
  const _Fuse({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final diameter = size * 0.36;
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.firecrackerRed,
        shape: BoxShape.circle,
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(
            '$count',
            style: AppType.monoLabel.copyWith(
              color: AppColors.boneWhite,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

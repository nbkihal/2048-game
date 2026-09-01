import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../core/skin.dart';
import '../models/board.dart';
import '../models/tile.dart';
import 'tile_view.dart';

/// Renders the grid and its tiles.
///
/// Tiles live in a [Stack] and are keyed by their stable id, so when a move
/// gives a tile new coordinates the same widget simply animates to them. This
/// is the whole trick behind the slide — nothing is torn down and rebuilt.
class BoardView extends StatefulWidget {
  const BoardView({
    super.key,
    required this.board,
    required this.skin,
    required this.mergedAwayTiles,
    this.dimmed = false,
    this.picking = false,
    this.onTileTap,
  });

  final Board board;

  final Skin skin;

  /// Tiles absorbed by the last move. They no longer exist on the board, but
  /// they are kept on screen just long enough to slide into the cell they
  /// merged with — otherwise a merge looks like a tile blinking out of
  /// existence halfway across the grid.
  final List<Tile> mergedAwayTiles;

  /// Greys the board out while the pause menu is up.
  final bool dimmed;

  /// The hammer is armed, so every tile on the board is a target.
  final bool picking;

  /// Called with the tile the player picked while [picking].
  final ValueChanged<Tile>? onTileTap;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  List<Tile> _ghosts = const [];
  Timer? _ghostTimer;

  @override
  void initState() {
    super.initState();
    _ghosts = widget.mergedAwayTiles;
    _scheduleGhostCleanup();
  }

  @override
  void didUpdateWidget(BoardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.mergedAwayTiles, widget.mergedAwayTiles)) {
      _ghosts = widget.mergedAwayTiles;
      _scheduleGhostCleanup();
    }
  }

  void _scheduleGhostCleanup() {
    _ghostTimer?.cancel();
    if (_ghosts.isEmpty) return;
    _ghostTimer = Timer(kGhostLifetime, () {
      if (mounted) setState(() => _ghosts = const []);
    });
  }

  @override
  void dispose() {
    _ghostTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.board.size;

    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Solve for the cell size: N cells, N-1 gaps and two outer paddings,
          // all expressed as fractions of the cell so every grid size looks the
          // same.
          final units = size + (size - 1) * kCellGapRatio + 2 * kBoardPaddingRatio;
          final cell = constraints.maxWidth / units;
          final gap = cell * kCellGapRatio;
          final pad = cell * kBoardPaddingRatio;

          double offset(int index) => pad + index * (cell + gap);

          return AnimatedOpacity(
            opacity: widget.dimmed ? 0.45 : 1,
            duration: kDialogDuration,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.skin.boardSurface,
                borderRadius: AppRadius.cardRadius,
              ),
              child: Stack(
                children: [
                  for (var row = 0; row < size; row++)
                    for (var col = 0; col < size; col++)
                      Positioned(
                        left: offset(col),
                        top: offset(row),
                        width: cell,
                        height: cell,
                        child: _CellSlot(
                          blocked: widget.board.isBlocked(row, col),
                          skin: widget.skin,
                        ),
                      ),
                  // Ghosts are painted first so the tile they merge into pops
                  // over the top of them.
                  for (final tile in _ghosts)
                    _PositionedTile(
                      key: ValueKey(tile.id),
                      tile: tile,
                      skin: widget.skin,
                      left: offset(tile.col),
                      top: offset(tile.row),
                      cell: cell,
                      ghost: true,
                    ),
                  for (final tile in widget.board.tiles)
                    _PositionedTile(
                      key: ValueKey(tile.id),
                      tile: tile,
                      skin: widget.skin,
                      left: offset(tile.col),
                      top: offset(tile.row),
                      cell: cell,
                      ghost: false,
                      picking: widget.picking,
                      onTap: widget.picking && widget.onTileTap != null
                          ? () => widget.onTileTap!(tile)
                          : null,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CellSlot extends StatelessWidget {
  const _CellSlot({required this.blocked, required this.skin});

  final bool blocked;
  final Skin skin;

  @override
  Widget build(BuildContext context) {
    if (!blocked) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: skin.cell,
          borderRadius: AppRadius.cardRadius,
        ),
      );
    }
    // A wall reads as a solid stamped block, not an empty cell.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: skin.wall,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Center(
        child: Icon(
          Icons.close_rounded,
          size: 18,
          color: skin.accent.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

/// A tile placed on the grid. Changing [left]/[top] animates the slide.
class _PositionedTile extends StatelessWidget {
  const _PositionedTile({
    super.key,
    required this.tile,
    required this.skin,
    required this.left,
    required this.top,
    required this.cell,
    required this.ghost,
    this.picking = false,
    this.onTap,
  });

  final Tile tile;
  final Skin skin;
  final double left;
  final double top;
  final double cell;
  final bool ghost;
  final bool picking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final view = TileView(
      tile: tile,
      skin: skin,
      size: cell,
      picking: picking,
    );

    return AnimatedPositioned(
      duration: kSlideDuration,
      curve: Curves.easeOutCubic,
      left: left,
      top: top,
      width: cell,
      height: cell,
      child: AnimatedOpacity(
        // The ghost fades as it arrives so the merge reads as absorption.
        opacity: ghost ? 0 : 1,
        duration: kSlideDuration,
        child: onTap == null
            ? view
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: view,
              ),
      ),
    );
  }
}

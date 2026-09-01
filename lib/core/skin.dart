import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Background + foreground pair for one rung of the tile value ramp.
class TileStyle {
  const TileStyle(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

/// A full visual theme for the board and the shell around it.
///
/// Skins are pure data (see `data/skins_data.dart`) so adding one is a new
/// entry, never new UI code — the same rule the stage table follows.
class Skin {
  const Skin({
    required this.id,
    required this.name,
    required this.tagline,
    required this.stage,
    required this.boardSurface,
    required this.cell,
    required this.wall,
    required this.accent,
    required this.accentSoft,
    required this.onStage,
    required this.onAccent,
    required this.ramp,
    required this.brightness,
    this.unlockAfterStagesCleared = 0,
  });

  final String id;
  final String name;

  /// One mono-label line shown on the skin card.
  final String tagline;

  /// Level 0 surface — the full-bleed canvas.
  final Color stage;

  /// Level 2 surface — the block the grid sits on.
  final Color boardSurface;

  /// An empty cell within the board.
  final Color cell;

  /// A blocked cell (the `blockedCells` stage twist), rendered as a wall.
  final Color wall;

  /// The single loudest colour on a screen — outlined actions, highlights.
  final Color accent;

  /// The display headline alternates between [accent] and this softer sibling,
  /// the way DESIGN.md alternates Hi-Vis and Buttery Yellow across words.
  final Color accentSoft;

  /// Text and icons drawn directly on [stage].
  final Color onStage;

  /// Text drawn on [accent].
  final Color onAccent;

  /// Tile colours by exponent: `ramp[0]` is the 2-tile, `ramp[1]` the 4, and so
  /// on. Values past the end of the ramp reuse the last few rungs.
  final List<TileStyle> ramp;

  /// Drives status-bar icon brightness and dialog barrier colour.
  final Brightness brightness;

  /// Number of cleared stages required before this skin can be selected.
  /// `0` means available from the start.
  final int unlockAfterStagesCleared;

  bool get isDefault => unlockAfterStagesCleared == 0;

  /// Fill for the primary pill action. DESIGN.md specifies a cream pill on the
  /// violet stage; on a light-stage skin the same cream would disappear, so the
  /// rule is "maximum contrast against the stage" rather than a fixed colour.
  Color get pillFill =>
      brightness == Brightness.dark ? AppColors.boneWhite : AppColors.inkBlack;

  Color get onPill =>
      brightness == Brightness.dark ? AppColors.pureBlack : AppColors.boneWhite;

  /// Scrim behind modal surfaces (pause menu, dialogs).
  Color get scrim => brightness == Brightness.dark
      ? AppColors.pureBlack.withValues(alpha: 0.62)
      : AppColors.inkBlack.withValues(alpha: 0.45);

  /// The style for a tile of [value].
  ///
  /// Very large values keep cycling through the tail of the ramp instead of
  /// clamping, so an endless run keeps producing visibly different tiles.
  TileStyle styleFor(int value) {
    final index = _exponent(value) - 1;
    if (index < 0) return ramp.first;
    if (index < ramp.length) return ramp[index];
    const tail = 3;
    final tailStart = ramp.length - tail;
    if (tailStart <= 0) return ramp.last;
    return ramp[tailStart + (index - ramp.length) % tail];
  }

  static int _exponent(int value) {
    var result = 0;
    var current = value;
    while (current > 1) {
      current >>= 1;
      result++;
    }
    return result;
  }
}

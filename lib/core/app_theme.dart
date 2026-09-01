import 'package:flutter/material.dart';

/// Design tokens, mapped straight from `docs/DESIGN.md` ("Flying Papers").
///
/// Widgets read these tokens and never hardcode a hex value or a size. Per-skin
/// colours (the board, the tile ramp) live in `data/skins_data.dart`; what is
/// here is the fixed part of the system: the brand palette, the type scale, the
/// spacing scale and the two radii.

// ---------------------------------------------------------------------------
// Colours — DESIGN.md "Tokens — Colors"
// ---------------------------------------------------------------------------

abstract final class AppColors {
  /// Primary canvas — the stage every other colour performs on.
  static const duskViolet = Color(0xFF8584BD);

  /// Outlined action borders and linked labels. Never a filled CTA.
  static const hiVisYellow = Color(0xFFF4ED36);

  /// Secondary display text — a mellower sibling of Hi-Vis.
  static const butteryYellow = Color(0xFFF9CC73);

  /// Nested surfaces on the violet stage.
  static const lilacShadow = Color(0xFF61609A);

  static const bubblegumPink = Color(0xFFF8C1BA);
  static const matchaCream = Color(0xFFB5C995);
  static const magentaPunch = Color(0xFFAC4F98);
  static const firecrackerRed = Color(0xFFC94245);

  /// Card surfaces and reverse text on the violet stage.
  static const boneWhite = Color(0xFFF9F5F2);

  /// Body text and primary borders on light surfaces.
  static const inkBlack = Color(0xFF1A1A1A);

  /// Maximum edge contrast — borders and text on yellow surfaces.
  static const pureBlack = Color(0xFF000000);
}

// ---------------------------------------------------------------------------
// Spacing — base unit 4px, "comfortable" density
// ---------------------------------------------------------------------------

abstract final class AppSpacing {
  static const unit = 4.0;

  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s40 = 40.0;
  static const s60 = 60.0;
  static const s80 = 80.0;
  static const s160 = 160.0;

  /// DESIGN.md layout block.
  static const cardPadding = 17.0;
  static const elementGap = 17.0;
  static const sectionGap = 40.0;
}

// ---------------------------------------------------------------------------
// Radii — the signature contrast between sharp blocks and soft pills
// ---------------------------------------------------------------------------

abstract final class AppRadius {
  /// Cards stay at exactly 6px — anything softer reads as SaaS, not riso.
  static const card = 6.0;

  /// Buttons and tags are full pills.
  static const pill = 100.0;

  static const cardRadius = BorderRadius.all(Radius.circular(card));
  static const pillRadius = BorderRadius.all(Radius.circular(pill));
}

// ---------------------------------------------------------------------------
// Typography
// ---------------------------------------------------------------------------

abstract final class AppFonts {
  /// Display family. DESIGN.md names ObviouslyVariable with Founders Grotesk
  /// Condensed / Knockout / Druk Wide as substitutes; Archivo Black is the
  /// closest freely-licensed wide geometric heavyweight.
  static const display = 'Archivo';

  /// Monospaced micro-type. DESIGN.md names bergen_mono with JetBrains Mono as
  /// the substitute, so this one is exact.
  static const mono = 'JetBrainsMono';
}

/// The DESIGN.md type scale, verbatim.
///
/// The poster sizes (100–341px) are meant to bleed to the canvas edges rather
/// than to be used literally on a 390px-wide phone. Hero text therefore renders
/// through a [FittedBox]: the ratios of the scale are preserved while the type
/// still fills the viewport the way the system asks it to.
abstract final class AppType {
  static const _display = AppFonts.display;
  static const _mono = AppFonts.mono;

  /// 10px / 1.0 — nav, footer micro-copy, inline labels.
  static const caption = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    height: 1.0,
    letterSpacing: 0.5,
  );

  /// 12px / 0.80 — the stamped-label mono texture.
  static const monoLabel = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    height: 0.8,
    letterSpacing: 0.6,
  );

  /// 14px / 1.0 — slightly larger mono for data readouts.
  static const monoData = TextStyle(
    fontFamily: _mono,
    fontSize: 14,
    height: 1.0,
  );

  /// 16px / 1.0 / 0.05em — CTAs and button labels.
  static const body = TextStyle(
    fontFamily: _display,
    fontSize: 16,
    height: 1.0,
    letterSpacing: 0.8,
  );

  /// 18px / 0.9.
  static const bodyLarge = TextStyle(
    fontFamily: _display,
    fontSize: 18,
    height: 0.9,
    letterSpacing: 0.36,
  );

  /// 30px / 0.9 — the brand wordmark in the nav.
  static const subheading = TextStyle(
    fontFamily: _display,
    fontSize: 30,
    height: 0.9,
    letterSpacing: 0.6,
  );

  /// 100px / 0.9 — smallest of the poster sizes.
  static const headingSmall = TextStyle(
    fontFamily: _display,
    fontSize: 100,
    height: 0.9,
    letterSpacing: 2,
  );

  /// 149px / 0.85.
  static const heading = TextStyle(
    fontFamily: _display,
    fontSize: 149,
    height: 0.85,
    letterSpacing: 2.98,
  );

  /// 341px / 0.80 — the hero, fitted to the viewport.
  static const display = TextStyle(
    fontFamily: _display,
    fontSize: 341,
    height: 0.8,
    letterSpacing: 6.82,
  );

  /// Tile numbers. Sized by the caller from the cell size, and tightened as
  /// digits are added so "2048" fits the same square as "2".
  static TextStyle tile(double cellSize, int digits) {
    final scale = switch (digits) {
      <= 1 => 0.46,
      2 => 0.42,
      3 => 0.34,
      4 => 0.27,
      _ => 0.21,
    };
    return TextStyle(
      fontFamily: _display,
      fontSize: cellSize * scale,
      height: 1.0,
      letterSpacing: -cellSize * 0.008,
    );
  }
}

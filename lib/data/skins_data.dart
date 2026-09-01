import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/skin.dart';

/// The ordered skin catalogue.
///
/// Adding a skin means adding an entry here — nothing in `screens/` or
/// `widgets/` knows any of these colours by name.
///
/// A note on the default skin: DESIGN.md asks for at most two accent colours in
/// one composition. A 2048 board is the system's "Color Swatch Card" case
/// instead — the ramp *is* a legend, where each rung has to be told apart from
/// its neighbours at a glance. The ramp therefore climbs through the neutral
/// and yellow tokens first and only reaches for the loud accents at the top of
/// the board, so a typical mid-game screen still reads as two colours.
const List<Skin> kSkins = [
  Skin(
    id: 'classic',
    name: 'Classic',
    tagline: 'THE ORIGINAL TAN',
    stage: Color(0xFFFAF8EF),
    boardSurface: Color(0xFFBBADA0),
    cell: Color(0xFFCDC1B4),
    wall: Color(0xFF8F7A66),
    accent: Color(0xFFF67C5F),
    accentSoft: Color(0xFFEDC22E),
    onStage: Color(0xFF776E65),
    onAccent: Color(0xFFF9F6F2),
    brightness: Brightness.light,
    ramp: [
      TileStyle(Color(0xFFEEE4DA), Color(0xFF776E65)),
      TileStyle(Color(0xFFEDE0C8), Color(0xFF776E65)),
      TileStyle(Color(0xFFF2B179), Color(0xFFF9F6F2)),
      TileStyle(Color(0xFFF59563), Color(0xFFF9F6F2)),
      TileStyle(Color(0xFFF67C5F), Color(0xFFF9F6F2)),
      TileStyle(Color(0xFFF65E3B), Color(0xFFF9F6F2)),
      TileStyle(Color(0xFFEDCF72), Color(0xFFF9F6F2)),
      TileStyle(Color(0xFFEDCC61), Color(0xFFF9F6F2)),
      TileStyle(Color(0xFFEDC850), Color(0xFFF9F6F2)),
      TileStyle(Color(0xFFEDC53F), Color(0xFFF9F6F2)),
      TileStyle(Color(0xFFEDC22E), Color(0xFFF9F6F2)),
      TileStyle(Color(0xFF3C3A32), Color(0xFFF9F6F2)),
      TileStyle(Color(0xFF2E2C26), Color(0xFFF9F6F2)),
    ],
  ),
  Skin(
    id: 'riso',
    name: 'Riso',
    tagline: 'THE HOUSE STYLE',
    stage: AppColors.duskViolet,
    boardSurface: AppColors.lilacShadow,
    cell: Color(0xFF706FA5),
    wall: AppColors.inkBlack,
    accent: AppColors.hiVisYellow,
    accentSoft: AppColors.butteryYellow,
    onStage: AppColors.boneWhite,
    onAccent: AppColors.pureBlack,
    brightness: Brightness.dark,
    ramp: [
      TileStyle(AppColors.boneWhite, AppColors.inkBlack), // 2
      TileStyle(Color(0xFFF7E9C9), AppColors.inkBlack), // 4
      TileStyle(AppColors.butteryYellow, AppColors.inkBlack), // 8
      TileStyle(Color(0xFFF6DD55), AppColors.pureBlack), // 16
      TileStyle(AppColors.hiVisYellow, AppColors.pureBlack), // 32
      TileStyle(AppColors.bubblegumPink, AppColors.inkBlack), // 64
      TileStyle(AppColors.matchaCream, AppColors.inkBlack), // 128
      TileStyle(AppColors.magentaPunch, AppColors.boneWhite), // 256
      TileStyle(AppColors.firecrackerRed, AppColors.boneWhite), // 512
      TileStyle(AppColors.inkBlack, AppColors.hiVisYellow), // 1024
      TileStyle(AppColors.pureBlack, AppColors.hiVisYellow), // 2048
      TileStyle(AppColors.lilacShadow, AppColors.hiVisYellow), // 4096
      TileStyle(AppColors.duskViolet, AppColors.pureBlack), // 8192
    ],
  ),
  Skin(
    id: 'bone',
    name: 'Bone',
    tagline: 'LIGHTS ON',
    unlockAfterStagesCleared: 1,
    stage: AppColors.boneWhite,
    boardSurface: Color(0xFFE6DFD8),
    cell: Color(0xFFEFE9E3),
    wall: AppColors.inkBlack,
    accent: AppColors.magentaPunch,
    accentSoft: AppColors.duskViolet,
    onStage: AppColors.inkBlack,
    onAccent: AppColors.boneWhite,
    brightness: Brightness.light,
    ramp: [
      TileStyle(Color(0xFFFFFFFF), AppColors.inkBlack),
      TileStyle(Color(0xFFF1ECE7), AppColors.inkBlack),
      TileStyle(AppColors.butteryYellow, AppColors.inkBlack),
      TileStyle(AppColors.hiVisYellow, AppColors.pureBlack),
      TileStyle(AppColors.matchaCream, AppColors.inkBlack),
      TileStyle(AppColors.bubblegumPink, AppColors.inkBlack),
      TileStyle(AppColors.magentaPunch, AppColors.boneWhite),
      TileStyle(AppColors.firecrackerRed, AppColors.boneWhite),
      TileStyle(AppColors.duskViolet, AppColors.boneWhite),
      TileStyle(AppColors.lilacShadow, AppColors.boneWhite),
      TileStyle(AppColors.inkBlack, AppColors.hiVisYellow),
      TileStyle(AppColors.pureBlack, AppColors.butteryYellow),
      TileStyle(AppColors.pureBlack, AppColors.bubblegumPink),
    ],
  ),
  Skin(
    id: 'midnight',
    name: 'Midnight',
    tagline: 'NEON AFTER DARK',
    unlockAfterStagesCleared: 5,
    stage: Color(0xFF101018),
    boardSurface: Color(0xFF1B1B28),
    cell: Color(0xFF242434),
    wall: Color(0xFF3A3A52),
    accent: AppColors.hiVisYellow,
    accentSoft: Color(0xFF36F9C1),
    onStage: AppColors.boneWhite,
    onAccent: AppColors.pureBlack,
    brightness: Brightness.dark,
    ramp: [
      TileStyle(Color(0xFF2F2F45), Color(0xFFC9C9E8)),
      TileStyle(Color(0xFF3D3D5C), Color(0xFFE4E4F6)),
      TileStyle(Color(0xFF4F4F80), AppColors.boneWhite),
      TileStyle(Color(0xFF6D5BD0), AppColors.boneWhite),
      TileStyle(Color(0xFF9A4FD0), AppColors.boneWhite),
      TileStyle(Color(0xFFD04F9A), AppColors.boneWhite),
      TileStyle(Color(0xFFF4536B), AppColors.boneWhite),
      TileStyle(Color(0xFFF98B3D), AppColors.inkBlack),
      TileStyle(AppColors.butteryYellow, AppColors.inkBlack),
      TileStyle(AppColors.hiVisYellow, AppColors.pureBlack),
      TileStyle(Color(0xFFB5F936), AppColors.pureBlack),
      TileStyle(Color(0xFF36F9C1), AppColors.pureBlack),
      TileStyle(Color(0xFF36C1F9), AppColors.pureBlack),
    ],
  ),
  Skin(
    id: 'bubblegum',
    name: 'Bubblegum',
    tagline: 'SWEET AND LOUD',
    unlockAfterStagesCleared: 9,
    stage: AppColors.bubblegumPink,
    boardSurface: Color(0xFFE39A92),
    cell: Color(0xFFEDA9A1),
    wall: AppColors.inkBlack,
    accent: AppColors.magentaPunch,
    accentSoft: AppColors.butteryYellow,
    onStage: AppColors.inkBlack,
    onAccent: AppColors.boneWhite,
    brightness: Brightness.light,
    ramp: [
      TileStyle(Color(0xFFFFF3F1), AppColors.inkBlack),
      TileStyle(Color(0xFFFFE0DC), AppColors.inkBlack),
      TileStyle(AppColors.butteryYellow, AppColors.inkBlack),
      TileStyle(Color(0xFFF4A6B8), AppColors.inkBlack),
      TileStyle(Color(0xFFEF7FA3), AppColors.boneWhite),
      TileStyle(Color(0xFFE05A92), AppColors.boneWhite),
      TileStyle(AppColors.magentaPunch, AppColors.boneWhite),
      TileStyle(Color(0xFF8E3F97), AppColors.boneWhite),
      TileStyle(Color(0xFF6B3A8F), AppColors.boneWhite),
      TileStyle(AppColors.firecrackerRed, AppColors.boneWhite),
      TileStyle(AppColors.inkBlack, AppColors.bubblegumPink),
      TileStyle(AppColors.pureBlack, AppColors.hiVisYellow),
      TileStyle(AppColors.pureBlack, AppColors.matchaCream),
    ],
  ),
  Skin(
    id: 'matcha',
    name: 'Matcha',
    tagline: 'DUSTY SAGE STACK',
    unlockAfterStagesCleared: 14,
    stage: AppColors.matchaCream,
    boardSurface: Color(0xFF93A877),
    cell: Color(0xFFA3B885),
    wall: Color(0xFF375027),
    accent: Color(0xFF375027),
    accentSoft: AppColors.butteryYellow,
    onStage: Color(0xFF1F2B16),
    onAccent: AppColors.boneWhite,
    brightness: Brightness.light,
    ramp: [
      TileStyle(Color(0xFFF4F7EC), Color(0xFF1F2B16)),
      TileStyle(Color(0xFFE3EBD2), Color(0xFF1F2B16)),
      TileStyle(Color(0xFFCBDCAE), Color(0xFF1F2B16)),
      TileStyle(Color(0xFFA8C47F), Color(0xFF1F2B16)),
      TileStyle(Color(0xFF86AB5C), AppColors.boneWhite),
      TileStyle(Color(0xFF648F3F), AppColors.boneWhite),
      TileStyle(Color(0xFF4A742C), AppColors.boneWhite),
      TileStyle(Color(0xFF375027), AppColors.boneWhite),
      TileStyle(AppColors.butteryYellow, Color(0xFF1F2B16)),
      TileStyle(AppColors.hiVisYellow, AppColors.pureBlack),
      TileStyle(AppColors.firecrackerRed, AppColors.boneWhite),
      TileStyle(AppColors.inkBlack, AppColors.matchaCream),
      TileStyle(AppColors.pureBlack, AppColors.hiVisYellow),
    ],
  ),
];

/// The skin used before the player has chosen one.
const String kDefaultSkinId = 'classic';

Skin skinById(String id) =>
    kSkins.firstWhere((s) => s.id == id, orElse: () => kSkins.first);

/// Whether [skin] is available given how many stages the player has cleared.
bool isSkinUnlocked(Skin skin, int stagesCleared) =>
    stagesCleared >= skin.unlockAfterStagesCleared;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'core/skin.dart';
import 'screens/home_screen.dart';
import 'state/providers.dart';

/// The app shell. The whole theme follows the selected skin, so switching skins
/// repaints every screen at once rather than only the board.
class Game2048App extends ConsumerWidget {
  const Game2048App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skin = ref.watch(skinProvider);

    // Match the system bars to the stage; nothing else in the system has chrome.
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: skin.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: skin.stage,
        systemNavigationBarIconBrightness: skin.brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: '2048 Stages',
      debugShowCheckedModeBanner: false,
      theme: _themeFor(skin),
      home: const HomeScreen(),
    );
  }

  ThemeData _themeFor(Skin skin) {
    return ThemeData(
      useMaterial3: true,
      brightness: skin.brightness,
      scaffoldBackgroundColor: skin.stage,
      canvasColor: skin.stage,
      fontFamily: AppFonts.display,
      colorScheme: ColorScheme.fromSeed(
        seedColor: skin.accent,
        brightness: skin.brightness,
      ).copyWith(surface: skin.stage),
      // The system is flat riso: no elevation anywhere, ever.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: skin.boardSurface,
          borderRadius: AppRadius.cardRadius,
        ),
        textStyle: AppType.monoLabel.copyWith(color: skin.onStage),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/persistence.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The board is square and the layout is built for it; a rotating phone would
  // only ever make the grid smaller.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Progress and settings are read once, before the first frame, so no screen
  // ever has to render an "unknown" state.
  final persistence = await Persistence.open();

  runApp(
    ProviderScope(
      overrides: [persistenceProvider.overrideWithValue(persistence)],
      child: const Game2048App(),
    ),
  );
}

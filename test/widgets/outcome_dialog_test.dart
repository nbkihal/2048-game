import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_2048/data/skins_data.dart';
import 'package:game_2048/data/stages_data.dart';
import 'package:game_2048/widgets/outcome_dialog.dart';

/// The end-of-attempt panel has to state the outcome with a glyph before any
/// text is read, and it has to fit a small phone without overflowing.
void main() {
  Widget host({required bool won, bool lostToMoveLimit = false}) {
    return MaterialApp(
      home: OutcomeDialog(
        skin: kSkins.first,
        won: won,
        stage: kStages.first,
        score: 1240,
        best: 980,
        isNewBest: true,
        nextStage: won ? kStages[1] : null,
        unlockedSkinNames: const [],
        canKeepGoing: won,
        lostToMoveLimit: lostToMoveLimit,
        onAction: (_) {},
      ),
    );
  }

  testWidgets('a stuck board shows the dead-face mark', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(won: false));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.sentiment_very_dissatisfied_rounded), findsOne);
    expect(find.text('NO MOVES LEFT'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a spent move budget shows the stopped clock instead', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(won: false, lostToMoveLimit: true));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.timer_off_rounded), findsOne);
    expect(find.text('OUT OF MOVES'), findsOne);
  });

  testWidgets('a clear shows the trophy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(won: true));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.emoji_events_rounded), findsOne);
    expect(tester.takeException(), isNull);
  });
}

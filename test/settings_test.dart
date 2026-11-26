import 'package:coartada/core/app_state.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/screens/game_screen.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:coartada/widgets/board_view.dart';
import 'package:coartada/widgets/suspect_avatar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _state([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return AppState(await SharedPreferences.getInstance());
}

/// Opens a 4×4 case and records every vibration request.
Future<(Puzzle, List<String>)> _open(WidgetTester tester, AppState app) async {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final vibrations = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        vibrations.add(call.arguments as String);
      }
      return null;
    },
  );
  final p = generatePuzzle(level: Level.apprentice, seed: 3);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: GameScreen(appState: app, puzzle: p),
    ),
  );
  return (p, vibrations);
}

/// Puts persons 0 and 1 on the same row, so they clash.
Future<void> _clash(WidgetTester tester, Puzzle p) async {
  final b = p.board;
  final row = [
    for (var c = 0; c < b.size; c++)
      if (b.standable(c)) c,
  ];
  final squares = find.descendant(
    of: find.byType(BoardView),
    matching: find.byType(InkWell),
  );
  await tester.tap(find.text(p.name(0)).first);
  await tester.pump();
  await tester.tap(squares.at(row[0]));
  await tester.pump(); // selection moves on to person 1
  await tester.tap(squares.at(row[1]));
  await tester.pumpAndSettle();
}

Iterable<SuspectAvatar> _boardAvatars(WidgetTester tester) =>
    tester.widgetList<SuspectAvatar>(
      find.descendant(
        of: find.byType(BoardView),
        matching: find.byType(SuspectAvatar),
      ),
    );

void main() {
  test('settings default on and persist', () async {
    final app = await _state();
    expect(app.haptics, isTrue);
    expect(app.visualHelp, isTrue);
    app
      ..haptics = false
      ..visualHelp = false;
    final again = AppState(await SharedPreferences.getInstance());
    expect(again.haptics, isFalse);
    expect(again.visualHelp, isFalse);
  });

  testWidgets('visual help rings clashing people; off hides it', (
    tester,
  ) async {
    final app = await _state();
    final (p, _) = await _open(tester, app);
    await _clash(tester, p);
    final error = AppTheme.light().colorScheme.error;
    expect(_boardAvatars(tester).where((a) => a.ring == error), hasLength(2));

    app.visualHelp = false;
    await tester.pumpAndSettle();
    expect(_boardAvatars(tester).where((a) => a.ring == error), isEmpty);
  });

  testWidgets(
    'hints vibrate; with vibration off, a wrong accusation doesn\'t',
    (tester) async {
      final app = await _state();
      final (p, vibrations) = await _open(tester, app);
      await _clash(tester, p);
      await tester.tap(find.text('Comprobar'));
      await tester.pump();
      expect(vibrations, isEmpty); // incomplete: no vibration

      // Undo the clash (a misplaced person gets a "mistake" hint first),
      // then hints place everyone.
      await tester.tap(find.text('Deshacer'));
      await tester.pump();
      await tester.tap(find.text('Deshacer'));
      await tester.pump();
      for (var i = 0; i < 2 * p.people; i++) {
        await tester.tap(find.text('Pista').last);
        await tester.pump();
      }
      expect(vibrations, isNotEmpty); // hint clicks
      vibrations.clear();

      app.haptics = false;
      await tester.pump();
      await tester.tap(find.text('Comprobar'));
      await tester.pumpAndSettle();
      final innocent = List.generate(
        p.people,
        (i) => i,
      ).firstWhere((i) => i != p.culprit && i != p.victim);
      await tester.tap(find.widgetWithText(ListTile, p.name(innocent)));
      await tester.pumpAndSettle();
      expect(vibrations, isEmpty);
    },
  );
}

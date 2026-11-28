import 'package:coartada/core/app_state.dart';
import 'package:coartada/game/game_controller.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/main.dart';
import 'package:coartada/screens/game_screen.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _state() async {
  SharedPreferences.setMockInitialValues({'tutorial_card_hidden': true});
  return AppState(await SharedPreferences.getInstance());
}

void main() {
  group('GameController', () {
    late Puzzle p;
    setUp(() => p = generatePuzzle(level: Level.apprentice, seed: 3));

    test('places, moves and removes people; undo restores', () {
      final g = GameController(p);
      final free = [
        for (var c = 0; c < p.board.cellCount; c++)
          if (p.board.standable(c)) c,
      ];
      g.select(0);
      expect(g.tap(free[0]), TapResult.ok);
      expect(g.placement[0], free[0]);
      g.select(0);
      g.tap(free[1]);
      expect(g.placement[0], free[1]);
      g.undo();
      expect(g.placement[0], free[0]);
    });

    test('blocked furniture refuses people', () {
      final g = GameController(p);
      final blocked = p.board.furniture.indexWhere((f) => f.blocks);
      g.select(1);
      expect(g.tap(blocked), TapResult.blocked);
      expect(g.placement[1], isNull);
    });

    test('tapping an empty square with nobody selected crosses it', () {
      final g = GameController(p);
      final free = p.board.furniture.indexWhere((f) => !f.blocks);
      g.tap(free);
      expect(g.crosses, contains(free));
      g.tap(free);
      expect(g.crosses, isNot(contains(free)));
    });

    test('hints solve the case, then only the culprit closes it', () {
      final g = GameController(p);
      expect(g.check(), CheckResult.incomplete);
      while (g.hint() != null) {}
      expect(g.check(), CheckResult.correct);
      expect(g.phase, Phase.accusing);
      final innocent = List.generate(
        p.people,
        (i) => i,
      ).firstWhere((i) => i != p.culprit && i != p.victim);
      expect(g.accuse(innocent), isFalse);
      expect(g.accuse(p.culprit), isTrue);
      expect(g.phase, Phase.solved);
    });

    test('conflicts flag people sharing a row', () {
      final g = GameController(p);
      final b = p.board;
      final row0 = [
        for (var c = 0; c < b.size; c++)
          if (b.standable(c)) c,
      ];
      g.select(0);
      g.tap(row0[0]);
      expect(g.selected, 1); // selection moves on to the next person
      g.tap(row0[1]);
      expect(g.conflicts, {0, 1});
    });
  });

  testWidgets('home lists the daily case and the four levels', (tester) async {
    final app = await _state();
    await tester.pumpWidget(CoartadaApp(appState: app));
    expect(find.text('Coartada'), findsOneWidget);
    expect(find.text('Caso del día'), findsOneWidget);
    for (final name in ['Aprendiz', 'Detective', 'Inspector', 'Comisario']) {
      expect(find.text(name), findsWidgets);
    }
  });

  testWidgets('a full game: hints, check, accuse, case closed', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = await _state();
    final p = generatePuzzle(level: Level.apprentice, seed: 11);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GameScreen(appState: app, puzzle: p),
      ),
    );
    expect(tester.takeException(), isNull);
    // Each person: the hint explains, asking again places them.
    for (var i = 0; i < 2 * p.people; i++) {
      await tester.tap(find.text('Pista').last);
      await tester.pump();
    }
    await tester.tap(find.text('Comprobar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Quién fue?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ListTile, p.name(p.culprit)));
    await tester.pumpAndSettle();
    // The reveal plays before the dialog.
    expect(find.text('¡Caso cerrado!'), findsNothing);
    await tester.pump(Motion.reveal + Motion.revealHold);
    await tester.pumpAndSettle();
    expect(find.text('¡Caso cerrado!'), findsOneWidget);
    expect(app.stats(Level.apprentice, Variant.classic).solved, 1);
  });

  testWidgets('7x7 board and dark theme lay out on a small phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375 * 3, 667 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = await _state();
    app.themeMode = ThemeMode.dark;
    app.language = 'ca';
    final p = generatePuzzle(
      level: Level.commissioner,
      seed: 5,
      variant: Variant.noTouch,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        home: GameScreen(appState: app, puzzle: p),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Comprovar'), findsOneWidget);
  });
}

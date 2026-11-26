import 'package:coartada/core/app_state.dart';
import 'package:coartada/game/game_controller.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/screens/game_screen.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:coartada/widgets/board_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// With reduced motion, every animation shows its final state at once.
void main() {
  Future<Puzzle> open(WidgetTester tester, {required bool reduce}) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    final p = generatePuzzle(level: Level.apprentice, seed: 11);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(375, 812),
          disableAnimations: reduce,
        ),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: GameScreen(appState: app, puzzle: p),
        ),
      ),
    );
    return p;
  }

  testWidgets('a hint places someone fully visible in one frame', (
    tester,
  ) async {
    await open(tester, reduce: true);
    await tester.tap(find.text('Pista').last);
    await tester.pump();
    // (The tap ripple still runs; the drop itself must already be done.)
    final opacities = tester.widgetList<Opacity>(
      find.descendant(
        of: find.byType(BoardView),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacities, isNotEmpty);
    expect(opacities.every((o) => o.opacity == 1), isTrue);
  });

  testWidgets('with motion, the drop animates', (tester) async {
    await open(tester, reduce: false);
    await tester.tap(find.text('Pista').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final opacities = tester.widgetList<Opacity>(
      find.descendant(
        of: find.byType(BoardView),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacities.any((o) => o.opacity < 1), isTrue); // mid-drop
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion: case-closed dialog without waiting', (
    tester,
  ) async {
    final p = await open(tester, reduce: true);
    for (var i = 0; i < p.people; i++) {
      await tester.tap(find.text('Pista').last);
      await tester.pump();
    }
    await tester.tap(find.text('Comprobar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, p.name(p.culprit)));
    await tester.pump(); // zero-length reveal delay
    await tester.pumpAndSettle();
    expect(find.text('¡Caso cerrado!'), findsOneWidget);
  });

  /// A complete but wrong board: two people swapped.
  Future<void> openWrong(WidgetTester tester, {required bool reduce}) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    final g = GameController(generatePuzzle(level: Level.apprentice, seed: 11));
    final sol = g.puzzle.solution;
    for (var i = 0; i < sol.length; i++) {
      g.placement[i] = sol[i];
    }
    g.placement[0] = sol[1];
    g.placement[1] = sol[0];
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(375, 812),
          disableAnimations: reduce,
        ),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: GameScreen.resume(appState: app, controller: g),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Offset boardAt(WidgetTester tester) =>
      tester.getTopLeft(find.byType(BoardView));

  testWidgets('a wrong check shakes the board, then it settles', (
    tester,
  ) async {
    await openWrong(tester, reduce: false);
    final rest = boardAt(tester);
    await tester.tap(find.text('Comprobar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(boardAt(tester), isNot(rest));
    await tester.pumpAndSettle();
    expect(boardAt(tester), rest);
  });

  testWidgets('reduced motion: a wrong check does not shake', (tester) async {
    await openWrong(tester, reduce: true);
    final rest = boardAt(tester);
    await tester.tap(find.text('Comprobar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(boardAt(tester), rest);
    expect(find.text('Algo no cuadra: revisa las pistas.'), findsOneWidget);
  });
}

import 'package:coartada/game/deducer.dart';
import 'package:coartada/game/solver.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/game/tutorial.dart';
import 'package:coartada/screens/game_screen.dart';
import 'package:coartada/widgets/board_view.dart';
import 'package:coartada/core/app_state.dart';
import 'package:coartada/main.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the tutorial case is sound and unique', () {
    final p = tutorialPuzzle();
    expect(p.clues.every((c) => c.holds(p.board, p.solution)), isTrue);
    expect(countSolutions(p.board, p.people, p.victim, p.clues), 1);
    expect(culpritOf(p.board, p.victim, p.solution), p.culprit);
  });

  test('it unfolds in the four planned steps', () {
    final p = tutorialPuzzle();
    final known = <int, int>{};
    final order = <int>[];
    final reasons = <Set<Reason>>[];
    while (known.length < p.people) {
      final d = Deducer(p, known: known).next()!;
      expect(d.cell, p.solution[d.person]);
      known[d.person] = d.cell;
      order.add(d.person);
      reasons.add(d.reasons);
    }
    expect(order, [1, 3, 0, 2]); // Bruno, Darío, Abril, Carmen
    expect(reasons[0], {Reason.clues});
    expect(reasons[1], {Reason.clues});
    expect(reasons[2], containsAll([Reason.clues, Reason.occupied]));
    expect(reasons[3], {Reason.occupied});
  });

  testWidgets('home offers the guided case; "Not now" hides it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    await tester.pumpWidget(PesquisaApp(appState: app));
    expect(find.text('¿Primera vez?'), findsOneWidget);
    await tester.tap(find.byTooltip('Ahora no'));
    await tester.pump();
    expect(find.text('¿Primera vez?'), findsNothing);
    expect(app.showTutorialCard, isFalse);
  });

  testWidgets('the coach walks through the case to the end', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    final p = tutorialPuzzle();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameScreen.tutorial(appState: app),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Caso guiado'), findsOneWidget); // not "Caso nº 0"
    // Two intro pages, with Back on the second.
    expect(find.textContaining('Tu primer caso'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Atrás'), findsOneWidget);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();

    // Follow each instruction: pick the person, tap the square.
    final squares = find.descendant(
      of: find.byType(BoardView),
      matching: find.byType(InkWell),
    );
    for (final person in [1, 3, 0, 2]) {
      final cell = p.solution[person];
      final at = '${String.fromCharCode(65 + cell % 4)}${cell ~/ 4 + 1}';
      expect(
        find.textContaining('${p.name(person)} solo puede estar en $at'),
        findsOneWidget,
      );
      expect(find.textContaining('toca $at'), findsOneWidget);
      await tester.tap(squares.at(cell)); // the coach pre-selected them
      await tester.pumpAndSettle();
    }
    expect(find.text('¡Todos en su sitio! Pulsa Comprobar.'), findsOneWidget);

    await tester.tap(find.text('Comprobar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, p.name(p.culprit)));
    await tester.pumpAndSettle();
    await tester.pump(Motion.reveal + Motion.revealHold);
    await tester.pumpAndSettle();
    expect(find.text('¡Ya sabes investigar!'), findsOneWidget);
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget); // back where it started
    expect(app.tutorialDone, isTrue);
    expect(app.savedGame, isNull); // never saved
    expect(app.stats(Level.apprentice, Variant.classic).solved, 0);
  });
}

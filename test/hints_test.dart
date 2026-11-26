import 'package:coartada/core/app_state.dart';
import 'package:coartada/game/deducer.dart';
import 'package:coartada/game/game_controller.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/screens/game_screen.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final variant in Variant.values) {
    for (final level in Level.values) {
      test('${level.name} ${variant.name}: every case can be reasoned out', () {
        for (var seed = 100; seed < 112; seed++) {
          final p = generatePuzzle(level: level, seed: seed, variant: variant);
          final (solved, steps) = Deducer.solvesAll(p);
          expect(solved, isTrue, reason: 'seed $seed');
          expect(steps, p.people);
        }
      });
    }
  }

  group('hint', () {
    late Puzzle p;
    setUp(() => p = generatePuzzle(level: Level.inspector, seed: 8));

    test('points at a misplaced person first, without moving anyone', () {
      final g = GameController(p);
      final wrong = p.solution[1]; // person 0 on person 1's square
      g.placement[0] = wrong;
      final h = g.hint();
      expect(h, isA<MistakeHint>());
      expect((h! as MistakeHint).cell, wrong);
      expect(g.placement[0], wrong);
      expect(g.hints, 1);
      // Moving that person away hides it.
      g.placement[0] = null;
      expect(g.activeHint, isNull);
    });

    test('explains a deduction, then places it on the second ask', () {
      final g = GameController(p);
      final h = g.hint();
      expect(h, isA<DeductionHint>());
      final d = (h! as DeductionHint).deduction;
      expect(d.cell, p.solution[d.person]);
      expect(g.placement[d.person], isNull); // nothing placed yet
      final again = g.hint();
      expect(again, isA<RevealHint>());
      expect(g.placement[d.person], d.cell);
      expect(g.locked, contains(d.person));
      expect(g.hints, 1); // the reveal of a shown deduction is free
    });

    test('following the deduction yourself clears it', () {
      final g = GameController(p);
      final d = (g.hint()! as DeductionHint).deduction;
      g.select(d.person);
      g.tap(d.cell);
      expect(g.activeHint, isNull);
      expect(g.hint(), isA<DeductionHint>()); // and the next one comes
    });
  });

  testWidgets('the hint card explains and highlights', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    final p = generatePuzzle(level: Level.inspector, seed: 8);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GameScreen(appState: app, puzzle: p),
      ),
    );
    await tester.tap(find.text('Pista').last);
    await tester.pump();
    expect(find.textContaining('solo puede estar en'), findsOneWidget);
    expect(find.textContaining('Pide otra ayuda'), findsOneWidget);
  });
}

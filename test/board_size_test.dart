import 'package:coartada/core/app_state.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/screens/game_screen.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:coartada/widgets/board_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Board squares are touch targets: at least 48dp (Android guidance; iOS
/// asks 44pt) on a 375px-wide phone, for every level.
void main() {
  for (final level in Level.values) {
    testWidgets('${level.name} squares are ≥ 48dp at 375px wide', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375 * 3, 812 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final app = AppState(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: GameScreen(
            appState: app,
            puzzle: generatePuzzle(level: level, seed: 1),
          ),
        ),
      );
      final squares = _squares();
      expect(squares, findsNWidgets(level.size * level.size));
      final size = tester.getSize(squares.first);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('8×8 on a phone: pan or toggle to see the whole board', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    final p = generatePuzzle(level: Level.legend, seed: 2);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GameScreen(appState: app, puzzle: p),
      ),
    );
    expect(find.text('Ver todo'), findsOneWidget);
    await tester.tap(find.text('Ver todo'));
    await tester.pump();
    expect(find.text('Acercar'), findsOneWidget);

    // Squares still take taps at the whole-board scale.
    // (Nobody selected: a tap crosses the square out.)
    final free = p.board.furniture.indexWhere((f) => !f.blocks);
    await tester.tap(_squares().at(free));
    await tester.pump();
    expect(
      find.descendant(
        of: _squares().at(free),
        matching: find.byIcon(Icons.close),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Acercar'));
    await tester.pump();
    expect(find.text('Ver todo'), findsOneWidget);
  });
}

/// The board's squares (the zoom button's InkWell isn't one).
Finder _squares() => find.descendant(
  of: find.byType(BoardView),
  matching: find.byWidgetPredicate(
    (w) => w is InkWell && w.customBorder == null && w.borderRadius == null,
  ),
);

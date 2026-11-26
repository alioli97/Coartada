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
      final squares = find.descendant(
        of: find.byType(BoardView),
        matching: find.byType(InkWell),
      );
      expect(squares, findsNWidgets(level.size * level.size));
      final size = tester.getSize(squares.first);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
    });
  }
}

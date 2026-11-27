import 'package:coartada/core/app_state.dart';
import 'package:coartada/core/strings.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/screens/archive_screen.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _state([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return AppState(await SharedPreferences.getInstance());
}

void main() {
  test('the last 30 days cross month boundaries', () {
    final days = AppState.recentDays(DateTime(2026, 3, 2));
    expect(days, hasLength(30));
    expect(days.first, 20260302);
    expect(days[1], 20260301);
    expect(days[2], 20260228);
    expect(AppState.dayOf(20260228), DateTime(2026, 2, 28));
  });

  test('every solved day is remembered; old single-day data too', () async {
    final app = await _state({'daily_solved': 20261120});
    expect(app.dailyDone(20261120), isTrue);
    for (final day in [20261118, 20261125]) {
      app.recordSolved(
        generatePuzzle(level: Level.inspector, seed: day),
        const Duration(seconds: 90),
        daily: true,
        now: DateTime(2026, 11, 27),
      );
    }
    expect(app.dailyDone(20261118), isTrue);
    expect(app.dailyDone(20261125), isTrue);
    expect(app.dailyDone(20261120), isFalse); // overwritten single value...
    expect(app.dailyDone(20261119), isFalse);
    // ...past days count in stats, not in the streak.
    expect(app.stats(Level.inspector, Variant.classic).solved, 2);
    expect(app.streak(DateTime(2026, 11, 27)).current, 0);
  });

  test('dates read naturally in each language', () {
    final apr = DateTime(2026, 4, 9); // a Thursday
    expect(const Strings('es').longDate(apr), 'jueves, 9 de abril');
    expect(const Strings('ca').longDate(apr), "dijous, 9 d'abril");
    expect(const Strings('en').longDate(apr), 'Thursday, 9 April');
    final nov = DateTime(2026, 11, 26);
    expect(const Strings('ca').shortDate(nov), '26 nov.');
    expect(const Strings('en').shortDate(nov), '26 Nov');
  });

  testWidgets('archive lists 30 days and opens a past case', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = await _state();
    final today = DateTime(2026, 11, 27);
    app.recordSolved(
      generatePuzzle(level: Level.inspector, seed: 20261126),
      const Duration(seconds: 90),
      daily: true,
      now: today,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: ArchiveScreen(appState: app, now: () => today),
      ),
    );
    expect(find.text('Hoy'), findsOneWidget);
    expect(find.text('Ayer'), findsOneWidget);
    expect(
      find.textContaining('Jueves, 26 de noviembre · Resuelto'),
      findsOneWidget,
    );
    expect(find.text('Miércoles, 25 de noviembre'), findsOneWidget);

    await tester.tap(find.text('Miércoles, 25 de noviembre'));
    await tester.pumpAndSettle();
    expect(find.text('Caso del día'), findsOneWidget);
    expect(find.text('25 nov. · Inspector · 6×6'), findsOneWidget);
  });
}

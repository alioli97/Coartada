import 'dart:convert';

import 'package:coartada/core/app_state.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/main.dart';
import 'package:coartada/screens/stats_screen.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _state([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return AppState(await SharedPreferences.getInstance());
}

/// Solves the daily case of [day] on that day.
void _solveDaily(AppState app, DateTime day, {int hints = 0}) {
  final p = generatePuzzle(
    level: Level.inspector,
    seed: AppState.dailySeed(day),
  );
  app.recordSolved(
    p,
    const Duration(seconds: 100),
    daily: true,
    hints: hints,
    now: day,
  );
}

void main() {
  group('streak', () {
    test('grows day by day, across months and years', () async {
      final app = await _state();
      for (final d in [
        DateTime(2026, 12, 30),
        DateTime(2026, 12, 31),
        DateTime(2027, 1, 1),
      ]) {
        _solveDaily(app, d);
      }
      final s = app.streak(DateTime(2027, 1, 1));
      expect(s.current, 3);
      expect(s.best, 3);
      expect(s.solvedToday, isTrue);
      // Still alive the next day, before solving it.
      expect(app.streak(DateTime(2027, 1, 2)).current, 3);
      expect(app.streak(DateTime(2027, 1, 2)).solvedToday, isFalse);
    });

    test('solving twice the same day counts once', () async {
      final app = await _state();
      _solveDaily(app, DateTime(2026, 11, 30));
      _solveDaily(app, DateTime(2026, 11, 30));
      expect(app.streak(DateTime(2026, 11, 30)).current, 1);
    });

    test('a missed day breaks it; the best is kept', () async {
      final app = await _state();
      _solveDaily(app, DateTime(2026, 11, 28));
      _solveDaily(app, DateTime(2026, 11, 29));
      expect(app.streak(DateTime(2026, 12, 1)).current, 0);
      _solveDaily(app, DateTime(2026, 12, 1));
      final s = app.streak(DateTime(2026, 12, 1));
      expect(s.current, 1);
      expect(s.best, 2);
    });

    test("an old daily solved later doesn't count", () async {
      final app = await _state();
      final p = generatePuzzle(level: Level.inspector, seed: 20261120);
      app.recordSolved(
        p,
        const Duration(seconds: 50),
        daily: true,
        now: DateTime(2026, 11, 27),
      );
      expect(app.streak(DateTime(2026, 11, 27)).current, 0);
    });
  });

  test('per-level averages, hints and older stats', () async {
    final app = await _state({
      // Stats saved before totals were tracked.
      'stats': jsonEncode({
        'apprentice_classic': {'solved': 2, 'best': 40},
      }),
    });
    expect(app.stats(Level.apprentice, Variant.classic).solved, 2);
    // Unknown times/hints for those: no made-up average.
    expect(app.stats(Level.apprentice, Variant.classic).average, isNull);
    expect(app.stats(Level.apprentice, Variant.classic).hintsPerCase, isNull);
    final p = generatePuzzle(level: Level.detective, seed: 1);
    app.recordSolved(p, const Duration(seconds: 60), daily: false, hints: 2);
    app.recordSolved(p, const Duration(seconds: 120), daily: false);
    final st = app.stats(Level.detective, Variant.classic);
    expect(st.average, const Duration(seconds: 90));
    expect(st.totalHints, 2);
    expect(st.noHints, 1);
    expect(st.bestSeconds, 60);
  });

  testWidgets('stats screen and the streak on the daily card', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = await _state();
    final today = DateTime(2026, 11, 27);
    _solveDaily(app, DateTime(2026, 11, 26), hints: 1);
    _solveDaily(app, today);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StatsScreen(appState: app, now: () => today),
      ),
    );
    expect(find.text('Racha actual · 2 días'), findsOneWidget);
    expect(find.text('Caso de hoy resuelto'), findsOneWidget);
    expect(find.text('Inspector · 6×6'), findsOneWidget);
    expect(
      find.text('Ayudas/caso 0,5', findRichText: true),
      findsOneWidget,
    ); // hints per case, with a decimal comma

    await tester.tap(find.text('Sin roces'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aún no has resuelto ningún caso en este modo.'),
      findsOneWidget,
    );

    await tester.pumpWidget(PesquisaApp(appState: app));
    await tester.pumpAndSettle();
    // The real clock isn't 2026-11-27 here, so the streak may show 0:
    // only check the stats button is reachable from home.
    expect(find.byTooltip('Estadísticas'), findsOneWidget);
  });
}

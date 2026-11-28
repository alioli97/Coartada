import 'dart:async';

import 'package:coartada/core/app_state.dart';
import 'package:coartada/core/result_share.dart';
import 'package:coartada/core/strings.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/screens/game_screen.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('daily result: date, level, time, hints; no spoilers', () {
    final p = generatePuzzle(level: Level.inspector, seed: 20261128);
    final text = resultShareText(
      const Strings('es'),
      p,
      daily: true,
      elapsed: const Duration(minutes: 4, seconds: 12),
      hints: 1,
    );
    expect(
      text,
      'Pesquisa — Caso del día, 28 nov.\n'
      'Inspector 6×6 · 4:12 · 1 ayuda\n'
      '¿Sabrías decir quién fue?\n'
      'alioli97.github.io/Pesquisa',
    );
    for (var i = 0; i < p.people; i++) {
      expect(text, isNot(contains(p.name(i))));
    }
  });

  test('numbered case, no-touch, plural hints, other languages', () {
    final p = generatePuzzle(
      level: Level.detective,
      seed: 4321,
      variant: Variant.noTouch,
    );
    String text(String lang, int hints) => resultShareText(
      Strings(lang),
      p,
      daily: false,
      elapsed: const Duration(seconds: 75),
      hints: hints,
    );
    expect(text('es', 0), contains('Caso nº 4321'));
    expect(
      text('es', 0),
      contains('Detective 5×5 · Sin roces · 1:15 · 0 ayudas'),
    );
    expect(text('ca', 2), contains('2 ajudes'));
    expect(text('en', 1), contains('Case #4321'));
    expect(text('en', 1), contains('1 hint'));
  });

  testWidgets('the case-closed dialog shares once per tap', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    final p = generatePuzzle(level: Level.apprentice, seed: 11);
    final sent = <String>[];
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GameScreen(
          appState: app,
          puzzle: p,
          share: (text) {
            sent.add(text);
            return pending.future;
          },
        ),
      ),
    );
    for (var i = 0; i < 2 * p.people; i++) {
      await tester.tap(find.text('Pista').last);
      await tester.pump();
    }
    await tester.tap(find.text('Comprobar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, p.name(p.culprit)));
    await tester.pumpAndSettle();
    await tester.pump(Motion.reveal + Motion.revealHold);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Compartir'));
    await tester.pump();
    await tester.tap(find.text('Compartir')); // still open: ignored
    await tester.pump();
    expect(sent, hasLength(1));
    expect(sent.single, startsWith('Pesquisa — Caso nº 11'));

    pending.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compartir'));
    await tester.pump();
    expect(sent, hasLength(2));
  });
}

import 'dart:convert';

import 'package:coartada/core/app_state.dart';
import 'package:coartada/game/game_controller.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _state([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return AppState(await SharedPreferences.getInstance());
}

/// A game with people placed, one cross, one struck clue and one hint.
GameController _played() {
  final p = generatePuzzle(
    level: Level.detective,
    seed: 21,
    variant: Variant.noTouch,
  );
  final g = GameController(
    p,
    daily: true,
    elapsed: const Duration(seconds: 90),
  );
  final free = [
    for (var c = 0; c < p.board.cellCount; c++)
      if (p.board.standable(c)) c,
  ];
  g.select(0);
  g.tap(free.first);
  g.select(null);
  g.tap(free.last); // cross
  g.toggleClue(0);
  g.hint();
  return g;
}

void main() {
  test('a game survives a JSON round trip', () {
    final g = _played();
    final copy = GameController.fromJson(
      jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>,
    )!;
    expect(copy.puzzle.seed, g.puzzle.seed);
    expect(copy.puzzle.level, Level.detective);
    expect(copy.board.variant, Variant.noTouch);
    expect(copy.puzzle.solution, g.puzzle.solution);
    expect(copy.daily, isTrue);
    expect(copy.placement, g.placement);
    expect(copy.crosses, g.crosses);
    expect(copy.doneClues, g.doneClues);
    expect(copy.locked, g.locked);
    expect(copy.hints, 1);
    expect(copy.elapsed, greaterThanOrEqualTo(const Duration(seconds: 90)));
  });

  test('bad or foreign save data is rejected, not crashed on', () {
    final json = _played().toJson();
    expect(GameController.fromJson({...json, 'v': 99}), isNull);
    // Saves from the previous generator would rebuild another case.
    expect(GameController.fromJson({...json, 'v': 1}), isNull);
    expect(
      GameController.fromJson({
        ...json,
        'placement': [1, 2],
      }),
      isNull,
    );
    expect(GameController.fromJson({...json, 'level': 'nope'}), isNull);
    expect(GameController.fromJson({'v': 1}), isNull);
  });

  test('the clock pauses and resumes', () async {
    final g = _played()..pauseClock();
    final at = g.elapsed;
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(g.elapsed, at);
    g.resumeClock();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(g.elapsed, greaterThan(at));
  });

  test('AppState stores one saved game and summarises it', () async {
    final app = await _state();
    expect(app.savedGame, isNull);
    final g = _played();
    app.saveGame(g.toJson());
    final info = app.savedGame!;
    expect(info.level, Level.detective);
    expect(info.daily, isTrue);
    expect(info.placed, g.placedCount);
    expect(info.people, 5);
    app.clearSavedGame();
    expect(app.savedGame, isNull);
  });

  testWidgets('moves are saved; Continue restores them', (tester) async {
    final app = await _state();
    await tester.pumpWidget(CoartadaApp(appState: app));
    expect(find.text('Continuar caso'), findsNothing);

    // Open a new 4×4 case, place someone with a hint, go back.
    await tester.tap(find.text('Aprendiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pista').last); // explains
    await tester.pump();
    await tester.tap(find.text('Pista').last); // places
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Continuar caso'), findsOneWidget);
    expect(find.textContaining('1 de 4 colocados'), findsWidgets);

    await tester.tap(find.text('Continuar caso'));
    await tester.pumpAndSettle();
    final saved = app.savedGameJson!;
    expect((saved['placement'] as List).whereType<int>().length, 1);
    expect(saved['locked'], hasLength(1)); // the hinted person
    expect(find.text('Comprobar'), findsOneWidget); // on the game screen
  });

  testWidgets('opening a case without moving keeps the old save', (
    tester,
  ) async {
    final app = await _state({'saved_game': jsonEncode(_played().toJson())});
    await tester.pumpWidget(CoartadaApp(appState: app));
    await tester.tap(find.text('Aprendiz'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(app.savedGame!.level, Level.detective);
  });
}

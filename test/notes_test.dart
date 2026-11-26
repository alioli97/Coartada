import 'dart:convert';

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

void main() {
  late Puzzle p;
  late List<int> free;
  setUp(() {
    p = generatePuzzle(level: Level.detective, seed: 4);
    free = [
      for (var c = 0; c < p.board.cellCount; c++)
        if (p.board.standable(c)) c,
    ];
  });

  test('notes toggle per person and need someone selected', () {
    final g = GameController(p)..toggleNotesMode();
    expect(g.tap(free[0]), TapResult.needsSuspect);
    g.select(0);
    g.tap(free[0]);
    g.select(0); // deselect, then pick another person
    g.select(2);
    g.tap(free[0]);
    expect(g.notesAt(free[0]), {0, 2});
    expect(g.selected, 2); // notes mode doesn't move the selection on
    g.tap(free[0]);
    expect(g.notesAt(free[0]), {0});
    final blocked = p.board.furniture.indexWhere((f) => f.blocks);
    expect(g.tap(blocked), TapResult.blocked);
  });

  test('undo restores notes; crossing out or restarting clears them', () {
    final g = GameController(p)
      ..toggleNotesMode()
      ..select(1);
    g.tap(free[0]);
    g.tap(free[1]);
    g.undo();
    expect(g.notesAt(free[1]), isEmpty);
    expect(g.notesAt(free[0]), {1});

    g.toggleCrossMode();
    g.tap(free[0]);
    expect(g.crosses, contains(free[0]));
    expect(g.notesAt(free[0]), isEmpty);
    g.undo();
    expect(g.notesAt(free[0]), {1});

    g.restart();
    expect(g.notes, isEmpty);
  });

  test('notes are saved, and older saves without them still load', () {
    final g = GameController(p)
      ..toggleNotesMode()
      ..select(3);
    g.tap(free[2]);
    final json = jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>;
    expect(GameController.fromJson(json)!.notesAt(free[2]), {3});
    expect(GameController.fromJson({...json}..remove('notes')), isNotNull);
  });

  testWidgets('pencilled initials appear on the square', (tester) async {
    tester.view.physicalSize = const Size(375 * 3, 812 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final app = AppState(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: GameScreen(appState: app, puzzle: p),
      ),
    );
    await tester.tap(find.text('Notas'));
    await tester.pump();
    final squares = find.descendant(
      of: find.byType(BoardView),
      matching: find.byType(InkWell),
    );
    // Without a suspect: a hint to pick one.
    await tester.tap(squares.at(free[0]));
    await tester.pump();
    expect(find.text('Elige primero a quién quieres anotar.'), findsOneWidget);

    await tester.tap(find.text(p.name(0)).first);
    await tester.pump();
    await tester.tap(squares.at(free[0]));
    await tester.pump();
    expect(
      find.descendant(
        of: squares.at(free[0]),
        matching: find.text(p.name(0)[0]),
      ),
      findsOneWidget,
    );
  });
}

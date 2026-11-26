import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/game/solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final variant in Variant.values) {
    for (final level in Level.values) {
      test('${level.name} ${variant.name}: unique, consistent cases', () {
        for (var seed = 0; seed < 15; seed++) {
          final p = generatePuzzle(level: level, seed: seed, variant: variant);
          final b = p.board;
          final n = level.size;
          expect(p.people, n);
          // The solution follows the rules.
          expect({for (final c in p.solution) b.row(c)}.length, n);
          expect({for (final c in p.solution) b.col(c)}.length, n);
          expect(p.solution.every(b.standable), isTrue);
          if (variant == Variant.noTouch) {
            for (final a in p.solution) {
              for (final c in p.solution) {
                expect(b.touch(a, c), isFalse);
              }
            }
          }
          // Every clue is true and the clues pin down one placement.
          expect(p.clues.every((c) => c.holds(b, p.solution)), isTrue);
          expect(countSolutions(b, n, p.victim, p.clues), 1);
          expect(culpritOf(b, p.victim, p.solution), p.culprit);
        }
      });
    }
  }

  test('same seed, same case', () {
    final a = generatePuzzle(level: Level.inspector, seed: 42);
    final b = generatePuzzle(level: Level.inspector, seed: 42);
    expect(a.solution, b.solution);
    expect(a.board.roomOf, b.board.roomOf);
    expect(a.clues.length, b.clues.length);
  });

  test('solver rejects a broken rule', () {
    final p = generatePuzzle(level: Level.apprentice, seed: 7);
    // Without clues there are many placements.
    expect(countSolutions(p.board, 4, p.victim, const []), 2);
  });
}

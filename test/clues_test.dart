import 'package:coartada/core/strings.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 4×4: rooms 0 (top half) and 1 (bottom half), no furniture.
  final b = Board(
    size: 4,
    variant: Variant.classic,
    roomOf: [for (var i = 0; i < 16; i++) i < 8 ? 0 : 1],
    rooms: [RoomKind.kitchen, RoomKind.garden],
    furniture: List.filled(16, Furniture.none),
  );

  test('in a corner / by an outer wall', () {
    expect(
      [
        for (var c = 0; c < 16; c++)
          if (const InCorner(0).allows(b, c)) c,
      ],
      [0, 3, 12, 15],
    );
    final walls = [
      for (var c = 0; c < 16; c++)
        if (const ByOuterWall(0).allows(b, c)) c,
    ];
    expect(walls, isNot(contains(5)));
    expect(walls, hasLength(12));
  });

  test('nobody in a room applies to everyone', () {
    const clue = NobodyInRoom(1);
    expect(clue.isGlobal, isTrue);
    expect(clue.appliesTo(0) && clue.appliesTo(3), isTrue);
    expect(clue.holds(b, [0, 5, 2, 7]), isTrue);
    expect(clue.holds(b, [0, 5, 2, 12]), isFalse);
  });

  test('different room / same diagonal', () {
    expect(const DifferentRoom(0, 1).allowsPair(b, 0, 12), isTrue);
    expect(const DifferentRoom(0, 1).allowsPair(b, 0, 5), isFalse);
    expect(const SameDiagonal(0, 1).allowsPair(b, 0, 15), isTrue);
    expect(const SameDiagonal(0, 1).allowsPair(b, 3, 12), isTrue);
    expect(const SameDiagonal(0, 1).allowsPair(b, 0, 6), isFalse);
  });

  test('the generator uses every new clue type', () {
    const fresh = {
      InCorner,
      ByOuterWall,
      NobodyInRoom,
      DifferentRoom,
      SameDiagonal,
    };
    final seen = <Type>{};
    for (var seed = 0; seed < 80 && !seen.containsAll(fresh); seed++) {
      for (final level in Level.values) {
        for (final c in generatePuzzle(level: level, seed: seed).clues) {
          seen.add(c.runtimeType);
        }
      }
    }
    expect(
      seen,
      containsAll([
        InCorner,
        ByOuterWall,
        NobodyInRoom,
        DifferentRoom,
        SameDiagonal,
      ]),
    );
  });

  test('every clue type reads well in all three languages', () {
    final p = generatePuzzle(level: Level.apprentice, seed: 1);
    final clues = <Clue>[
      const InCorner(0),
      const ByOuterWall(0),
      const NobodyInRoom(0),
      const DifferentRoom(0, 1),
      const SameDiagonal(0, 1),
    ];
    for (final lang in Strings.languages.keys) {
      for (final c in clues) {
        final text = Strings(lang).clue(c, p);
        expect(text[0], text[0].toUpperCase(), reason: '$lang $text');
        expect(text.endsWith('.'), isTrue);
      }
    }
    expect(
      const Strings('es').clue(const NobodyInRoom(0), p),
      startsWith('Nadie estaba'),
    );
  });
}

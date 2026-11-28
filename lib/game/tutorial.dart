import 'model.dart';

/// The guided first case: hand-made (original), 4×4, solved in four steps
/// that each teach one idea:
/// 1. Bruno — a clue alone ("on a chair": there's only one chair);
/// 2. Darío — another clue alone ("on a rug");
/// 3. Abril — a clue plus taken rows ("in the kitchen", Bruno's row is
///    taken and the table blocks the other square);
/// 4. Carmen — no clue at all: the only row and column left.
/// Then the victim rule: Carmen is the only one in Darío's room.
///
/// ```
///      A        B        C        D
/// 1  table    Abril    ·        shelf     kitchen | library
/// 2  ·        ·        ·        Bruno(chair)
/// 3  Carmen   ·        ·        ·         garden  | library
/// 4  plant    ·        Darío(rug) ·
/// ```
Puzzle tutorialPuzzle() {
  const k = 0, l = 1, g = 2;
  final furniture = List.filled(16, Furniture.none);
  furniture[0] = Furniture.table;
  furniture[3] = Furniture.shelf;
  furniture[7] = Furniture.chair;
  furniture[12] = Furniture.plant;
  furniture[14] = Furniture.rug;
  return Puzzle(
    board: Board(
      size: 4,
      variant: Variant.classic,
      roomOf: const [
        k, k, l, l, //
        k, k, l, l, //
        g, g, g, l, //
        g, g, g, l, //
      ],
      rooms: const [RoomKind.kitchen, RoomKind.library, RoomKind.garden],
      furniture: furniture,
    ),
    // Abril, Bruno, Carmen, Darío.
    cast: const [0, 1, 2, 3],
    victim: 3,
    culprit: 2,
    solution: const [1, 7, 8, 14],
    clues: const [
      OnFurniture(3, Furniture.rug),
      InRoom(0, k),
      OnFurniture(1, Furniture.chair),
    ],
    seed: 0,
    level: Level.apprentice,
  );
}

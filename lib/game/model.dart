/// Core data types of a case: the house (board), the people, the clues.
library;

enum Furniture {
  none,
  chair,
  rug,
  table,
  plant,
  shelf;

  /// Nobody can stand on a blocking piece of furniture.
  bool get blocks => this == table || this == plant || this == shelf;

  /// Someone can stand on it, and a clue can say so.
  bool get isSeat => this == chair || this == rug;
}

enum RoomKind {
  kitchen,
  library,
  study,
  lounge,
  bedroom,
  bathroom,
  garden,
  cellar,
  dining,
}

enum Variant {
  /// One person per row and per column.
  classic,

  /// Classic, and nobody touches anyone else, not even diagonally.
  noTouch,
}

/// The four levels, one per board size.
enum Level {
  apprentice(4),
  detective(5),
  inspector(6),
  commissioner(7);

  const Level(this.size);
  final int size;
}

/// Fixed roster. A case uses `size` of them; colors are by roster index.
const roster = [
  'Abril',
  'Bruno',
  'Carmen',
  'Darío',
  'Elena',
  'Félix',
  'Greta',
  'Hugo',
];

/// The house: grid, rooms and furniture. No people.
class Board {
  Board({
    required this.size,
    required this.variant,
    required this.roomOf,
    required this.rooms,
    required this.furniture,
  });

  final int size;
  final Variant variant;

  /// Room index for every cell (row-major).
  final List<int> roomOf;

  /// Kind of every room index.
  final List<RoomKind> rooms;
  final List<Furniture> furniture;

  int get cellCount => size * size;
  int row(int cell) => cell ~/ size;
  int col(int cell) => cell % size;
  int cell(int row, int col) => row * size + col;

  bool standable(int cell) => !furniture[cell].blocks;

  /// Orthogonal neighbours.
  Iterable<int> neighbours(int cell) sync* {
    final r = row(cell), c = col(cell);
    if (r > 0) yield cell - size;
    if (r < size - 1) yield cell + size;
    if (c > 0) yield cell - 1;
    if (c < size - 1) yield cell + 1;
  }

  /// Different cells that share a side or a corner.
  bool touch(int a, int b) =>
      a != b && (row(a) - row(b)).abs() <= 1 && (col(a) - col(b)).abs() <= 1;

  bool nextTo(int cell, Furniture f) =>
      neighbours(cell).any((n) => furniture[n] == f);
}

/// A statement about where someone was. People are indices into the case's
/// cast (0..size-1).
sealed class Clue {
  const Clue(this.subject);
  final int subject;

  /// The second person of a two-person clue.
  int? get other => null;

  /// Whether the subject may stand on [cell] (one-person clues).
  bool allows(Board b, int cell) => true;

  /// Whether the pair of positions fits (two-person clues).
  bool allowsPair(Board b, int subjectCell, int otherCell) => true;

  bool holds(Board b, List<int> positions) {
    final o = other;
    if (o == null) return allows(b, positions[subject]);
    return allowsPair(b, positions[subject], positions[o]);
  }
}

class InRoom extends Clue {
  const InRoom(super.subject, this.room);
  final int room;
  @override
  bool allows(Board b, int cell) => b.roomOf[cell] == room;
}

class NotInRoom extends Clue {
  const NotInRoom(super.subject, this.room);
  final int room;
  @override
  bool allows(Board b, int cell) => b.roomOf[cell] != room;
}

class OnFurniture extends Clue {
  const OnFurniture(super.subject, this.furniture);
  final Furniture furniture;
  @override
  bool allows(Board b, int cell) => b.furniture[cell] == furniture;
}

class NextTo extends Clue {
  const NextTo(super.subject, this.furniture);
  final Furniture furniture;
  @override
  bool allows(Board b, int cell) => b.nextTo(cell, furniture);
}

class InRow extends Clue {
  const InRow(super.subject, this.row);
  final int row;
  @override
  bool allows(Board b, int cell) => b.row(cell) == row;
}

class InColumn extends Clue {
  const InColumn(super.subject, this.column);
  final int column;
  @override
  bool allows(Board b, int cell) => b.col(cell) == column;
}

/// Subject was in a row above (north of) the other person.
class NorthOf extends Clue {
  const NorthOf(super.subject, this.otherPerson);
  final int otherPerson;
  @override
  int get other => otherPerson;
  @override
  bool allowsPair(Board b, int subjectCell, int otherCell) =>
      b.row(subjectCell) < b.row(otherCell);
}

/// Subject was in a column left of (west of) the other person.
class WestOf extends Clue {
  const WestOf(super.subject, this.otherPerson);
  final int otherPerson;
  @override
  int get other => otherPerson;
  @override
  bool allowsPair(Board b, int subjectCell, int otherCell) =>
      b.col(subjectCell) < b.col(otherCell);
}

class SameRoom extends Clue {
  const SameRoom(super.subject, this.otherPerson);
  final int otherPerson;
  @override
  int get other => otherPerson;
  @override
  bool allowsPair(Board b, int subjectCell, int otherCell) =>
      b.roomOf[subjectCell] == b.roomOf[otherCell];
}

/// A generated case with a unique solution.
class Puzzle {
  Puzzle({
    required this.board,
    required this.cast,
    required this.victim,
    required this.culprit,
    required this.solution,
    required this.clues,
    required this.seed,
    required this.level,
  });

  final Board board;

  /// Roster index of every person in the case.
  final List<int> cast;
  final int victim;
  final int culprit;

  /// Cell of every person.
  final List<int> solution;
  final List<Clue> clues;
  final int seed;
  final Level level;

  int get people => cast.length;
  String name(int person) => roster[cast[person]];
}

import 'dart:math';

import 'deducer.dart';
import 'model.dart';

/// Builds a random case with exactly one solution. Same arguments, same case.
Puzzle generatePuzzle({
  required Level level,
  required int seed,
  Variant variant = Variant.classic,
}) {
  final rng = Random(seed);
  for (var attempt = 0; attempt < 200; attempt++) {
    final p = _tryGenerate(level, variant, rng, seed);
    if (p != null) return p;
  }
  throw StateError('Could not generate a case (seed $seed)');
}

const _roomCount = {4: 3, 5: 4, 6: 5, 7: 6};

/// Relative chance of each clue type being picked, per level. Easier levels
/// lean on direct clues (row, column, room); harder ones on relations.
const _weights = {
  Level.apprentice: {
    InRow: 3.0, InColumn: 3.0, InRoom: 3.0, OnFurniture: 2.0, NextTo: 1.0, //
    NotInRoom: 1.0, NorthOf: 1.0, WestOf: 1.0, SameRoom: 1.0,
    InCorner: 1.5,
    ByOuterWall: 1.5,
    NobodyInRoom: 1.5,
    DifferentRoom: 0.5,
    SameDiagonal: 0.5,
  },
  Level.detective: {
    InRow: 2.0, InColumn: 2.0, InRoom: 3.0, OnFurniture: 2.0, NextTo: 2.0, //
    NotInRoom: 2.0, NorthOf: 2.0, WestOf: 2.0, SameRoom: 2.0,
    InCorner: 1.5,
    ByOuterWall: 1.5,
    NobodyInRoom: 1.5,
    DifferentRoom: 1.0,
    SameDiagonal: 1.0,
  },
  Level.inspector: {
    InRow: 1.0, InColumn: 1.0, InRoom: 2.0, OnFurniture: 2.0, NextTo: 3.0, //
    NotInRoom: 3.0, NorthOf: 3.0, WestOf: 3.0, SameRoom: 2.0,
    InCorner: 1.5,
    ByOuterWall: 1.5,
    NobodyInRoom: 1.5,
    DifferentRoom: 1.5,
    SameDiagonal: 1.5,
  },
  Level.commissioner: {
    InRow: 0.4, InColumn: 0.4, InRoom: 2.0, OnFurniture: 2.0, NextTo: 3.0, //
    NotInRoom: 3.0, NorthOf: 3.0, WestOf: 3.0, SameRoom: 2.0,
    InCorner: 1.5,
    ByOuterWall: 1.5,
    NobodyInRoom: 1.5,
    DifferentRoom: 2.0,
    SameDiagonal: 2.0,
  },
};

/// Redundant clues kept after minimising, so easy cases are gentler.
const _spare = {
  Level.apprentice: 2,
  Level.detective: 1,
  Level.inspector: 0,
  Level.commissioner: 0,
};

Puzzle? _tryGenerate(Level level, Variant variant, Random rng, int seed) {
  final n = level.size;

  // 1. Solution: one person per row, a column per row.
  final perm = _permutation(n, variant, rng);
  if (perm == null) return null;
  final cells = [for (var r = 0; r < n; r++) r * n + perm[r]];
  cells.shuffle(rng); // cells[p] is where person p was
  final occupied = cells.toSet();

  // 2. Rooms.
  final roomOf = _rooms(n, _roomCount[n]!, rng);
  final kinds = [...RoomKind.values]..shuffle(rng);
  final rooms = kinds.take(_roomCount[n]!).toList();

  // 3. Victim and culprit: the victim's room must hold exactly one other.
  final people = List.generate(n, (p) => p)..shuffle(rng);
  int? victim, culprit;
  for (final v in people) {
    final mates = [
      for (var q = 0; q < n; q++)
        if (q != v && roomOf[cells[q]] == roomOf[cells[v]]) q,
    ];
    if (mates.length == 1) {
      victim = v;
      culprit = mates.single;
      break;
    }
  }
  if (victim == null || culprit == null) return null;

  // 4. Furniture: obstacles on empty cells, seats anywhere standable.
  final furniture = List.filled(n * n, Furniture.none);
  final empty = [
    for (var c = 0; c < n * n; c++)
      if (!occupied.contains(c)) c,
  ]..shuffle(rng);
  const blockers = [Furniture.table, Furniture.plant, Furniture.shelf];
  final blockCount = (n * n * 0.2).round();
  for (final c in empty.take(blockCount)) {
    furniture[c] = blockers[rng.nextInt(blockers.length)];
  }
  final seatSpots = [
    ...cells.take(n ~/ 2 + 1),
    ...empty.skip(blockCount).take(n ~/ 2),
  ];
  for (final c in seatSpots) {
    furniture[c] = rng.nextBool() ? Furniture.chair : Furniture.rug;
  }

  final board = Board(
    size: n,
    variant: variant,
    roomOf: roomOf,
    rooms: rooms,
    furniture: furniture,
  );

  // 5. Every true clue, in a weighted random order.
  final pool = _cluePool(board, cells, victim, rng);
  final weights = _weights[level]!;
  final keyed = [
    for (final c in pool)
      (c, -log(1 - rng.nextDouble()) / weights[c.runtimeType]!),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  final ordered = [for (final k in keyed) k.$1];

  // A clue set is good when a person can reason the whole solution out (the
  // Deducer's techniques), never by trial and error. Since the Deducer only
  // rules out what the rules forbid, reaching one square per person also
  // proves the solution is unique (tests double-check with the solver).
  bool good(List<Clue> clues) {
    final draft = Puzzle(
      board: board,
      cast: List.generate(n, (i) => i),
      victim: victim!,
      culprit: culprit!,
      solution: cells,
      clues: clues,
      seed: seed,
      level: level,
    );
    return Deducer.solvesAll(draft).$1;
  }

  // 6. Add clues until the case is good.
  final chosen = <Clue>[];
  var solved = false;
  for (final c in ordered) {
    chosen.add(c);
    if (chosen.length < n - 1) continue;
    if (good(chosen)) {
      solved = true;
      break;
    }
  }
  if (!solved) return null;

  // 7. Drop clues that aren't needed, then keep a few spares on easy levels.
  final removed = <Clue>[];
  for (final c in [...chosen]..shuffle(rng)) {
    final without = [...chosen]..remove(c);
    if (good(without)) {
      chosen.remove(c);
      removed.add(c);
    }
  }
  chosen.addAll(removed.take(_spare[level]!));

  // Grouped by person, victim first, so the list reads like witness reports.
  // Clues about nobody in particular go last.
  int rank(Clue c) => c.isGlobal
      ? 1 << 20
      : c.subject == victim
      ? -1
      : c.subject;
  chosen.sort((a, b) => rank(a).compareTo(rank(b)));

  final cast = List.generate(roster.length, (i) => i)..shuffle(rng);
  return Puzzle(
    board: board,
    cast: cast.take(n).toList(),
    victim: victim,
    culprit: culprit,
    solution: cells,
    clues: chosen,
    seed: seed,
    level: level,
  );
}

List<int>? _permutation(int n, Variant variant, Random rng) {
  final perm = List.generate(n, (i) => i);
  for (var i = 0; i < 2000; i++) {
    perm.shuffle(rng);
    if (variant == Variant.classic) return perm;
    var ok = true;
    for (var r = 0; r + 1 < n; r++) {
      if ((perm[r] - perm[r + 1]).abs() <= 1) ok = false;
    }
    if (ok) return perm;
  }
  return null;
}

/// Splits the grid into [k] connected rooms of similar size.
List<int> _rooms(int n, int k, Random rng) {
  while (true) {
    final roomOf = List.filled(n * n, -1);
    final seeds = (List.generate(n * n, (i) => i)..shuffle(rng)).take(k);
    var r = 0;
    for (final s in seeds) {
      roomOf[s] = r++;
    }
    final sizes = List.filled(k, 1);
    var left = n * n - k;
    Iterable<int> free(int cell) sync* {
      final row = cell ~/ n, col = cell % n;
      if (row > 0 && roomOf[cell - n] < 0) yield cell - n;
      if (row < n - 1 && roomOf[cell + n] < 0) yield cell + n;
      if (col > 0 && roomOf[cell - 1] < 0) yield cell - 1;
      if (col < n - 1 && roomOf[cell + 1] < 0) yield cell + 1;
    }

    while (left > 0) {
      final order = List.generate(k, (i) => i)..shuffle(rng);
      order.sort((a, b) => sizes[a].compareTo(sizes[b]));
      var grew = false;
      for (final room in order) {
        final frontier = <int>{
          for (var c = 0; c < n * n; c++)
            if (roomOf[c] == room) ...free(c),
        }.toList();
        if (frontier.isEmpty) continue;
        roomOf[frontier[rng.nextInt(frontier.length)]] = room;
        sizes[room]++;
        left--;
        grew = true;
        break;
      }
      if (!grew) break;
    }
    if (left == 0 && sizes.every((s) => s >= 3)) return roomOf;
  }
}

List<Clue> _cluePool(Board b, List<int> cells, int victim, Random rng) {
  final n = cells.length;
  final pool = <Clue>[];
  for (var p = 0; p < n; p++) {
    final cell = cells[p];
    pool
      ..add(InRow(p, b.row(cell)))
      ..add(InColumn(p, b.col(cell)))
      ..add(InRoom(p, b.roomOf[cell]));
    final elsewhere = [
      for (var r = 0; r < b.rooms.length; r++)
        if (r != b.roomOf[cell]) r,
    ]..shuffle(rng);
    for (final r in elsewhere.take(2)) {
      pool.add(NotInRoom(p, r));
    }
    if (b.furniture[cell].isSeat) pool.add(OnFurniture(p, b.furniture[cell]));
    final corner = InCorner(p), wall = ByOuterWall(p);
    if (corner.allows(b, cell)) pool.add(corner);
    if (wall.allows(b, cell)) pool.add(wall);
    for (final f in {for (final nb in b.neighbours(cell)) b.furniture[nb]}) {
      if (f.blocks || f == Furniture.chair) pool.add(NextTo(p, f));
    }
    for (var q = 0; q < n; q++) {
      if (q == p) continue;
      if (b.row(cell) < b.row(cells[q])) pool.add(NorthOf(p, q));
      if (b.col(cell) < b.col(cells[q])) pool.add(WestOf(p, q));
      if (p < q) {
        final (rp, rq) = (b.roomOf[cell], b.roomOf[cells[q]]);
        if (rp != rq) pool.add(DifferentRoom(p, q));
        final (dr, dc) = (
          (b.row(cell) - b.row(cells[q])).abs(),
          (b.col(cell) - b.col(cells[q])).abs(),
        );
        if (dr == dc) pool.add(SameDiagonal(p, q));
      }
      if (p < q &&
          p != victim &&
          q != victim &&
          b.roomOf[cell] == b.roomOf[cells[q]]) {
        pool.add(SameRoom(p, q));
      }
    }
  }
  final occupiedRooms = {for (final c in cells) b.roomOf[c]};
  for (var r = 0; r < b.rooms.length; r++) {
    if (!occupiedRooms.contains(r)) pool.add(NobodyInRoom(r));
  }
  return pool;
}

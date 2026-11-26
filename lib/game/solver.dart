import 'model.dart';

/// The rules every case follows, besides its clues:
/// - one person per row and per column;
/// - nobody stands on blocking furniture;
/// - with [Variant.noTouch], nobody touches anyone else;
/// - exactly one other person shares the victim's room (the culprit).
///
/// Counts placements that satisfy the rules and [clues], stopping at [limit].
int countSolutions(
  Board board,
  int people,
  int victim,
  List<Clue> clues, {
  int limit = 2,
}) {
  final n = people;
  final candidates = List.generate(n, (p) {
    final unary = clues.where((c) => c.subject == p && c.other == null);
    return [
      for (var cell = 0; cell < board.cellCount; cell++)
        if (board.standable(cell) && unary.every((c) => c.allows(board, cell)))
          cell,
    ];
  });
  if (candidates.any((c) => c.isEmpty)) return 0;

  final pairClues = List.generate(
    n,
    (p) => [
      for (final c in clues)
        if (c.other != null && (c.subject == p || c.other == p)) c,
    ],
  );

  final order = List.generate(n, (p) => p)
    ..sort((a, b) => candidates[a].length.compareTo(candidates[b].length));

  final pos = List<int>.filled(n, -1);
  final rowUsed = List<bool>.filled(board.size, false);
  final colUsed = List<bool>.filled(board.size, false);
  final noTouch = board.variant == Variant.noTouch;
  var found = 0;

  bool victimRoomOk({required bool complete}) {
    final v = pos[victim];
    if (v < 0) return true;
    final room = board.roomOf[v];
    var others = 0;
    for (var p = 0; p < n; p++) {
      if (p != victim && pos[p] >= 0 && board.roomOf[pos[p]] == room) others++;
    }
    return complete ? others == 1 : others <= 1;
  }

  void search(int i) {
    if (found >= limit) return;
    if (i == n) {
      if (victimRoomOk(complete: true)) found++;
      return;
    }
    final p = order[i];
    for (final cell in candidates[p]) {
      final r = board.row(cell), c = board.col(cell);
      if (rowUsed[r] || colUsed[c]) continue;
      if (noTouch && pos.any((q) => q >= 0 && board.touch(q, cell))) continue;
      pos[p] = cell;
      var ok = true;
      for (final clue in pairClues[p]) {
        final s = pos[clue.subject], o = pos[clue.other!];
        if (s >= 0 && o >= 0 && !clue.allowsPair(board, s, o)) {
          ok = false;
          break;
        }
      }
      if (ok && victimRoomOk(complete: false)) {
        rowUsed[r] = colUsed[c] = true;
        search(i + 1);
        rowUsed[r] = colUsed[c] = false;
      }
      pos[p] = -1;
      if (found >= limit) return;
    }
  }

  search(0);
  return found;
}

/// Who shares the victim's room in [positions], or null when it isn't
/// exactly one person.
int? culpritOf(Board board, int victim, List<int> positions) {
  final room = board.roomOf[positions[victim]];
  final others = [
    for (var p = 0; p < positions.length; p++)
      if (p != victim && board.roomOf[positions[p]] == room) p,
  ];
  return others.length == 1 ? others.single : null;
}

import 'model.dart';

/// Why some squares were ruled out for a person, in human terms.
enum Reason {
  /// One of the case's clues (see [Deduction.clues]).
  clues,

  /// Someone else already fills that row or column (or touches it, in the
  /// no-touch variant).
  occupied,

  /// A row or column needs someone, and only this person can go there.
  rowColumnNeeds,

  /// Exactly one other person shares the victim's room.
  victimRule,
}

/// "[person] can only be in [cell]", and why.
class Deduction {
  const Deduction({
    required this.person,
    required this.cell,
    required this.reasons,
    required this.clues,
  });

  final int person;
  final int cell;
  final Set<Reason> reasons;

  /// Indices into `Puzzle.clues` that ruled squares out for [person].
  final Set<int> clues;
}

/// Solves like a person would: keeps the squares each person could still be
/// on and rules squares out with simple techniques, simplest first, until
/// someone has a single square left. No guessing, no backtracking.
class Deducer {
  Deducer(this.puzzle, {this.known = const {}});

  final Puzzle puzzle;

  /// People whose square is already settled (correctly placed by the
  /// player): person → square.
  final Map<int, int> known;

  Board get _b => puzzle.board;
  int get _n => puzzle.people;

  late final List<Set<int>> _cand;
  late final List<Set<Reason>> _why;
  late final List<Set<int>> _whyClues;

  /// The simplest next placement the player hasn't made yet, or null when
  /// these techniques get stuck.
  Deduction? next() {
    _init();
    final single = _newSingle();
    if (single != null) return single;
    for (var round = 0; round < 200; round++) {
      var changed = false;
      for (final technique in [
        _occupied,
        _pairClues,
        _rowColumn,
        _blockedByOther,
        _victim,
        _sharedLines,
      ]) {
        if (technique()) {
          changed = true;
          final found = _newSingle();
          if (found != null) return found;
          break; // back to the simplest technique
        }
      }
      if (!changed) return null;
    }
    return null;
  }

  /// Whether these techniques alone place everyone, starting from scratch.
  /// Also the number of deductions needed (a rough difficulty).
  static (bool, int) solvesAll(Puzzle puzzle) {
    final known = <int, int>{};
    var steps = 0;
    while (known.length < puzzle.people) {
      final d = Deducer(puzzle, known: known).next();
      if (d == null) return (false, steps);
      if (puzzle.solution[d.person] != d.cell) return (false, steps);
      known[d.person] = d.cell;
      steps++;
    }
    return (true, steps);
  }

  void _init() {
    _cand = [];
    _why = List.generate(_n, (_) => <Reason>{});
    _whyClues = List.generate(_n, (_) => <int>{});
    for (var p = 0; p < _n; p++) {
      final k = known[p];
      if (k != null) {
        _cand.add({k});
        continue;
      }
      final cells = <int>{
        for (var c = 0; c < _b.cellCount; c++)
          if (_b.standable(c)) c,
      };
      for (var i = 0; i < puzzle.clues.length; i++) {
        final clue = puzzle.clues[i];
        if (!clue.appliesTo(p) || clue.other != null) continue;
        final before = cells.length;
        cells.removeWhere((c) => !clue.allows(_b, c));
        if (cells.length < before) {
          _why[p].add(Reason.clues);
          _whyClues[p].add(i);
        }
      }
      _cand.add(cells);
    }
  }

  Deduction? _newSingle() {
    for (var p = 0; p < _n; p++) {
      if (known.containsKey(p) || _cand[p].length != 1) continue;
      return Deduction(
        person: p,
        cell: _cand[p].single,
        reasons: _why[p],
        clues: _whyClues[p],
      );
    }
    return null;
  }

  bool _remove(int p, bool Function(int cell) out, Reason why, [int? clue]) {
    final before = _cand[p].length;
    _cand[p].removeWhere(out);
    if (_cand[p].length == before) return false;
    _why[p].add(why);
    if (clue != null) _whyClues[p].add(clue);
    return true;
  }

  bool _clash(int a, int b) =>
      _b.row(a) == _b.row(b) ||
      _b.col(a) == _b.col(b) ||
      (_b.variant == Variant.noTouch && _b.touch(a, b));

  /// Settled people block their row, column (and neighbours in no-touch).
  bool _occupied() {
    var changed = false;
    for (var p = 0; p < _n; p++) {
      if (_cand[p].length != 1) continue;
      final cell = _cand[p].single;
      for (var q = 0; q < _n; q++) {
        if (q == p) continue;
        changed |= _remove(q, (c) => _clash(c, cell), Reason.occupied);
      }
    }
    return changed;
  }

  /// Two-person clues: keep only squares with a compatible partner square.
  bool _pairClues() {
    var changed = false;
    for (var i = 0; i < puzzle.clues.length; i++) {
      final clue = puzzle.clues[i];
      final o = clue.other;
      if (o == null) continue;
      final s = clue.subject;
      changed |= _remove(
        s,
        (cs) => !_cand[o].any(
          (co) => !_clash(cs, co) && clue.allowsPair(_b, cs, co),
        ),
        Reason.clues,
        i,
      );
      changed |= _remove(
        o,
        (co) => !_cand[s].any(
          (cs) => !_clash(cs, co) && clue.allowsPair(_b, cs, co),
        ),
        Reason.clues,
        i,
      );
    }
    return changed;
  }

  /// Every row and column holds someone: if only one person can still reach
  /// a row (or column), they must be in it.
  bool _rowColumn() {
    var changed = false;
    for (final byRow in [true, false]) {
      int line(int c) => byRow ? _b.row(c) : _b.col(c);
      for (var l = 0; l < _b.size; l++) {
        final who = [
          for (var p = 0; p < _n; p++)
            if (_cand[p].any((c) => line(c) == l)) p,
        ];
        if (who.length == 1) {
          changed |= _remove(
            who.single,
            (c) => line(c) != l,
            Reason.rowColumnNeeds,
          );
        }
      }
    }
    return changed;
  }

  /// A square is out for someone if every square still open to another
  /// person shares its row or column (or touches it, in no-touch).
  bool _blockedByOther() {
    var changed = false;
    for (var q = 0; q < _n; q++) {
      if (_cand[q].length < 2 || _cand[q].length > _b.size) continue;
      for (var p = 0; p < _n; p++) {
        if (p == q) continue;
        changed |= _remove(
          p,
          (c) => _cand[q].every((cq) => _clash(c, cq)),
          Reason.occupied,
        );
      }
    }
    return changed;
  }

  /// If k people (k = 2 or 3) can only be in the same k rows (or columns),
  /// those rows are theirs: nobody else can be in them.
  bool _sharedLines() {
    var changed = false;
    for (final byRow in [true, false]) {
      int line(int c) => byRow ? _b.row(c) : _b.col(c);
      final lines = [
        for (var p = 0; p < _n; p++) {for (final c in _cand[p]) line(c)},
      ];
      for (var a = 0; a < _n; a++) {
        for (var b = a + 1; b < _n; b++) {
          final two = {...lines[a], ...lines[b]};
          if (two.length == 2) {
            changed |= _excludeLines(two, {a, b}, line);
          }
          for (var c = b + 1; c < _n; c++) {
            final three = {...two, ...lines[c]};
            if (three.length == 3) {
              changed |= _excludeLines(three, {a, b, c}, line);
            }
          }
        }
      }
    }
    return changed;
  }

  bool _excludeLines(Set<int> taken, Set<int> owners, int Function(int) line) {
    var changed = false;
    for (var p = 0; p < _n; p++) {
      if (owners.contains(p)) continue;
      changed |= _remove(
        p,
        (c) => taken.contains(line(c)),
        Reason.rowColumnNeeds,
      );
    }
    return changed;
  }

  /// Once the victim's room is known, exactly one other person is in it.
  bool _victim() {
    final v = puzzle.victim;
    final rooms = {for (final c in _cand[v]) _b.roomOf[c]};
    if (rooms.length != 1) return false;
    final room = rooms.single;
    bool inRoom(int c) => _b.roomOf[c] == room;
    final forced = [
      for (var q = 0; q < _n; q++)
        if (q != v && _cand[q].every(inRoom)) q,
    ];
    final possible = [
      for (var q = 0; q < _n; q++)
        if (q != v && _cand[q].any(inRoom)) q,
    ];
    var changed = false;
    if (forced.length == 1) {
      for (final q in possible) {
        if (q != forced.single) {
          changed |= _remove(q, inRoom, Reason.victimRule);
        }
      }
    } else if (forced.isEmpty && possible.length == 1) {
      changed |= _remove(possible.single, (c) => !inRoom(c), Reason.victimRule);
    }
    return changed;
  }
}

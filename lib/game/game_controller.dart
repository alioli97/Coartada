import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'generator.dart';
import 'model.dart';

enum Phase { placing, accusing, solved }

enum CheckResult { incomplete, wrong, correct }

enum TapResult { ok, blocked, locked }

/// What the player has on the board, with undo. UI-agnostic.
class GameController extends ChangeNotifier {
  GameController(
    this.puzzle, {
    this.daily = false,
    Duration elapsed = Duration.zero,
  }) : placement = List.filled(puzzle.people, null),
       _elapsedBefore = elapsed;

  /// Rebuilds a saved game (see [toJson]). The case itself is regenerated
  /// from its seed, so only the player's marks are stored. Returns null for
  /// data from another version or that doesn't fit the case.
  static GameController? fromJson(Map<String, dynamic> json) {
    try {
      if (json['v'] != saveVersion) return null;
      final puzzle = generatePuzzle(
        level: Level.values.byName(json['level'] as String),
        seed: json['seed'] as int,
        variant: Variant.values.byName(json['variant'] as String),
      );
      final g = GameController(
        puzzle,
        daily: json['daily'] as bool,
        elapsed: Duration(milliseconds: json['elapsedMs'] as int),
      );
      final cells = puzzle.board.cellCount;
      bool validCell(int c) => c >= 0 && c < cells;
      final placement = (json['placement'] as List).cast<int?>();
      if (placement.length != puzzle.people) return null;
      if (placement.any((c) => c != null && !validCell(c))) return null;
      for (var p = 0; p < placement.length; p++) {
        g.placement[p] = placement[p];
      }
      g.crosses.addAll((json['crosses'] as List).cast<int>().where(validCell));
      g.doneClues.addAll(
        (json['doneClues'] as List).cast<int>().where(
          (i) => i >= 0 && i < puzzle.clues.length,
        ),
      );
      g.locked.addAll(
        (json['locked'] as List).cast<int>().where(
          (p) => p >= 0 && p < puzzle.people,
        ),
      );
      g.hints = json['hints'] as int;
      g.wrongAccusations = json['wrongAccusations'] as int;
      return g;
    } catch (_) {
      return null;
    }
  }

  static const saveVersion = 1;

  /// The player's progress, enough to resume with [fromJson].
  Map<String, dynamic> toJson() => {
    'v': saveVersion,
    'seed': puzzle.seed,
    'level': puzzle.level.name,
    'variant': board.variant.name,
    'daily': daily,
    'placement': placement,
    'crosses': crosses.toList(),
    'doneClues': doneClues.toList(),
    'locked': locked.toList(),
    'hints': hints,
    'wrongAccusations': wrongAccusations,
    'elapsedMs': elapsed.inMilliseconds,
  };

  final Puzzle puzzle;
  final bool daily;
  Board get board => puzzle.board;

  /// Cell of every person, or null.
  final List<int?> placement;
  final Set<int> crosses = {};
  final Set<int> doneClues = {};

  /// People placed by a hint: right and can't be moved.
  final Set<int> locked = {};
  final List<(List<int?>, Set<int>)> _history = [];
  final Stopwatch _watch = Stopwatch()..start();
  final Duration _elapsedBefore;

  /// Time played, including earlier sessions of a resumed game.
  Duration get elapsed => _elapsedBefore + _watch.elapsed;

  int get placedCount => placement.where((c) => c != null).length;

  /// Stops the clock while the app is in the background.
  void pauseClock() => _watch.stop();

  void resumeClock() {
    if (phase != Phase.solved) _watch.start();
  }

  int? selected;
  bool crossMode = false;
  int hints = 0;
  int wrongAccusations = 0;
  Phase phase = Phase.placing;

  /// Last tapped cell, for the inspector line.
  int? focusedCell;

  bool get canUndo => _history.isNotEmpty && phase == Phase.placing;
  bool get allPlaced => placement.every((c) => c != null);

  int? personAt(int cell) {
    final i = placement.indexOf(cell);
    return i < 0 ? null : i;
  }

  /// Rows and columns with someone in them.
  Set<int> get takenRows => {
    for (final c in placement)
      if (c != null) board.row(c),
  };
  Set<int> get takenCols => {
    for (final c in placement)
      if (c != null) board.col(c),
  };

  /// People breaking a rule: sharing a row/column, or touching in no-touch.
  Set<int> get conflicts {
    final out = <int>{};
    for (var a = 0; a < placement.length; a++) {
      for (var b = a + 1; b < placement.length; b++) {
        final ca = placement[a], cb = placement[b];
        if (ca == null || cb == null) continue;
        final clash =
            board.row(ca) == board.row(cb) ||
            board.col(ca) == board.col(cb) ||
            (board.variant == Variant.noTouch && board.touch(ca, cb));
        if (clash) out.addAll([a, b]);
      }
    }
    return out;
  }

  void _save() {
    _history.add(([...placement], {...crosses}));
    if (_history.length > 200) _history.removeAt(0);
  }

  void undo() {
    if (!canUndo) return;
    final (p, x) = _history.removeLast();
    for (var i = 0; i < p.length; i++) {
      placement[i] = p[i];
    }
    crosses
      ..clear()
      ..addAll(x);
    notifyListeners();
  }

  void select(int? person) {
    if (phase != Phase.placing) return;
    selected = selected == person ? null : person;
    crossMode = false;
    notifyListeners();
  }

  void toggleCrossMode() {
    crossMode = !crossMode;
    if (crossMode) selected = null;
    notifyListeners();
  }

  void toggleClue(int index) {
    doneClues.contains(index) ? doneClues.remove(index) : doneClues.add(index);
    notifyListeners();
  }

  TapResult tap(int cell) {
    if (phase != Phase.placing) return TapResult.ok;
    focusedCell = cell;
    final here = personAt(cell);
    final sel = selected;

    if (crossMode || (sel == null && here == null)) {
      if (here != null) {
        notifyListeners();
        return TapResult.ok;
      }
      _save();
      crosses.contains(cell) ? crosses.remove(cell) : crosses.add(cell);
      notifyListeners();
      return TapResult.ok;
    }

    if (sel == null) {
      // Tapping someone on the board picks them up.
      selected = here;
      notifyListeners();
      return TapResult.ok;
    }

    if (locked.contains(sel) || (here != null && locked.contains(here))) {
      notifyListeners();
      return TapResult.locked;
    }
    if (here == sel) {
      _save();
      placement[sel] = null;
      notifyListeners();
      return TapResult.ok;
    }
    if (!board.standable(cell)) {
      notifyListeners();
      return TapResult.blocked;
    }
    _save();
    if (here != null) placement[here] = null;
    placement[sel] = cell;
    crosses.remove(cell);
    selected = _nextUnplaced(after: sel);
    notifyListeners();
    return TapResult.ok;
  }

  int? _nextUnplaced({required int after}) {
    final n = placement.length;
    for (var i = 1; i <= n; i++) {
      final p = (after + i) % n;
      if (placement[p] == null) return p;
    }
    return null;
  }

  CheckResult check() {
    if (!allPlaced) return CheckResult.incomplete;
    for (var p = 0; p < placement.length; p++) {
      if (placement[p] != puzzle.solution[p]) return CheckResult.wrong;
    }
    phase = Phase.accusing;
    selected = null;
    notifyListeners();
    return CheckResult.correct;
  }

  bool accuse(int person) {
    if (person == puzzle.culprit) {
      phase = Phase.solved;
      _watch.stop();
      notifyListeners();
      return true;
    }
    wrongAccusations++;
    notifyListeners();
    return false;
  }

  /// Puts one wrongly placed (or else unplaced) person in their real spot.
  /// Returns that person, or null when everyone is already right.
  int? hint([Random? rng]) {
    if (phase != Phase.placing) return null;
    final wrong = [
      for (var p = 0; p < placement.length; p++)
        if (placement[p] != null && placement[p] != puzzle.solution[p]) p,
    ];
    final missing = [
      for (var p = 0; p < placement.length; p++)
        if (placement[p] == null) p,
    ];
    final pool = wrong.isNotEmpty ? wrong : missing;
    if (pool.isEmpty) return null;
    final p = pool[(rng ?? Random()).nextInt(pool.length)];
    _save();
    final target = puzzle.solution[p];
    final other = personAt(target);
    if (other != null) placement[other] = null;
    placement[p] = target;
    crosses.remove(target);
    locked.add(p);
    hints++;
    if (selected == p) selected = null;
    notifyListeners();
    return p;
  }

  void restart() {
    _save();
    for (var p = 0; p < placement.length; p++) {
      if (!locked.contains(p)) placement[p] = null;
    }
    crosses.clear();
    doneClues.clear();
    selected = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _watch.stop();
    super.dispose();
  }
}

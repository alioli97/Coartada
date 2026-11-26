import 'package:material_ui/material_ui.dart';

import '../core/strings.dart';
import '../game/game_controller.dart';
import '../game/model.dart';
import '../theme/app_theme.dart';
import 'furniture_glyph.dart';
import 'suspect_avatar.dart';

/// The house map with row/column labels. Rebuilds from [controller].
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.controller,
    required this.strings,
    required this.onTap,
    this.visualHelp = true,
  });

  final GameController controller;
  final Strings strings;
  final void Function(int cell) onTap;

  /// Shade taken rows/columns and ring clashing people (a setting).
  final bool visualHelp;

  /// Width of the row/column label strip. Kept small so 7×7 squares stay
  /// ≥ 48dp on a 375px-wide phone (see test/board_size_test.dart).
  static const _label = 18.0;

  /// Smallest square: a full touch target (48dp, Android).
  static const minSquare = 48.0;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final b = c.board;
    final n = b.size;
    final game = context.game;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600);
    final conflicts = visualHelp ? c.conflicts : const <int>{};
    final takenRows = visualHelp ? c.takenRows : const <int>{};
    final takenCols = visualHelp ? c.takenCols : const <int>{};

    return LayoutBuilder(
      builder: (context, box) {
        final side = box.maxWidth.clamp(0.0, 520.0);
        // Squares never shrink below a touch target: if the board doesn't
        // fit at that size (8×8 on a phone), it becomes zoomable instead.
        final cell = ((side - _label) / n).clamp(minSquare, double.infinity);
        final boardSide = _label + cell * n;
        final board = SizedBox(
          width: boardSide,
          height: boardSide,
          child: Stack(
            children: [
              for (var col = 0; col < n; col++)
                Positioned(
                  left: _label + col * cell,
                  top: 0,
                  width: cell,
                  height: _label,
                  child: ExcludeSemantics(
                    child: Center(
                      child: Text(Strings.colLetter(col), style: labelStyle),
                    ),
                  ),
                ),
              for (var row = 0; row < n; row++)
                Positioned(
                  left: 0,
                  top: _label + row * cell,
                  width: _label,
                  height: cell,
                  child: ExcludeSemantics(
                    child: Center(child: Text('${row + 1}', style: labelStyle)),
                  ),
                ),
              Positioned(
                left: _label,
                top: _label,
                width: cell * n,
                height: cell * n,
                child: CustomPaint(
                  painter: _BoardPainter(
                    board: b,
                    colors: game,
                    shaded: {
                      for (var i = 0; i < b.cellCount; i++)
                        if (c.personAt(i) == null &&
                            (takenRows.contains(b.row(i)) ||
                                takenCols.contains(b.col(i))))
                          i,
                    },
                  ),
                  child: Stack(
                    children: [
                      for (var i = 0; i < b.cellCount; i++)
                        Positioned(
                          left: b.col(i) * cell,
                          top: b.row(i) * cell,
                          width: cell,
                          height: cell,
                          child: _Cell(
                            index: i,
                            size: cell,
                            controller: c,
                            strings: strings,
                            conflict: conflicts.contains(c.personAt(i)),
                            onTap: () => onTap(i),
                          ),
                        ),
                      // Final reveal, once the case is solved: the other
                      // rooms dim and the victim's room is outlined.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              end: c.phase == Phase.solved ? 1.0 : 0.0,
                            ),
                            duration: Motion.of(context, Motion.reveal),
                            curve: Motion.enter,
                            builder: (context, t, _) => t == 0
                                ? const SizedBox.expand()
                                : CustomPaint(
                                    painter: _RevealPainter(
                                      board: b,
                                      room:
                                          b.roomOf[c.puzzle.solution[c
                                              .puzzle
                                              .victim]],
                                      t: t,
                                      dim: scheme.surface,
                                      outline: scheme.secondary,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        if (boardSide <= side + 0.5) return board;
        return _ZoomableBoard(
          viewport: side,
          boardSide: boardSide,
          strings: strings,
          child: board,
        );
      },
    );
  }
}

/// A board bigger than the screen (8×8 on a phone): squares stay 48dp and
/// the player pans with one finger or pinches. A button toggles between
/// close-up and the whole board, so zoom never needs a two-finger gesture.
class _ZoomableBoard extends StatefulWidget {
  const _ZoomableBoard({
    required this.viewport,
    required this.boardSide,
    required this.strings,
    required this.child,
  });

  final double viewport;
  final double boardSide;
  final Strings strings;
  final Widget child;

  @override
  State<_ZoomableBoard> createState() => _ZoomableBoardState();
}

class _ZoomableBoardState extends State<_ZoomableBoard> {
  final _zoom = TransformationController();

  double get _fit => widget.viewport / widget.boardSide;
  // X scale (getMaxScaleOnAxis would include the unscaled Z axis).
  bool get _wholeBoard => _zoom.value.entry(0, 0) <= _fit + 0.01;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _zoom
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  void _toggle() {
    _zoom.value = _wholeBoard
        ? Matrix4.identity()
        : (Matrix4.identity()..scaleByDouble(_fit, _fit, 1, 1));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _toggle,
          icon: Icon(_wholeBoard ? Icons.zoom_in : Icons.zoom_out_map),
          label: Text(_wholeBoard ? s.zoomIn : s.wholeBoard),
        ),
        SizedBox.square(
          dimension: widget.viewport,
          child: ClipRect(
            child: InteractiveViewer(
              transformationController: _zoom,
              constrained: false,
              minScale: _fit,
              maxScale: 2,
              boundaryMargin: EdgeInsets.zero,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.index,
    required this.size,
    required this.controller,
    required this.strings,
    required this.conflict,
    required this.onTap,
  });

  final int index;
  final double size;
  final GameController controller;
  final Strings strings;
  final bool conflict;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final b = c.board;
    final p = c.puzzle;
    final f = b.furniture[index];
    final person = c.personAt(index);
    final scheme = Theme.of(context).colorScheme;
    final crossed = c.crosses.contains(index);
    final highlight = switch (c.activeHint) {
      MistakeHint(:final cell) when cell == index => scheme.error,
      DeductionHint(:final deduction) when deduction.cell == index =>
        scheme.secondary,
      RevealHint(:final cell) when cell == index => scheme.primary,
      _ => null,
    };
    final marks = person == null && !crossed
        ? (c.notesAt(index).toList()..sort())
        : const <int>[];

    Color? ring;
    if (person != null) {
      if (conflict) {
        ring = scheme.error;
      } else if (c.selected == person) {
        ring = scheme.secondary;
      } else if (c.phase == Phase.solved &&
          (person == p.victim || person == p.culprit)) {
        ring = scheme.secondary; // spotlight on the two people in the room
      } else if (c.locked.contains(person)) {
        ring = scheme.primary;
      }
    }

    final parts = [
      strings.row(b.row(index)),
      strings.column(b.col(index)),
      strings.roomName(b.rooms[b.roomOf[index]]),
      if (f != Furniture.none) strings.furnitureName(f),
      if (person != null)
        p.name(person)
      else if (crossed)
        strings.crossed
      else if (marks.isNotEmpty)
        strings.notesLabel([for (final m in marks) p.name(m)])
      else
        strings.empty,
    ];

    return Semantics(
      button: true,
      label: parts.join(', '),
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (highlight != null)
                // The square the current hint is about.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: highlight.withValues(alpha: 0.18),
                      border: Border.all(color: highlight, width: 3),
                    ),
                  ),
                ),
              // A rug is floor: it stays full size under whoever stands on
              // it. A chair shrinks to a corner badge when occupied.
              // Furniture fades behind pencil marks so they stay legible.
              Opacity(
                opacity: marks.isEmpty ? 1 : 0.3,
                child: f == Furniture.rug
                    ? FurnitureGlyph(f, size: size * 0.86)
                    : f != Furniture.none && person == null
                    ? FurnitureGlyph(f, size: size * 0.66)
                    : f == Furniture.chair
                    ? Align(
                        alignment: Alignment.bottomRight,
                        child: FurnitureGlyph(f, size: size * 0.36),
                      )
                    : const SizedBox.shrink(),
              ),
              if (marks.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(size * 0.06),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    runAlignment: WrapAlignment.center,
                    spacing: size * 0.04,
                    children: [
                      for (final m in marks)
                        Text(
                          p.name(m)[0],
                          style: TextStyle(
                            fontSize: size * 0.25,
                            height: 1.1,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                ),
              if (crossed && person == null)
                Icon(
                  Icons.close,
                  size: size * 0.5,
                  color: scheme.onSurfaceVariant,
                ),
              if (person != null)
                // Keyed by person and square: placing or moving someone
                // replays the drop; the final state never depends on it.
                TweenAnimationBuilder<double>(
                  key: ValueKey('$person@$index'),
                  tween: Tween(begin: 0, end: 1),
                  duration: Motion.of(context, Motion.place),
                  curve: Motion.land,
                  builder: (context, t, child) => Opacity(
                    opacity: t.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -(1 - t) * size * 0.3),
                      child: Transform.scale(
                        scale: 0.85 + 0.15 * t,
                        child: child,
                      ),
                    ),
                  ),
                  child: SuspectAvatar(
                    rosterIndex: p.cast[person],
                    size: size * 0.7,
                    isVictim: person == p.victim,
                    ring: ring,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevealPainter extends CustomPainter {
  _RevealPainter({
    required this.board,
    required this.room,
    required this.t,
    required this.dim,
    required this.outline,
  });

  final Board board;
  final int room;
  final double t;
  final Color dim;
  final Color outline;

  @override
  void paint(Canvas canvas, Size size) {
    final n = board.size;
    final cell = size.width / n;
    final shade = Paint()..color = dim.withValues(alpha: 0.72 * t);
    final line = Paint()
      ..color = outline.withValues(alpha: t)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.square;
    for (var i = 0; i < board.cellCount; i++) {
      final x = board.col(i) * cell, y = board.row(i) * cell;
      if (board.roomOf[i] != room) {
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), shade);
        continue;
      }
      // Outline the room: every side that borders another room or the edge.
      bool other(int r, int c) =>
          r < 0 || c < 0 || r >= n || c >= n || board.roomOf[r * n + c] != room;
      final r = board.row(i), c = board.col(i);
      if (other(r - 1, c)) {
        canvas.drawLine(Offset(x, y), Offset(x + cell, y), line);
      }
      if (other(r + 1, c)) {
        canvas.drawLine(Offset(x, y + cell), Offset(x + cell, y + cell), line);
      }
      if (other(r, c - 1)) {
        canvas.drawLine(Offset(x, y), Offset(x, y + cell), line);
      }
      if (other(r, c + 1)) {
        canvas.drawLine(Offset(x + cell, y), Offset(x + cell, y + cell), line);
      }
    }
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.t != t ||
      old.room != room ||
      old.dim != dim ||
      old.outline != outline;
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.colors,
    required this.shaded,
  });

  final Board board;
  final GameColors colors;
  final Set<int> shaded;

  @override
  void paint(Canvas canvas, Size size) {
    final n = board.size;
    final cell = size.width / n;
    Rect rect(int i) =>
        Rect.fromLTWH(board.col(i) * cell, board.row(i) * cell, cell, cell);

    for (var i = 0; i < board.cellCount; i++) {
      final tint = colors.roomTints[board.roomOf[i] % colors.roomTints.length];
      canvas.drawRect(rect(i), Paint()..color = tint);
      _paintFloor(canvas, rect(i), board.rooms[board.roomOf[i]], i);
      if (shaded.contains(i)) {
        canvas.drawRect(rect(i), Paint()..color = colors.takenShade);
      }
    }

    final thin = Paint()
      ..color = colors.gridLine
      ..strokeWidth = 1;
    for (var k = 1; k < n; k++) {
      canvas.drawLine(Offset(k * cell, 0), Offset(k * cell, size.height), thin);
      canvas.drawLine(Offset(0, k * cell), Offset(size.width, k * cell), thin);
    }

    final wall = Paint()
      ..color = colors.wall
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.square;
    for (var i = 0; i < board.cellCount; i++) {
      final r = board.row(i), c = board.col(i);
      final x = c * cell, y = r * cell;
      if (c < n - 1 && board.roomOf[i] != board.roomOf[i + 1]) {
        canvas.drawLine(Offset(x + cell, y), Offset(x + cell, y + cell), wall);
      }
      if (r < n - 1 && board.roomOf[i] != board.roomOf[i + n]) {
        canvas.drawLine(Offset(x, y + cell), Offset(x + cell, y + cell), wall);
      }
    }
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = colors.wall
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  /// Decorative floor per room kind: a second cue besides the tint, kept
  /// faint (colors.pattern) so furniture and people keep their contrast.
  void _paintFloor(Canvas canvas, Rect r, RoomKind kind, int index) {
    final ink = Paint()
      ..color = colors.pattern
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final w = r.width;
    Offset at(double x, double y) => Offset(r.left + x * w, r.top + y * w);
    canvas.save();
    canvas.clipRect(r);
    switch (kind) {
      case RoomKind.kitchen || RoomKind.bathroom:
        // Tiles: 2×2 per square.
        canvas.drawLine(at(0.5, 0), at(0.5, 1), ink);
        canvas.drawLine(at(0, 0.5), at(1, 0.5), ink);
      case RoomKind.library ||
          RoomKind.study ||
          RoomKind.lounge ||
          RoomKind.dining:
        // Wooden planks with staggered joints.
        final shift = board.row(index).isEven ? 0.0 : 0.5;
        for (final y in [1 / 3, 2 / 3]) {
          canvas.drawLine(at(0, y), at(1, y), ink);
        }
        for (var k = 0; k < 3; k++) {
          final x = (0.25 + shift + k * 0.5) % 1;
          canvas.drawLine(at(x, k / 3), at(x, (k + 1) / 3), ink);
        }
      case RoomKind.bedroom:
        // Carpet: a fine grid of dots.
        final dot = Paint()..color = colors.pattern;
        for (var y = 0; y < 4; y++) {
          for (var x = 0; x < 4; x++) {
            canvas.drawCircle(at((x + 0.5) / 4, (y + 0.5) / 4), 1, dot);
          }
        }
      case RoomKind.garden:
        // Grass tufts at fixed spots that vary per square.
        const spots = [
          (0.2, 0.3),
          (0.65, 0.2),
          (0.45, 0.65),
          (0.8, 0.8),
          (0.15, 0.85),
        ];
        for (var k = 0; k < spots.length; k++) {
          if ((index + k) % 3 == 0) continue;
          final (x, y) = spots[k];
          canvas.drawLine(at(x, y), at(x - 0.05, y - 0.1), ink);
          canvas.drawLine(at(x, y), at(x + 0.05, y - 0.1), ink);
        }
      case RoomKind.cellar:
        // Stone blocks: two courses, offset joints.
        canvas.drawLine(at(0, 0.5), at(1, 0.5), ink);
        canvas.drawLine(at(0.35, 0), at(0.35, 0.5), ink);
        canvas.drawLine(at(0.75, 0.5), at(0.75, 1), ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.colors != colors ||
      old.board != board ||
      old.shaded.length != shaded.length ||
      !old.shaded.containsAll(shaded);
}

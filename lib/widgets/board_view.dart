import 'package:material_ui/material_ui.dart';

import '../core/strings.dart';
import '../game/game_controller.dart';
import '../game/model.dart';
import '../theme/app_theme.dart';
import 'suspect_avatar.dart';

IconData furnitureIcon(Furniture f) => switch (f) {
  Furniture.chair => Icons.chair,
  Furniture.rug => Icons.texture,
  Furniture.table => Icons.table_restaurant,
  Furniture.plant => Icons.local_florist,
  Furniture.shelf => Icons.shelves,
  Furniture.none => Icons.crop_square,
};

/// The house map with row/column labels. Rebuilds from [controller].
class BoardView extends StatelessWidget {
  const BoardView({
    super.key,
    required this.controller,
    required this.strings,
    required this.onTap,
  });

  final GameController controller;
  final Strings strings;
  final void Function(int cell) onTap;

  static const _label = 22.0;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final b = c.board;
    final n = b.size;
    final game = context.game;
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(context).textTheme.labelMedium
        ?.copyWith(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600);
    final conflicts = c.conflicts;
    final takenRows = c.takenRows, takenCols = c.takenCols;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return LayoutBuilder(
      builder: (context, box) {
        final side = box.maxWidth.clamp(0.0, 520.0);
        final cell = (side - _label) / n;
        return SizedBox(
          width: side,
          height: side,
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
                            reduceMotion: reduceMotion,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    required this.reduceMotion,
    required this.onTap,
  });

  final int index;
  final double size;
  final GameController controller;
  final Strings strings;
  final bool conflict;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final b = c.board;
    final p = c.puzzle;
    final f = b.furniture[index];
    final person = c.personAt(index);
    final scheme = Theme.of(context).colorScheme;
    final game = context.game;
    final crossed = c.crosses.contains(index);

    Color? ring;
    if (person != null) {
      if (conflict) {
        ring = scheme.error;
      } else if (c.selected == person) {
        ring = scheme.secondary;
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
              if (f.blocks)
                Icon(
                  furnitureIcon(f),
                  size: size * 0.52,
                  color: game.blockedIcon,
                ),
              if (f == Furniture.chair)
                Align(
                  alignment: person == null
                      ? Alignment.center
                      : Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(person == null ? 0 : size * 0.04),
                    child: Icon(
                      Icons.chair,
                      size: person == null ? size * 0.42 : size * 0.28,
                      color: game.seat,
                    ),
                  ),
                ),
              if (crossed && person == null)
                Icon(
                  Icons.close,
                  size: size * 0.5,
                  color: scheme.onSurfaceVariant,
                ),
              AnimatedScale(
                scale: person == null ? 0 : 1,
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: person == null
                    ? SizedBox.square(dimension: size * 0.7)
                    : SuspectAvatar(
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
      if (board.furniture[i] == Furniture.rug) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect(i).deflate(cell * 0.1),
            Radius.circular(cell * 0.12),
          ),
          Paint()..color = colors.rug,
        );
      }
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

  @override
  bool shouldRepaint(_BoardPainter old) =>
      old.colors != colors ||
      old.board != board ||
      old.shaded.length != shaded.length ||
      !old.shaded.containsAll(shaded);
}

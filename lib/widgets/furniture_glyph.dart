import 'package:material_ui/material_ui.dart';

import '../game/model.dart';
import '../theme/app_theme.dart';

/// Hand-drawn, flat furniture (top-down, except the bookshelf seen from the
/// front). One style for all pieces, per UI UX Pro Max: soft fill + a 2px
/// outline, no shadows or gradients. Obstacles use grey ink; pieces people
/// can stand on (chairs, rugs) use the warm seat ink.
class FurnitureGlyph extends StatelessWidget {
  const FurnitureGlyph(this.furniture, {super.key, required this.size});

  final Furniture furniture;
  final double size;

  @override
  Widget build(BuildContext context) {
    final game = context.game;
    final ink = furniture.isSeat ? game.seat : game.blockedIcon;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: FurniturePainter(furniture, ink: ink),
      ),
    );
  }
}

class FurniturePainter extends CustomPainter {
  FurniturePainter(this.furniture, {required this.ink});

  final Furniture furniture;
  final Color ink;

  /// Same outline width for every piece and every size.
  static const stroke = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.translate((size.width - s) / 2, (size.height - s) / 2);
    Offset p(double x, double y) => Offset(x * s, y * s);
    Rect r(double l, double t, double rr, double b) =>
        Rect.fromLTRB(l * s, t * s, rr * s, b * s);

    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = ink.withValues(alpha: 0.2);

    void shape(Path path) {
      canvas.drawPath(path, fill);
      canvas.drawPath(path, line);
    }

    switch (furniture) {
      case Furniture.table:
        // Tabletop with its edge, plus a plate-like centre.
        final top = RRect.fromRectAndRadius(
          r(0.14, 0.24, 0.86, 0.76),
          Radius.circular(s * 0.08),
        );
        shape(Path()..addRRect(top));
        canvas.drawRRect(top.deflate(s * 0.08), line);
      case Furniture.plant:
        // Leaves around a round pot, seen from above.
        for (var i = 0; i < 6; i++) {
          canvas.save();
          canvas.translate(s / 2, s / 2);
          canvas.rotate(i * 3.14159 / 3);
          shape(
            Path()..addOval(
              Rect.fromCenter(
                center: Offset(0, -s * 0.22),
                width: s * 0.2,
                height: s * 0.34,
              ),
            ),
          );
          canvas.restore();
        }
        shape(
          Path()
            ..addOval(Rect.fromCircle(center: p(0.5, 0.5), radius: s * 0.13)),
        );
      case Furniture.shelf:
        // Bookcase from the front: frame, two shelves, books.
        final frame = r(0.2, 0.1, 0.8, 0.9);
        shape(Path()..addRect(frame));
        for (final y in [0.37, 0.63]) {
          canvas.drawLine(p(0.2, y), p(0.8, y), line);
        }
        for (final (top, bottom) in [(0.1, 0.37), (0.37, 0.63), (0.63, 0.9)]) {
          for (final x in [0.33, 0.45, 0.62]) {
            canvas.drawLine(p(x, top + 0.06), p(x, bottom - 0.04), line);
          }
        }
      case Furniture.chair:
        // Seat with a backrest, from above.
        shape(
          Path()..addRRect(
            RRect.fromRectAndRadius(
              r(0.28, 0.36, 0.72, 0.8),
              Radius.circular(s * 0.06),
            ),
          ),
        );
        shape(
          Path()..addRRect(
            RRect.fromRectAndRadius(
              r(0.24, 0.2, 0.76, 0.32),
              Radius.circular(s * 0.05),
            ),
          ),
        );
      case Furniture.rug:
        // Rug with an inner border and fringes on both ends.
        final rug = RRect.fromRectAndRadius(
          r(0.16, 0.12, 0.84, 0.88),
          Radius.circular(s * 0.05),
        );
        shape(Path()..addRRect(rug));
        canvas.drawRRect(rug.deflate(s * 0.1), line);
        for (final x in [0.3, 0.43, 0.57, 0.7]) {
          canvas.drawLine(p(x, 0.04), p(x, 0.12), line);
          canvas.drawLine(p(x, 0.88), p(x, 0.96), line);
        }
      case Furniture.none:
        break;
    }
  }

  @override
  bool shouldRepaint(FurniturePainter old) =>
      old.furniture != furniture || old.ink != ink;
}

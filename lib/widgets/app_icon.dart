import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

// The app icon artwork, shared by the About screen and
// tool/branding/render_icons_test.dart (which renders the launcher PNGs).

const iconGreen = Color(0xFF15803D);
const _paper = Color(0xFFFDFBF7);
const _ink = Color(0xFF1A1A1A);
const _gold = Color(0xFFF59E0B);
const _goldDark = Color(0xFFB45309);

/// The icon artwork in a 1024 square. [mono]: one colour (alpha only),
/// for Android themed icons. [scale] shrinks the art around the centre so
/// adaptive-icon foregrounds stay inside the safe circle (66dp of 108dp;
/// the handle tip is the farthest point, hence 0.62).
void paintAppIconArt(Canvas c, {bool mono = false, double scale = 1}) {
  Color k(Color col) => mono ? Colors.white : col;
  c.save();
  c.translate(512, 512);
  c.scale(scale);
  c.translate(-512, -512);

  // The house plan: a sheet of paper with a 4×4 grid and three rooms.
  final plan = RRect.fromLTRBR(196, 196, 724, 724, const Radius.circular(36));
  // Monochrome (themed icons): outlines only, so the shapes stay readable.
  if (!mono) c.drawRRect(plan, Paint()..color = _paper);
  if (!mono) {
    final grid = Paint()
      ..color = _ink.withValues(alpha: 0.18)
      ..strokeWidth = 6;
    for (var i = 1; i < 4; i++) {
      final d = 196 + i * 132.0;
      c.drawLine(Offset(d, 196), Offset(d, 724), grid);
      c.drawLine(Offset(196, d), Offset(724, d), grid);
    }
  }
  final wall = Paint()
    ..color = k(_ink)
    ..style = PaintingStyle.stroke
    ..strokeWidth = mono ? 34 : 22
    ..strokeCap = StrokeCap.square;
  c.drawRRect(plan, wall);
  c.drawLine(const Offset(460, 196), const Offset(460, 460), wall);
  c.drawLine(const Offset(196, 460), const Offset(724, 460), wall);
  // A suspect token on one square.
  c.drawCircle(const Offset(328, 328), 46, Paint()..color = k(_goldDark));

  // Magnifying glass over the plan.
  final lensCentre = const Offset(600, 600);
  // The lens: tinted glass; in monochrome it clears what's under it, so the
  // ring reads on its own.
  c.drawCircle(
    lensCentre,
    170,
    mono
        ? (Paint()..blendMode = BlendMode.clear)
        : (Paint()..color = _gold.withValues(alpha: 0.18)),
  );
  c.drawCircle(
    lensCentre,
    170,
    Paint()
      ..color = k(_gold)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 54,
  );
  c.save();
  c.translate(lensCentre.dx, lensCentre.dy);
  c.rotate(math.pi / 4);
  c.drawRRect(
    RRect.fromLTRBR(170, -40, 400, 40, const Radius.circular(40)),
    Paint()..color = k(_gold),
  );
  c.restore();
  c.restore();
}

/// The full icon (green square, art at 0.9) at [size] logical pixels.
class AppIcon extends StatelessWidget {
  const AppIcon({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.22),
    child: CustomPaint(size: Size.square(size), painter: _IconPainter()),
  );
}

class _IconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = iconGreen);
    canvas.scale(size.width / 1024);
    paintAppIconArt(canvas, scale: 0.9);
  }

  @override
  bool shouldRepaint(_IconPainter old) => false;
}

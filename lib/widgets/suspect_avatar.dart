import 'package:material_ui/material_ui.dart';

import '../game/model.dart';
import '../theme/app_theme.dart';

/// Shirt under the chest initial: the suspect color, darker, so white text
/// stays readable (checked in test/portrait_test.dart).
Color shirtColor(Color suspect) => Color.lerp(suspect, Colors.black, 0.35)!;

/// Smallest avatar size: the chest initial is 36% of it, so ≥ 12px text.
const minAvatarSize = 34.0;

/// Original flat portrait of a roster character, in their color, with their
/// initial on the chest so people are told apart by letter, not only by
/// drawing or color. Decorative for screen readers: the name is always next
/// to it or in the square's label. The victim gets a broken-heart badge.
class SuspectAvatar extends StatelessWidget {
  const SuspectAvatar({
    super.key,
    required this.rosterIndex,
    required this.size,
    this.isVictim = false,
    this.ring,
  });

  final int rosterIndex;
  final double size;
  final bool isVictim;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final colors = context.game.suspects;
    final fill = colors[rosterIndex % colors.length];
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: PortraitPainter(
                  rosterIndex: rosterIndex,
                  background: fill,
                  initialStyle: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: size * 0.36,
                    height: 1,
                  ),
                ),
              ),
            ),
            if (ring != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ring!, width: 3),
                  ),
                ),
              ),
            if (isVictim)
              Positioned(
                right: -size * 0.08,
                bottom: -size * 0.08,
                child: Container(
                  padding: EdgeInsets.all(size * 0.04),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.heart_broken,
                    size: size * 0.34,
                    color: scheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// How each character looks. Index = roster index.
enum _Hair { long, short, bun, curly, bob, bald, curls, hat }

class _Look {
  const _Look(
    this.skin,
    this.hairColor,
    this.hair, {
    this.glasses = false,
    this.beard = false,
    this.mustache = false,
    this.earrings = false,
  });
  final Color skin;
  final Color hairColor;
  final _Hair hair;
  final bool glasses;
  final bool beard;
  final bool mustache;
  final bool earrings;
}

const _looks = [
  // Abril: long auburn hair, earrings.
  _Look(Color(0xFFF2C9A5), Color(0xFF7A2E12), _Hair.long, earrings: true),
  // Bruno: short dark hair and a beard.
  _Look(Color(0xFFD9A47E), Color(0xFF2B1B12), _Hair.short, beard: true),
  // Carmen: black bun and glasses.
  _Look(Color(0xFFC68E63), Color(0xFF111111), _Hair.bun, glasses: true),
  // Darío: black curly hair and a moustache.
  _Look(Color(0xFF8D5A3B), Color(0xFF151010), _Hair.curly, mustache: true),
  // Elena: blonde bob.
  _Look(Color(0xFFF5D3B8), Color(0xFFE0B54A), _Hair.bob),
  // Félix: bald with grey sides and round glasses.
  _Look(Color(0xFFE8B996), Color(0xFFB8B8B8), _Hair.bald, glasses: true),
  // Greta: short silver curls, earrings.
  _Look(Color(0xFFF0C7AA), Color(0xFFD9D9DE), _Hair.curls, earrings: true),
  // Hugo: hat and stubble.
  _Look(Color(0xFF6B4329), Color(0xFF1F1F1F), _Hair.hat, beard: true),
];

/// Paints a portrait inside a circle in a 100×100 design space.
class PortraitPainter extends CustomPainter {
  PortraitPainter({
    required this.rosterIndex,
    required this.background,
    required this.initialStyle,
  });

  final int rosterIndex;
  final Color background;
  final TextStyle initialStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    final look = _looks[rosterIndex % _looks.length];
    final circle = Rect.fromLTWH(0, 0, size.shortestSide, size.shortestSide);
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    canvas.drawRect(circle, Paint()..color = background);
    canvas.scale(s);
    // Figure sits a little high so the chest has room for the initial.
    canvas.translate(0, -6);

    final skin = Paint()..color = look.skin;
    final hair = Paint()..color = look.hairColor;
    // Shirt: the suspect color, darker, so the initial reads in white.
    final shirt = Paint()..color = shirtColor(background);
    final ink = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Hair behind the head (long styles).
    switch (look.hair) {
      case _Hair.long:
        canvas.drawRRect(
          RRect.fromLTRBR(26, 22, 74, 72, const Radius.circular(20)),
          hair,
        );
      case _Hair.bob:
        canvas.drawRRect(
          RRect.fromLTRBR(27, 20, 73, 60, const Radius.circular(18)),
          hair,
        );
      case _Hair.bun:
        canvas.drawCircle(const Offset(50, 14), 10, hair);
      default:
        break;
    }

    // Neck, shoulders and shirt.
    canvas.drawRect(const Rect.fromLTRB(43, 52, 57, 66), skin);
    canvas.drawPath(
      Path()
        ..moveTo(8, 100)
        ..quadraticBezierTo(10, 64, 50, 62)
        ..quadraticBezierTo(90, 64, 92, 100)
        ..close(),
      shirt,
    );

    // Head.
    canvas.drawOval(const Rect.fromLTRB(32, 18, 68, 58), skin);

    // Hair on top.
    switch (look.hair) {
      case _Hair.long || _Hair.bob || _Hair.short || _Hair.bun:
        canvas.drawPath(
          Path()
            ..moveTo(31, 38)
            ..quadraticBezierTo(30, 14, 50, 14)
            ..quadraticBezierTo(70, 14, 69, 38)
            ..quadraticBezierTo(60, 24, 50, 25)
            ..quadraticBezierTo(38, 24, 31, 38)
            ..close(),
          hair,
        );
      case _Hair.curly || _Hair.curls:
        for (final (x, y) in [
          (36.0, 24.0),
          (44.0, 18.0),
          (52.0, 16.0),
          (60.0, 19.0),
          (66.0, 26.0),
          (32.0, 32.0),
          (68.0, 33.0),
        ]) {
          canvas.drawCircle(Offset(x, y), 7.5, hair);
        }
      case _Hair.bald:
        canvas.drawRRect(
          RRect.fromLTRBR(30, 30, 36, 44, const Radius.circular(3)),
          hair,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(64, 30, 70, 44, const Radius.circular(3)),
          hair,
        );
      case _Hair.hat:
        canvas.drawRRect(
          RRect.fromLTRBR(22, 24, 78, 30, const Radius.circular(3)),
          hair,
        );
        canvas.drawRRect(
          RRect.fromLTRBR(34, 8, 66, 27, const Radius.circular(6)),
          hair,
        );
    }

    // Face: eyes, then extras.
    final eye = Paint()..color = const Color(0xFF1A1A1A);
    canvas.drawCircle(const Offset(43, 39), 2.4, eye);
    canvas.drawCircle(const Offset(57, 39), 2.4, eye);
    if (look.glasses) {
      canvas.drawCircle(const Offset(43, 39), 6, ink);
      canvas.drawCircle(const Offset(57, 39), 6, ink);
      canvas.drawLine(const Offset(49, 39), const Offset(51, 39), ink);
    }
    if (look.beard) {
      canvas.drawPath(
        Path()
          ..moveTo(33, 42)
          ..quadraticBezierTo(34, 60, 50, 60)
          ..quadraticBezierTo(66, 60, 67, 42)
          ..quadraticBezierTo(60, 52, 50, 52)
          ..quadraticBezierTo(40, 52, 33, 42)
          ..close(),
        hair,
      );
    }
    if (look.mustache) {
      canvas.drawRRect(
        RRect.fromLTRBR(42, 46, 58, 50, const Radius.circular(2)),
        hair,
      );
    }
    if (look.earrings) {
      final gold = Paint()..color = const Color(0xFFF2C94C);
      canvas.drawCircle(const Offset(32, 46), 2.6, gold);
      canvas.drawCircle(const Offset(68, 46), 2.6, gold);
    }

    canvas.restore();

    // Initial on the chest, in real pixels (not scaled).
    final letter = TextPainter(
      text: TextSpan(text: roster[rosterIndex][0], style: initialStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final side = size.shortestSide;
    letter.paint(
      canvas,
      Offset((side - letter.width) / 2, side * 0.78 - letter.height / 2),
    );
  }

  @override
  bool shouldRepaint(PortraitPainter old) =>
      old.rosterIndex != rosterIndex ||
      old.background != background ||
      old.initialStyle != initialStyle;
}

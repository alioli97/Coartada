import 'package:material_ui/material_ui.dart';

import '../game/model.dart';
import '../theme/app_theme.dart';

/// Colored disc with the person's initial. The initial (not only the color)
/// tells people apart. The victim gets a broken-heart badge.
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
    final fill =
        context.game.suspects[rosterIndex % context.game.suspects.length];
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: ring == null ? null : Border.all(color: ring!, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(
              roster[rosterIndex][0],
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.46,
                height: 1,
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
    );
  }
}

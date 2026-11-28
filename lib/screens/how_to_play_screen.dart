import 'package:material_ui/material_ui.dart';

import '../core/strings.dart';
import '../game/model.dart';
import '../widgets/furniture_glyph.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({
    super.key,
    required this.strings,
    this.onPlayTutorial,
  });
  final Strings strings;

  /// Opens the guided case (from home; not offered mid-game).
  final VoidCallback? onPlayTutorial;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget symbol(IconData data) => Icon(data, color: scheme.primary);

    Widget section(String title, List<(Widget, String)> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: text.titleLarge)),
        const SizedBox(height: 8),
        for (final (icon, body) in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: SizedBox.square(dimension: 24, child: icon),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(body, style: text.bodyLarge)),
              ],
            ),
          ),
        const SizedBox(height: 20),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(s.howToPlay)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (onPlayTutorial != null) ...[
                  FilledButton.icon(
                    onPressed: onPlayTutorial,
                    icon: const Icon(Icons.school_outlined),
                    label: Text(s.tutorialPlay),
                  ),
                  const SizedBox(height: 20),
                ],
                section(s.rulesTitle, [
                  (symbol(Icons.grid_on), s.rule1),
                  (const FurnitureGlyph(Furniture.table, size: 24), s.rule2),
                  (symbol(Icons.fact_check_outlined), s.rule3),
                  (symbol(Icons.heart_broken_outlined), s.rule4),
                ]),
                section(s.controlsTitle, [
                  (symbol(Icons.touch_app_outlined), s.control1),
                  (symbol(Icons.close), s.control2),
                  (symbol(Icons.edit_outlined), s.controlNotes),
                  (symbol(Icons.strikethrough_s), s.control3),
                  (symbol(Icons.gavel), s.control4),
                ]),
                section(s.mapTitle, [
                  (symbol(Icons.explore_outlined), s.mapBody),
                ]),
                section(s.noTouchTitle, [
                  (symbol(Icons.social_distance), s.noTouchBody),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

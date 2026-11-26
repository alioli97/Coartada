import 'package:material_ui/material_ui.dart';

import '../core/strings.dart';
import '../game/model.dart';
import '../widgets/board_view.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key, required this.strings});
  final Strings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    Widget section(String title, List<(IconData, String)> items) => Column(
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
                ExcludeSemantics(child: Icon(icon, color: scheme.primary)),
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
                section(s.rulesTitle, [
                  (Icons.grid_on, s.rule1),
                  (furnitureIcon(Furniture.table), s.rule2),
                  (Icons.fact_check_outlined, s.rule3),
                  (Icons.heart_broken_outlined, s.rule4),
                ]),
                section(s.controlsTitle, [
                  (Icons.touch_app_outlined, s.control1),
                  (Icons.close, s.control2),
                  (Icons.strikethrough_s, s.control3),
                  (Icons.gavel, s.control4),
                ]),
                section(s.mapTitle, [(Icons.explore_outlined, s.mapBody)]),
                section(s.noTouchTitle, [
                  (Icons.social_distance, s.noTouchBody),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

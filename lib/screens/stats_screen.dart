import 'package:material_ui/material_ui.dart';

import '../core/app_state.dart';
import '../core/strings.dart';
import '../game/model.dart';

/// Daily streak and per-level statistics, for one variant at a time.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.appState, this.now});

  final AppState appState;

  /// Fixed date for tests; defaults to the real clock.
  final DateTime Function()? now;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Variant _variant = widget.appState.variant;

  @override
  Widget build(BuildContext context) {
    final s = widget.appState.s;
    final theme = Theme.of(context);
    final today = (widget.now ?? DateTime.now)();
    final streak = widget.appState.streak(today);
    // Same source as the home daily card, so both always agree.
    final solvedToday = widget.appState.dailySolved(today);
    final rows = widget.appState.allStats(_variant);
    final total = rows.fold(0, (sum, r) => sum + r.$2.solved);
    final noHints = rows.fold(0, (sum, r) => sum + r.$2.noHints);

    return Scaffold(
      appBar: AppBar(title: Text(s.stats)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _StreakCard(
                  strings: s,
                  streak: streak,
                  solvedToday: solvedToday,
                ),
                const SizedBox(height: 24),
                SegmentedButton<Variant>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: Variant.classic,
                      label: Text(s.classic),
                    ),
                    ButtonSegment(
                      value: Variant.noTouch,
                      label: Text(s.noTouchShort),
                    ),
                  ],
                  selected: {_variant},
                  onSelectionChanged: (v) =>
                      setState(() => _variant = v.single),
                ),
                // Empty state first, where it's seen at once.
                if (total == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      s.noneYet,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Tile(label: s.totalSolved, value: '$total'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _Tile(label: s.withoutHints, value: '$noHints'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final (level, st) in rows) ...[
                  _LevelCard(strings: s, level: level, stats: st),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.strings,
    required this.streak,
    required this.solvedToday,
  });
  final Strings strings;
  final Streak streak;
  final bool solvedToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _Big(
                    icon: Icons.local_fire_department,
                    color: scheme.secondary,
                    value: '${streak.current}',
                    label:
                        '${strings.currentStreak} · ${strings.days(streak.current)}',
                  ),
                ),
                Expanded(
                  child: _Big(
                    icon: Icons.emoji_events_outlined,
                    color: scheme.primary,
                    value: '${streak.best}',
                    label:
                        '${strings.bestStreak} · ${strings.days(streak.best)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  solvedToday
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: solvedToday ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    solvedToday ? strings.todayDone : strings.todayPending,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 6),
              Text(value, style: theme.textTheme.displaySmall),
            ],
          ),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: theme.textTheme.headlineSmall),
            Text(label, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.strings,
    required this.level,
    required this.stats,
  });
  final Strings strings;
  final Level level;
  final LevelStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = strings;
    final avg = stats.average;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s.levelName(level)} · ${level.size}×${level.size}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(label: s.solvedLabel, value: '${stats.solved}'),
                if (stats.bestSeconds != null)
                  _Pill(
                    label: s.bestLabel,
                    value: formatDuration(
                      Duration(seconds: stats.bestSeconds!),
                    ),
                  ),
                if (avg != null)
                  _Pill(label: s.averageLabel, value: formatDuration(avg)),
                if (stats.hintsPerCase case final h?)
                  _Pill(label: s.hintsPerCase, value: s.decimal(h)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$label '),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

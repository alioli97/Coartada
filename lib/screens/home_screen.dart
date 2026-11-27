import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../core/app_state.dart';
import '../core/strings.dart';
import '../game/game_controller.dart';
import '../game/generator.dart';
import '../game/model.dart';
import '../widgets/settings_sheet.dart';
import 'archive_screen.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.appState, this.now});

  final AppState appState;

  /// Fixed date for tests; defaults to the real clock.
  final DateTime Function()? now;

  void _open(BuildContext context, Puzzle puzzle, {bool daily = false}) => _go(
    context,
    GameScreen(appState: appState, puzzle: puzzle, daily: daily),
  );

  void _resume(BuildContext context) {
    final json = appState.savedGameJson;
    final game = json == null ? null : GameController.fromJson(json);
    if (game == null) {
      // Saved by an older version or corrupted: drop it.
      appState.clearSavedGame();
      appState.refresh();
      return;
    }
    _go(context, GameScreen.resume(appState: appState, controller: game));
  }

  /// The game screen saves progress without notifying, so the home screen
  /// refreshes (Continue card, stats) when it closes.
  Future<void> _go(BuildContext context, Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    appState.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = appState.s;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = (now ?? DateTime.now)();
    final dailyDone = appState.dailySolved(today);
    final saved = appState.savedGame;
    final dailySeed = AppState.dailySeed(today);
    final savedIsToday =
        saved != null && saved.daily && saved.seed == dailySeed;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Row(
                  children: [
                    Icon(Icons.search, size: 32, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Coartada',
                          style: theme.textTheme.displaySmall,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: s.stats,
                      icon: const Icon(Icons.bar_chart),
                      onPressed: () => _go(
                        context,
                        StatsScreen(appState: appState, now: now),
                      ),
                    ),
                    IconButton(
                      tooltip: s.howToPlay,
                      icon: const Icon(Icons.help_outline),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HowToPlayScreen(strings: s),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: s.settings,
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => showSettingsSheet(context, appState),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  s.tagline,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (saved != null) ...[
                  _ContinueCard(
                    strings: s,
                    info: saved,
                    onTap: () => _resume(context),
                  ),
                  const SizedBox(height: 12),
                ],
                _DailyCard(
                  strings: s,
                  done: dailyDone,
                  streak: appState.streak(today).current,
                  onTap: savedIsToday
                      ? () => _resume(context)
                      : () => _open(
                          context,
                          generatePuzzle(
                            level: Level.inspector,
                            seed: dailySeed,
                          ),
                          daily: true,
                        ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _go(
                      context,
                      ArchiveScreen(appState: appState, now: now),
                    ),
                    icon: const Icon(Icons.history),
                    label: Text(s.archive),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(s.newCase, style: theme.textTheme.titleLarge),
                ),
                const SizedBox(height: 12),
                for (final level in Level.values) ...[
                  _LevelTile(
                    level: level,
                    strings: s,
                    stats: appState.stats(level, appState.variant),
                    onTap: () => _open(
                      context,
                      generatePuzzle(
                        level: level,
                        seed: Random().nextInt(99999) + 1,
                        variant: appState.variant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                Card(
                  child: SwitchListTile(
                    value: appState.variant == Variant.noTouch,
                    onChanged: (on) => appState.variant = on
                        ? Variant.noTouch
                        : Variant.classic,
                    title: Text(s.noTouchTitle),
                    subtitle: Text(s.noTouchBody),
                    secondary: const Icon(Icons.social_distance),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.strings,
    required this.info,
    required this.onTap,
  });
  final Strings strings;
  final SavedGameInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = info.daily
        ? strings.dailyCase
        : '${strings.levelName(info.level)} · ${info.level.size}×${info.level.size}';
    final detail = [
      strings.placedOf(info.placed, info.people),
      formatDuration(info.elapsed),
      if (info.variant == Variant.noTouch) strings.noTouchTitle,
    ].join(' · ');
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.restore, color: scheme.primary, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.continueCase,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: info.people == 0 ? 0 : info.placed / info.people,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHigh,
                        semanticsLabel: strings.placedOf(
                          info.placed,
                          info.people,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      detail,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.play_arrow, color: scheme.primary, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({
    required this.strings,
    required this.done,
    required this.streak,
    required this.onTap,
  });
  final Strings strings;
  final bool done;
  final int streak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = scheme.onPrimary;
    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: fg, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.dailyCase,
                      style: theme.textTheme.titleLarge?.copyWith(color: fg),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (done)
                          strings.solvedToday
                        else
                          '${strings.levelName(Level.inspector)} · 6×6',
                        if (streak > 0) strings.streakLine(streak),
                      ].join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
              Icon(
                done ? Icons.check_circle : Icons.play_arrow,
                color: fg,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.level,
    required this.strings,
    required this.stats,
    required this.onTap,
  });
  final Level level;
  final Strings strings;
  final LevelStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final detail = [
      strings.solvedCount(stats.solved),
      if (stats.bestSeconds != null)
        strings.best(formatDuration(Duration(seconds: stats.bestSeconds!))),
    ].join(' · ');
    return Card(
      child: ListTile(
        minTileHeight: 64,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${level.size}×${level.size}',
            style: theme.textTheme.titleMedium,
          ),
        ),
        title: Text(
          strings.levelName(level),
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(detail),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

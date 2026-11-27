import 'package:material_ui/material_ui.dart';

import '../core/app_state.dart';
import '../game/game_controller.dart';
import '../game/generator.dart';
import '../game/model.dart';
import 'game_screen.dart';

/// The daily cases of the last 30 days, newest first. Solving one counts
/// in the statistics but not in the streak (only today's does).
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key, required this.appState, this.now});

  final AppState appState;

  /// Fixed date for tests; defaults to the real clock.
  final DateTime Function()? now;

  Future<void> _open(BuildContext context, int day) async {
    final saved = appState.savedGameJson;
    final info = appState.savedGame;
    final resume = info != null && info.daily && info.seed == day
        ? GameController.fromJson(saved!)
        : null;
    final screen = resume != null
        ? GameScreen.resume(appState: appState, controller: resume)
        : GameScreen(
            appState: appState,
            puzzle: generatePuzzle(level: Level.inspector, seed: day),
            daily: true,
          );
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    appState.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final today = (now ?? DateTime.now)();
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final s = appState.s;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final days = AppState.recentDays(today);
        final saved = appState.savedGame;
        return Scaffold(
          appBar: AppBar(title: Text(s.archive)),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: days.length + 1,
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          s.archiveIntro,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    final day = days[i - 1];
                    final date = AppState.dayOf(day);
                    final done = appState.dailyDone(day);
                    final going =
                        !done &&
                        saved != null &&
                        saved.daily &&
                        saved.seed == day;
                    final (icon, color, state) = done
                        ? (Icons.check_circle, scheme.primary, s.stateSolved)
                        : going
                        ? (Icons.timelapse, scheme.secondary, s.stateInProgress)
                        : (
                            Icons.radio_button_unchecked,
                            scheme.onSurfaceVariant,
                            s.stateNotPlayed,
                          );
                    final relative = i == 1
                        ? s.today
                        : i == 2
                        ? s.yesterday
                        : null;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        minTileHeight: 56,
                        leading: Icon(icon, color: color),
                        title: Text(relative ?? _cap(s.longDate(date))),
                        subtitle: Text(
                          relative == null
                              ? state
                              : '${_cap(s.longDate(date))} · $state',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(context, day),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static String _cap(String t) => t[0].toUpperCase() + t.substring(1);
}

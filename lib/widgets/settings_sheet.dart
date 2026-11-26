import 'package:material_ui/material_ui.dart';

import '../core/app_state.dart';
import '../core/strings.dart';

Future<void> showSettingsSheet(BuildContext context, AppState appState) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Taller than half the screen on small phones: let it grow and scroll.
    isScrollControlled: true,
    builder: (context) => ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final s = appState.s;
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.settings, style: text.headlineSmall),
                const SizedBox(height: 16),
                Text(s.language, style: text.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    for (final e in Strings.languages.entries)
                      ButtonSegment(value: e.key, label: Text(e.value)),
                  ],
                  selected: {appState.language},
                  onSelectionChanged: (v) => appState.language = v.single,
                ),
                const SizedBox(height: 20),
                Text(s.appearance, style: text.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(s.themeSystem),
                      icon: const Icon(Icons.brightness_auto),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(s.themeLight),
                      icon: const Icon(Icons.light_mode),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(s.themeDark),
                      icon: const Icon(Icons.dark_mode),
                    ),
                  ],
                  selected: {appState.themeMode},
                  onSelectionChanged: (v) => appState.themeMode = v.single,
                ),
                const SizedBox(height: 20),
                Text(s.gameSettings, style: text.titleMedium),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.vibration),
                  title: Text(s.haptics),
                  subtitle: Text(s.hapticsBody),
                  value: appState.haptics,
                  onChanged: (on) => appState.haptics = on,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.grid_on),
                  title: Text(s.visualHelp),
                  subtitle: Text(s.visualHelpBody),
                  value: appState.visualHelp,
                  onChanged: (on) => appState.visualHelp = on,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

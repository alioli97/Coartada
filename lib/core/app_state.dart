import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/model.dart';
import 'strings.dart';

/// App-wide settings and progress, stored on the device. Passed explicitly
/// to every screen (no Provider).
class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    final saved = _prefs.getString(_kLanguage);
    _language = Strings.languages.containsKey(saved) ? saved! : 'es';
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == _prefs.getString(_kTheme),
      orElse: () => ThemeMode.system,
    );
    _variant = _prefs.getBool(_kNoTouch) ?? false
        ? Variant.noTouch
        : Variant.classic;
    final raw = _prefs.getString(_kStats);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      map.forEach(
        (k, v) => _stats[k] = LevelStats.fromJson(v as Map<String, dynamic>),
      );
    }
  }

  static const _kLanguage = 'language_code';
  static const _kTheme = 'theme_mode';
  static const _kNoTouch = 'variant_no_touch';
  static const _kStats = 'stats';
  static const _kDaily = 'daily_solved';
  static const _kSavedGame = 'saved_game';
  static const _kHaptics = 'haptics';
  static const _kVisualHelp = 'visual_help';

  final SharedPreferences _prefs;
  late String _language;
  late ThemeMode _themeMode;
  late Variant _variant;
  final Map<String, LevelStats> _stats = {};

  String get language => _language;
  Strings get s => Strings(_language);
  ThemeMode get themeMode => _themeMode;
  Variant get variant => _variant;

  set language(String code) {
    _language = code;
    _prefs.setString(_kLanguage, code);
    notifyListeners();
  }

  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    _prefs.setString(_kTheme, mode.name);
    notifyListeners();
  }

  /// Vibration on check, accusation and hint. On by default.
  bool get haptics => _prefs.getBool(_kHaptics) ?? true;
  set haptics(bool on) {
    _prefs.setBool(_kHaptics, on);
    notifyListeners();
  }

  /// Board aids: shading of taken rows/columns and rings on people who
  /// clash. On by default; off for a harder game.
  bool get visualHelp => _prefs.getBool(_kVisualHelp) ?? true;
  set visualHelp(bool on) {
    _prefs.setBool(_kVisualHelp, on);
    notifyListeners();
  }

  set variant(Variant v) {
    _variant = v;
    _prefs.setBool(_kNoTouch, v == Variant.noTouch);
    notifyListeners();
  }

  /// The one game in progress, if any (see `GameController.toJson`).
  Map<String, dynamic>? get savedGameJson {
    final raw = _prefs.getString(_kSavedGame);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Summary for the home "Continue" card, read without regenerating the case.
  SavedGameInfo? get savedGame {
    final j = savedGameJson;
    if (j == null) return null;
    try {
      return SavedGameInfo(
        level: Level.values.byName(j['level'] as String),
        variant: Variant.values.byName(j['variant'] as String),
        seed: j['seed'] as int,
        daily: j['daily'] as bool,
        placed: (j['placement'] as List).where((c) => c != null).length,
        people: (j['placement'] as List).length,
        elapsed: Duration(milliseconds: j['elapsedMs'] as int),
      );
    } catch (_) {
      return null;
    }
  }

  /// Saves without notifying: it runs on every move, and the home screen
  /// refreshes with [refresh] when the game screen closes.
  void saveGame(Map<String, dynamic> json) =>
      _prefs.setString(_kSavedGame, jsonEncode(json));

  void clearSavedGame() => _prefs.remove(_kSavedGame);

  /// Rebuilds listeners after changes made without notifying.
  void refresh() => notifyListeners();

  static String statsKey(Level l, Variant v) => '${l.name}_${v.name}';

  LevelStats stats(Level l, Variant v) =>
      _stats[statsKey(l, v)] ?? const LevelStats();

  /// Seed for today's case: the same for everyone on the same date.
  static int dailySeed(DateTime now) =>
      now.year * 10000 + now.month * 100 + now.day;

  bool dailySolved(DateTime now) => _prefs.getInt(_kDaily) == dailySeed(now);

  void recordSolved(Puzzle p, Duration time, {required bool daily}) {
    final key = statsKey(p.level, p.board.variant);
    final old = stats(p.level, p.board.variant);
    final secs = time.inSeconds;
    _stats[key] = LevelStats(
      solved: old.solved + 1,
      bestSeconds: old.bestSeconds == null || secs < old.bestSeconds!
          ? secs
          : old.bestSeconds,
    );
    _prefs.setString(
      _kStats,
      jsonEncode(_stats.map((k, v) => MapEntry(k, v.toJson()))),
    );
    if (daily) _prefs.setInt(_kDaily, p.seed);
    notifyListeners();
  }
}

class SavedGameInfo {
  const SavedGameInfo({
    required this.level,
    required this.variant,
    required this.seed,
    required this.daily,
    required this.placed,
    required this.people,
    required this.elapsed,
  });

  final Level level;
  final Variant variant;
  final int seed;
  final bool daily;
  final int placed;
  final int people;
  final Duration elapsed;
}

class LevelStats {
  const LevelStats({this.solved = 0, this.bestSeconds});
  factory LevelStats.fromJson(Map<String, dynamic> j) => LevelStats(
    solved: j['solved'] as int? ?? 0,
    bestSeconds: j['best'] as int?,
  );

  final int solved;
  final int? bestSeconds;

  Map<String, dynamic> toJson() => {'solved': solved, 'best': bestSeconds};
}

String formatDuration(Duration d) {
  final m = d.inMinutes, s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

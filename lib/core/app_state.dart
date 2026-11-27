import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/game_controller.dart';
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
  static const _kDailyDone = 'daily_done';
  static const _kSavedGame = 'saved_game';
  static const _kStreak = 'daily_streak';
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
    // A save from another version can't be resumed: don't offer it.
    if (j == null || j['v'] != GameController.saveVersion) return null;
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

  bool dailySolved(DateTime now) => dailyDone(dailySeed(now));

  /// Whether the daily case of [day] (yyyymmdd) was ever solved. Older
  /// versions only kept the last one (`daily_solved`).
  bool dailyDone(int day) =>
      _prefs.getInt(_kDaily) == day ||
      (_prefs.getStringList(_kDailyDone)?.contains('$day') ?? false);

  /// The last [count] days, newest (today) first, as yyyymmdd.
  static List<int> recentDays(DateTime now, {int count = 30}) => [
    for (var i = 0; i < count; i++)
      dailySeed(DateTime(now.year, now.month, now.day - i)),
  ];

  /// The date of a daily case's seed (yyyymmdd).
  static DateTime dayOf(int seed) =>
      DateTime(seed ~/ 10000, seed ~/ 100 % 100, seed % 100);

  void recordSolved(
    Puzzle p,
    Duration time, {
    required bool daily,
    int hints = 0,
    DateTime? now,
  }) {
    final key = statsKey(p.level, p.board.variant);
    final old = stats(p.level, p.board.variant);
    final secs = time.inSeconds;
    _stats[key] = LevelStats(
      solved: old.solved + 1,
      bestSeconds: old.bestSeconds == null || secs < old.bestSeconds!
          ? secs
          : old.bestSeconds,
      totalSeconds: old.totalSeconds + secs,
      totalHints: old.totalHints + hints,
      noHints: old.noHints + (hints == 0 ? 1 : 0),
      tracked: old.tracked + 1,
    );
    _prefs.setString(
      _kStats,
      jsonEncode(_stats.map((k, v) => MapEntry(k, v.toJson()))),
    );
    if (daily) {
      _prefs.setInt(_kDaily, p.seed);
      final done = {...?_prefs.getStringList(_kDailyDone), '${p.seed}'};
      _prefs.setStringList(_kDailyDone, done.toList()..sort());
      // Only today's case on its own day counts for the streak.
      if (p.seed == dailySeed(now ?? DateTime.now())) _extendStreak(p.seed);
    }
    notifyListeners();
  }

  /// Days in a row with the daily case solved.
  Streak streak(DateTime now) {
    final raw = _prefs.getString(_kStreak);
    if (raw == null) return const Streak();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final last = j['last'] as int, current = j['current'] as int;
      final today = dailySeed(now), yesterday = _dayBefore(today);
      // Broken once a whole day passes without solving.
      final alive = last == today || last == yesterday;
      return Streak(
        current: alive ? current : 0,
        best: j['best'] as int,
        solvedToday: last == today,
      );
    } catch (_) {
      return const Streak();
    }
  }

  void _extendStreak(int day) {
    var (last, current, best) = (0, 0, 0);
    final raw = _prefs.getString(_kStreak);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        (last, current, best) = (
          j['last'] as int,
          j['current'] as int,
          j['best'] as int,
        );
      } catch (_) {}
    }
    if (last == day) return;
    current = last == _dayBefore(day) ? current + 1 : 1;
    if (current > best) best = current;
    _prefs.setString(
      _kStreak,
      jsonEncode({'last': day, 'current': current, 'best': best}),
    );
  }

  /// yyyymmdd of the day before [day] (also yyyymmdd).
  static int _dayBefore(int day) =>
      dailySeed(DateTime(day ~/ 10000, day ~/ 100 % 100, day % 100 - 1));

  /// Stats of every level for [v], in level order.
  List<(Level, LevelStats)> allStats(Variant v) => [
    for (final l in Level.values) (l, stats(l, v)),
  ];
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

class Streak {
  const Streak({this.current = 0, this.best = 0, this.solvedToday = false});
  final int current;
  final int best;
  final bool solvedToday;
}

class LevelStats {
  const LevelStats({
    this.solved = 0,
    this.bestSeconds,
    this.totalSeconds = 0,
    this.totalHints = 0,
    this.noHints = 0,
    this.tracked = 0,
  });
  factory LevelStats.fromJson(Map<String, dynamic> j) => LevelStats(
    solved: j['solved'] as int? ?? 0,
    bestSeconds: j['best'] as int?,
    // Optional: stats saved before these were tracked.
    totalSeconds: j['total'] as int? ?? 0,
    totalHints: j['hints'] as int? ?? 0,
    noHints: j['noHints'] as int? ?? 0,
    tracked: j['tracked'] as int? ?? 0,
  );

  final int solved;
  final int? bestSeconds;
  final int totalSeconds;
  final int totalHints;

  /// Cases solved without any hint.
  final int noHints;

  /// Solves with time and hints recorded (older ones only kept the count),
  /// the base for [average] and [hintsPerCase].
  final int tracked;

  Duration? get average =>
      tracked == 0 ? null : Duration(seconds: (totalSeconds / tracked).round());

  double? get hintsPerCase => tracked == 0 ? null : totalHints / tracked;

  Map<String, dynamic> toJson() => {
    'solved': solved,
    'best': bestSeconds,
    'total': totalSeconds,
    'hints': totalHints,
    'noHints': noHints,
    'tracked': tracked,
  };
}

String formatDuration(Duration d) {
  final m = d.inMinutes, s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

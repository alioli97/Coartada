// Raw captures of the real screens for the store screenshots, rendered with
// sample progress. The marketing frames (headline, device, background) are
// made in store/screenshots-editor (App Store Screenshots skill) from these.
//
// Not part of CI (lives outside test/). Regenerate with:
//   flutter test store/screenshots/captures_test.dart
// Output (opaque PNG, no alpha):
//   store/screenshots-editor/public/screenshots/apple/iphone/{es,ca,en}/0N.png
//     1320×2868, 6.9" iPhone, with the iPhone's safe area;
//   store/screenshots-editor/public/screenshots/android/phone/{es,ca,en}/0N.png
//     1080×2340, the 9:19.5 screen of the editor's Android frame.
//
// The bundled app fonts and the Material icons are loaded by hand (tests
// render text with a placeholder font otherwise).

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:coartada/core/app_state.dart';
import 'package:coartada/game/deducer.dart';
import 'package:coartada/game/game_controller.dart';
import 'package:coartada/game/generator.dart';
import 'package:coartada/game/model.dart';
import 'package:coartada/screens/game_screen.dart';
import 'package:coartada/screens/home_screen.dart';
import 'package:coartada/screens/stats_screen.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _out = 'store/screenshots-editor/public/screenshots';
final _today = DateTime(2026, 11, 28);
final _day = AppState.dailySeed(_today);

class _Target {
  const _Target(this.dir, this.logical, this.padding, this.platform);
  final String dir;
  final Size logical;
  final EdgeInsets padding;
  final TargetPlatform platform;
}

const _targets = [
  // 6.9" iPhone: 440×956 pt; Dynamic Island and home indicator insets.
  _Target(
    'apple/iphone',
    Size(440, 956),
    EdgeInsets.only(top: 62, bottom: 34),
    TargetPlatform.iOS,
  ),
  // Android phone, 9:19.5; status and gesture bars.
  _Target(
    'android/phone',
    Size(360, 780),
    EdgeInsets.only(top: 28, bottom: 16),
    TargetPlatform.android,
  ),
];

Future<void> _loadFonts() async {
  Future<ByteData> file(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());
  await (FontLoader('PlayfairDisplay')
        ..addFont(file('assets/fonts/PlayfairDisplay-Bold.ttf'))
        ..addFont(file('assets/fonts/PlayfairDisplay-ExtraBold.ttf')))
      .load();
  await (FontLoader('SourceSerif4')
        ..addFont(file('assets/fonts/SourceSerif4-Regular.ttf'))
        ..addFont(file('assets/fonts/SourceSerif4-SemiBold.ttf')))
      .load();
  // The Material icons live in the SDK cache, next to flutter_tester.
  Directory? fonts;
  for (
    var d = File(Platform.resolvedExecutable).parent;
    d.parent.path != d.path && fonts == null;
    d = d.parent
  ) {
    for (final sub in ['material_fonts', 'artifacts/material_fonts']) {
      final c = Directory('${d.path}/$sub');
      if (c.existsSync()) fonts = c;
    }
  }
  if (fonts == null) throw StateError('Material fonts not found in the SDK');
  await (FontLoader(
    'MaterialIcons',
  )..addFont(file('${fonts.path}/MaterialIcons-Regular.otf'))).load();
}

/// A player with a few weeks of history: stats, a streak, today's case in
/// progress, the guided case done.
Future<AppState> _app(String lang, {Map<String, Object> extra = const {}}) {
  final stats = {
    'apprentice_classic': _stats(14, 58, 1610, 3),
    'detective_classic': _stats(11, 101, 2380, 5),
    'inspector_classic': _stats(23, 187, 6420, 9),
    'commissioner_classic': _stats(6, 312, 2650, 4),
    'legend_classic': _stats(2, 611, 1490, 2),
  };
  // ignore: invalid_use_of_visible_for_testing_member (a test outside test/)
  SharedPreferences.setMockInitialValues({
    'language_code': lang,
    'tutorial_done': true,
    'stats': jsonEncode(stats),
    'daily_streak': jsonEncode({
      'last': AppState.dailySeed(_today.subtract(const Duration(days: 1))),
      'current': 6,
      'best': 12,
    }),
    'daily_done': [
      for (final d in AppState.recentDays(_today).skip(1).take(6)) '$d',
    ],
    ...extra,
  });
  return SharedPreferences.getInstance().then(AppState.new);
}

Map<String, dynamic> _stats(int solved, int best, int total, int hints) => {
  'solved': solved,
  'best': best,
  'total': total,
  'hints': hints,
  'noHints': solved - hints,
  'tracked': solved,
};

/// Today's case with the first [placed] deductions done, as a player would.
GameController _dailyGame(int placed, {int seconds = 252}) {
  final p = generatePuzzle(level: Level.inspector, seed: _day);
  final g = GameController(p, daily: true, elapsed: Duration(seconds: seconds));
  for (var i = 0; i < placed; i++) {
    final known = {
      for (var q = 0; q < p.people; q++)
        if (g.placement[q] != null) q: g.placement[q]!,
    };
    final d = Deducer(p, known: known).next();
    if (d == null) break;
    g.placement[d.person] = d.cell;
  }
  // A few squares ruled out and a pencil note, like a real game.
  final free = [
    for (var c = 0; c < p.board.cellCount; c++)
      if (g.personAt(c) == null &&
          !g.takenRows.contains(p.board.row(c)) &&
          !g.takenCols.contains(p.board.col(c)))
        c,
  ];
  final unplaced = [
    for (var q = 0; q < p.people; q++)
      if (g.placement[q] == null) q,
  ];
  for (final c in free.take(3)) {
    if (c != p.solution[unplaced.first]) g.crosses.add(c);
  }
  g.notes[p.solution[unplaced.last]] = {unplaced.last, unplaced.first};
  g.select(unplaced.first);
  return g;
}

Future<void> _capture(
  WidgetTester tester,
  _Target t,
  String lang,
  String name,
  Widget Function(AppState app) build, {
  Map<String, Object> prefs = const {},
  Future<void> Function(WidgetTester tester, AppState app)? act,
}) async {
  final app = await _app(lang, extra: prefs);
  debugDefaultTargetPlatformOverride = t.platform;
  tester.view.physicalSize = t.logical * 3;
  tester.view.devicePixelRatio = 3;
  tester.view.padding = FakeViewPadding(
    top: t.padding.top * 3,
    bottom: t.padding.bottom * 3,
  );
  final key = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        key: UniqueKey(),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: build(app),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (act != null) await act(tester, app);
  await tester.pumpAndSettle();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    // Opaque RGB PNG: the stores reject transparency.
    final rgba = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: bytes!.buffer,
      numChannels: 4,
    );
    final rgb = img.Image(width: rgba.width, height: rgba.height);
    img.compositeImage(rgb, rgba);
    final file = File('$_out/${t.dir}/$lang/$name.png')
      ..createSync(recursive: true);
    file.writeAsBytesSync(img.encodePng(rgb));
  });
  debugDefaultTargetPlatformOverride = null;
}

void main() {
  setUpAll(_loadFonts);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  for (final t in _targets) {
    for (final lang in ['es', 'ca', 'en']) {
      testWidgets('${t.dir} $lang', (tester) async {
        addTearDown(tester.view.reset);

        // 01: today's case in progress (the hero).
        await _capture(
          tester,
          t,
          lang,
          '01',
          (app) => GameScreen.resume(appState: app, controller: _dailyGame(3)),
        );

        // 02: a hint that explains the next deduction.
        await _capture(tester, t, lang, '02', (app) {
          final g = _dailyGame(2, seconds: 191)..select(null);
          g.hint();
          return GameScreen.resume(appState: app, controller: g);
        });

        // 03: home, with the streak and the case in progress.
        final saved = _dailyGame(3).toJson();
        await _capture(
          tester,
          t,
          lang,
          '03',
          (app) => HomeScreen(appState: app, now: () => _today),
          prefs: {'saved_game': jsonEncode(saved)},
        );

        // 04: case closed (the culprit named, the crime scene revealed).
        await _capture(
          tester,
          t,
          lang,
          '04',
          (app) {
            final g = _dailyGame(0, seconds: 0);
            final p = g.puzzle;
            for (var q = 0; q < p.people; q++) {
              g.placement[q] = p.solution[q];
            }
            return GameScreen.resume(
              appState: app,
              controller: GameController.fromJson({
                ...g.toJson(),
                'elapsedMs': 371000,
              })!,
              share: (_) async {},
            );
          },
          act: (tester, app) async {
            final s = app.s;
            await tester.tap(find.text(s.check));
            await tester.pumpAndSettle();
            final p = generatePuzzle(level: Level.inspector, seed: _day);
            await tester.tap(find.widgetWithText(ListTile, p.name(p.culprit)));
            await tester.pumpAndSettle();
            await tester.pump(Motion.reveal + Motion.revealHold);
            await tester.pumpAndSettle();
          },
        );

        // 05: the guided first case, on its first deduction.
        await _capture(
          tester,
          t,
          lang,
          '05',
          (app) => GameScreen.tutorial(appState: app),
          act: (tester, app) async {
            for (var i = 0; i < 2; i++) {
              await tester.tap(find.text(app.s.next));
              await tester.pumpAndSettle();
            }
          },
        );

        // 06: statistics.
        await _capture(
          tester,
          t,
          lang,
          '06',
          (app) => StatsScreen(appState: app, now: () => _today),
        );
      });
    }
  }
}

import 'dart:io';

import 'package:coartada/core/app_info.dart';
import 'package:coartada/core/app_state.dart';
import 'package:coartada/screens/about_screen.dart';
import 'package:coartada/screens/home_screen.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppState> _state() async {
  SharedPreferences.setMockInitialValues({});
  return AppState(await SharedPreferences.getInstance());
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(375 * 3, 812 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

void main() {
  test('appVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final v = RegExp(
      r'^version: (\S+?)\+',
      multiLine: true,
    ).firstMatch(pubspec);
    expect(v?.group(1), appVersion);
  });

  test('the site has the pages the app links to', () {
    for (final page in ['index', 'privacy/index', 'support/index']) {
      expect(File('site/$page.html').existsSync(), isTrue, reason: page);
    }
    expect(privacyUrl.toString(), endsWith('/privacy/'));
    expect(supportUrl.toString(), endsWith('/support/'));
  });

  testWidgets('settings open About; links go out, failures say where', (
    tester,
  ) async {
    _phone(tester);
    final app = await _state();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: HomeScreen(appState: app),
      ),
    );
    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Acerca de Coartada'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Acerca de Coartada'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Versión $appVersion'), findsOneWidget);

    // A fresh app (new key: drop the pushed routes) with a fake opener.
    final opened = <Uri>[];
    var works = true;
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        theme: AppTheme.light(),
        home: AboutScreen(
          appState: app,
          openLink: (uri) async {
            opened.add(uri);
            return works;
          },
        ),
      ),
    );
    await tester.tap(find.text('Política de privacidad'));
    await tester.tap(find.text('Ayuda y contacto'));
    await tester.pump();
    expect(opened, [privacyUrl, supportUrl]);
    expect(find.byType(SnackBar), findsNothing);

    works = false;
    await tester.ensureVisible(find.text('Escríbenos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escríbenos'));
    await tester.pump();
    expect(opened.last, contactUrl);
    expect(
      find.text('No se ha podido abrir. La dirección es: ${contactUrl.path}'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Licencias'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Licencias'));
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('About reads in every language and theme without overflow', (
    tester,
  ) async {
    _phone(tester);
    final app = await _state();
    for (final lang in ['es', 'ca', 'en']) {
      app.language = lang;
      for (final theme in [AppTheme.light(), AppTheme.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: AboutScreen(appState: app),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    }
  });
}

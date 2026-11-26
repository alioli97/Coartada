import 'dart:io';

import 'package:coartada/core/font_licenses.dart';
import 'package:coartada/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every font file declared in pubspec exists', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final assets = RegExp(r'asset: (assets/fonts/\S+\.ttf)')
        .allMatches(pubspec)
        .map((m) => m.group(1)!)
        .toList();
    expect(assets, hasLength(4));
    for (final a in assets) {
      expect(File(a).existsSync(), isTrue, reason: a);
    }
    for (final license in bundledFonts.values) {
      expect(File(license).readAsStringSync(), contains('SIL OPEN FONT'));
    }
  });

  test('theme uses Playfair for headings and Source Serif 4 for text', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final t = theme.textTheme;
      expect(t.displaySmall!.fontFamily, AppTheme.headingFont);
      expect(t.titleLarge!.fontFamily, AppTheme.headingFont);
      expect(t.bodyLarge!.fontFamily, AppTheme.bodyFont);
      expect(t.labelSmall!.fontFamily, AppTheme.bodyFont);
    }
  });

  test('font licenses are registered', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerFontLicenses();
    final packages = <String>{};
    await for (final entry in LicenseRegistry.licenses) {
      packages.addAll(entry.packages);
    }
    expect(packages, containsAll(bundledFonts.keys));
  });
}

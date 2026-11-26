import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bundled fonts and their OFL license files in `assets/fonts/`.
const bundledFonts = {
  'Playfair Display': 'assets/fonts/OFL-PlayfairDisplay.txt',
  'Source Serif 4': 'assets/fonts/OFL-SourceSerif4.txt',
};

/// Adds the bundled fonts' licenses to the app's license page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final MapEntry(key: family, value: path) in bundledFonts.entries) {
      final text = await rootBundle.loadString(path);
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}

import 'package:url_launcher/url_launcher.dart';

/// Version shown in About and the licenses page. Keep it equal to the
/// `version:` in pubspec.yaml (without the build number):
/// `test/about_test.dart` checks it.
const appVersion = '1.0.0';

/// The public pages in `site/`, published by `.github/workflows/pages.yml`.
const siteUrl = 'https://alioli97.github.io/Pesquisa';

/// Where a shared result sends people (the landing page links to the stores).
const shareLink = 'alioli97.github.io/Pesquisa';
final privacyUrl = Uri.parse('$siteUrl/privacy/');
final supportUrl = Uri.parse('$siteUrl/support/');
final contactUrl = Uri.parse('mailto:alio.studios.games@gmail.com');

/// Opens [uri] outside the app; false when nothing could open it.
typedef OpenLink = Future<bool> Function(Uri uri);

Future<bool> openWithPlatform(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

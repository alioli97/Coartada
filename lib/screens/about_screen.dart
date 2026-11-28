import 'package:material_ui/material_ui.dart';

import '../core/app_info.dart';
import '../core/app_state.dart';
import '../widgets/app_icon.dart';

/// Version, what the game is, the public privacy and support pages, an email
/// contact and the licenses page. Opened from the settings sheet.
class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    required this.appState,
    this.openLink = openWithPlatform,
  });

  final AppState appState;

  /// Opens links outside the app; tests pass a fake.
  final OpenLink openLink;

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await openLink(uri)) return;
    final s = appState.s;
    final shown = uri.scheme == 'mailto' ? uri.path : uri.toString();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${s.linkFailed} $shown')));
  }

  @override
  Widget build(BuildContext context) {
    final s = appState.s;
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final muted = theme.colorScheme.onSurfaceVariant;
    const legalese = '© 2026 Arnau Alio';

    return Scaffold(
      appBar: AppBar(title: Text(s.about)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const SizedBox(height: 8),
                const Center(child: ExcludeSemantics(child: AppIcon(size: 88))),
                const SizedBox(height: 16),
                Text(
                  'Pesquisa',
                  textAlign: TextAlign.center,
                  style: text.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  s.version(appVersion),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: muted),
                ),
                const SizedBox(height: 20),
                Text(s.aboutBody, style: text.bodyLarge),
                const SizedBox(height: 12),
                Text(s.aboutPrivacy, style: text.bodyLarge),
                const SizedBox(height: 16),
                const Divider(),
                _LinkTile(
                  icon: Icons.privacy_tip_outlined,
                  title: s.privacyPolicy,
                  subtitle: s.opensInBrowser,
                  external: true,
                  onTap: () => _open(context, privacyUrl),
                ),
                _LinkTile(
                  icon: Icons.help_outline,
                  title: s.support,
                  subtitle: s.opensInBrowser,
                  external: true,
                  onTap: () => _open(context, supportUrl),
                ),
                _LinkTile(
                  icon: Icons.mail_outline,
                  title: s.writeToUs,
                  subtitle: contactUrl.path,
                  external: true,
                  onTap: () => _open(context, contactUrl),
                ),
                _LinkTile(
                  icon: Icons.description_outlined,
                  title: s.licenses,
                  subtitle: s.licensesBody,
                  external: false,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Pesquisa',
                    applicationVersion: s.version(appVersion),
                    applicationIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: AppIcon(size: 56),
                    ),
                    applicationLegalese: legalese,
                  ),
                ),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  legalese,
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.external,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool external;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minTileHeight: 56,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: Icon(external ? Icons.open_in_new : Icons.chevron_right),
    onTap: onTap,
  );
}

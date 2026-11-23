import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/widgets/vaultix_card.dart';
import '../../../core/widgets/vaultix_logo.dart';
import '../data/package_info_provider.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  Future<void> _mail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppInfo.contactEmail,
      query: 'subject=Vaultix',
    );
    try {
      final ok = await launchUrl(uri);
      if (!ok && context.mounted) _snack(context);
    } catch (_) {
      if (context.mounted) _snack(context);
    }
  }

  void _snack(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('No email app found')));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final info = ref.watch(packageInfoProvider).valueOrNull;
    final version = info?.version ?? AppConstants.version;
    final build = info?.buildNumber ?? '';
    final versionText = build.isEmpty ? 'Version $version' : 'Version $version ($build)';

    return VaultixCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                const VaultixLogo(size: 72),
                const SizedBox(height: 16),
                Text(AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(AppConstants.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65))),
                const SizedBox(height: 10),
                Text(versionText,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Developer'),
            subtitle: const Text(AppInfo.developerName),
          ),
          if (AppInfo.contactEmail.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.mail_outline_rounded),
              title: const Text('Contact'),
              subtitle: const Text(AppInfo.contactEmail),
              onTap: () => _mail(context),
            ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/legal/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms and conditions'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/legal/terms'),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Open-source licenses'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(
              context: context,
              applicationName: AppConstants.appName,
              applicationVersion: version,
              applicationLegalese: '© ${DateTime.now().year} ${AppInfo.developerName}',
            ),
          ),
        ],
      ),
    );
  }
}

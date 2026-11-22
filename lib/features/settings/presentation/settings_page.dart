import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/vaultix_card.dart';
import 'security_section.dart';

/// Appearance + About are functional now; security and vault management
/// sections are added in later phases.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Security'),
        const SecuritySection(),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Organization'),
        VaultixCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.category_rounded),
            title: const Text('Categories'),
            subtitle: const Text('Manage names, icons and colors'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/categories'),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Appearance'),
        VaultixCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Theme'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Light')),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Dark')),
                    ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('System')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => notifier.setThemeMode(s.first),
                ),
              ),
              const SizedBox(height: 22),
              const Text('Accent color'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in AppColors.accentOptions)
                    _AccentDot(
                      color: c,
                      selected: c.toARGB32() == settings.accent.toARGB32(),
                      onTap: () => notifier.setAccent(c),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'About'),
        const VaultixCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.shield_rounded),
            title: Text(AppConstants.appName),
            subtitle: Text('${AppConstants.tagline}\nVersion ${AppConstants.version}'),
            isThreeLine: true,
          ),
        ),
      ],
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Accent color',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface
                  : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

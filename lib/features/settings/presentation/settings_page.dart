import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/vaultix_card.dart';
import 'about_section.dart';
import 'security_section.dart';
import 'vault_management_section.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(themeSettingsProvider);
    final notifier = ref.read(themeSettingsProvider.notifier);
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                cacheExtent: 400,
                padding: EdgeInsets.fromLTRB(20, 0, 20, AppConstants.floatingNavReserved + 16 + bottomPad),
                children: [
            const SectionHeader(title: 'Security'),
            const SecuritySection(),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Organization'),
            VaultixCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: _iconBox(context, Icons.category_rounded),
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
                  Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
                        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('System')),
                      ],
                      selected: {settings.themeMode},
                      onSelectionChanged: (s) => notifier.setThemeMode(s.first),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Accent color', style: Theme.of(context).textTheme.titleMedium),
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
            const SectionHeader(title: 'Vault management'),
            const VaultManagementSection(),
            const SizedBox(height: 20),
            const SectionHeader(title: 'About'),
            const AboutSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _iconBox(BuildContext context, IconData icon) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: primary.withValues(alpha: 0.12),
      ),
      child: Icon(icon, color: primary),
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Accent color',
      child: PressableScale(
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: selected ? 0.45 : 0.18),
                  blurRadius: selected ? 14 : 8,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: selected ? onSurface.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.35),
                width: selected ? 2.4 : 1.2,
              ),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: selected ? 1 : 0,
              child: const Icon(Icons.check_rounded, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/vaultix_card.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../categories/presentation/category_providers.dart';
import '../../password_health/presentation/health_providers.dart';
import '../../vault/domain/credential.dart';
import '../../vault/presentation/vault_state.dart';
import 'dashboard_state.dart';
import 'dashboard_widgets.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _submitSearch(String query) {
    ref.read(vaultFilterProvider.notifier).setQuery(query.trim());
    _search.clear();
    context.go('/vault');
  }

  void _open(CredentialSummary c) => context.push('/vault/${c.id}');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.6);

    final stats = ref.watch(dashboardStatsProvider).valueOrNull;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final byId = {for (final c in categories) c.category.id: c.category};
    final added = ref.watch(recentlyAddedProvider).valueOrNull ?? const [];
    final accessed = ref.watch(recentlyAccessedProvider).valueOrNull ?? const [];
    final frequent = ref.watch(frequentlyUsedProvider).valueOrNull ?? const [];
    final health = ref.watch(passwordHealthProvider);
    final isEmptyVault = stats != null && stats.total == 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () => context.push('/vault/new'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add password'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
        children: [
          // Welcome + lock
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(), style: TextStyle(color: muted)),
                    const SizedBox(height: 2),
                    Text('Welcome back',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Lock vault',
                onPressed: ref.read(authControllerProvider.notifier).lock,
                icon: const Icon(Icons.lock_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onSubmitted: _submitSearch,
            decoration: const InputDecoration(
              hintText: 'Search your vault',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 20),

          // 1. Overview cards
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.key_rounded,
                  value: '${stats?.total ?? '–'}',
                  label: 'Passwords',
                  color: scheme.primary,
                  onTap: () {
                    ref.read(vaultFilterProvider.notifier).reset();
                    ref.read(vaultFilterProvider.notifier).setFavoritesOnly(false);
                    context.go('/vault');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.category_rounded,
                  value: categories.isEmpty ? '–' : '${categories.length}',
                  label: 'Categories',
                  color: AppColors.secondary,
                  onTap: () => context.push('/categories'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.star_rounded,
                  value: '${stats?.favorites ?? '–'}',
                  label: 'Favorites',
                  color: AppColors.warning,
                  onTap: () {
                    final n = ref.read(vaultFilterProvider.notifier);
                    n.reset();
                    n.setFavoritesOnly(true);
                    context.go('/vault');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (isEmptyVault)
            VaultixCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(Icons.shield_rounded, size: 40, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text('Start your vault',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    AppConstants.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Add your first password',
                    icon: Icons.add_rounded,
                    onPressed: () => context.push('/vault/new'),
                  ),
                ],
              ),
            )
          else ...[
            // 2. Recently added
            if (added.isNotEmpty) ...[
              SectionHeader(
                title: 'Recently added',
                actionLabel: 'See all',
                onAction: () {
                  final n = ref.read(vaultFilterProvider.notifier);
                  n.reset();
                  n.setFavoritesOnly(false);
                  n.setSort(CredentialSort.recentlyAdded);
                  context.go('/vault');
                },
              ),
              CredentialMiniList(items: added, categories: byId, onOpen: _open),
              const SizedBox(height: 16),
            ],
            // 3. Frequently used
            if (frequent.isNotEmpty) ...[
              const SectionHeader(title: 'Frequently used'),
              CredentialMiniList(items: frequent, categories: byId, onOpen: _open),
              const SizedBox(height: 16),
            ],
            // Recently accessed
            if (accessed.isNotEmpty) ...[
              const SectionHeader(title: 'Recently accessed'),
              CredentialMiniList(items: accessed, categories: byId, onOpen: _open),
              const SizedBox(height: 16),
            ],
          ],

          // 4. Security overview
          const SectionHeader(title: 'Security overview'),
          SecurityOverviewCard(
            report: health,
            onTap: () => context.push('/health'),
          ),
          const SizedBox(height: 20),

          // 5. Quick actions
          const SectionHeader(title: 'Quick actions'),
          Row(
            children: [
              Expanded(
                child: QuickAction(
                  icon: Icons.add_rounded,
                  label: 'Add',
                  onTap: () => context.push('/vault/new'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickAction(
                  icon: Icons.password_rounded,
                  label: 'Generate',
                  onTap: () => context.go('/generator'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickAction(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  onTap: () => context.push('/categories'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: QuickAction(
                  icon: Icons.lock_rounded,
                  label: 'Lock',
                  onTap: ref.read(authControllerProvider.notifier).lock,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

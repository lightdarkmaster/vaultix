import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass.dart';
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
    final q = query.trim();
    if (q.isEmpty) return;
    ref.read(vaultFilterProvider.notifier).setQuery(q);
    _search.clear();
    context.go('/vault');
  }

  void _open(CredentialSummary c) => context.push('/vault/${c.id}');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.62);
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom;

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
      floatingActionButton: null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(), style: TextStyle(color: muted, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                PressableScale(
                  child: GlassSurface(
                    borderRadius: 16,
                    padding: const EdgeInsets.all(2),
                    onTap: () => context.push('/vault/new'),
                    child: IconButton(
                      tooltip: 'Add password',
                      onPressed: () => context.push('/vault/new'),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            GlassSurface(
              borderRadius: 20,
              padding: EdgeInsets.zero,
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onSubmitted: _submitSearch,
                decoration: InputDecoration(
                  hintText: 'Search your vault',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  suffixIcon: IconButton(
                    tooltip: 'Search',
                    onPressed: () => _submitSearch(_search.text),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                cacheExtent: 400,
                padding: EdgeInsets.fromLTRB(20, 0, 20, AppConstants.floatingNavReserved + 24 + bottomPad),
                children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.key_rounded,
                    value: '${stats?.total ?? '—'}',
                    label: 'Passwords',
                    color: scheme.primary,
                    onTap: () {
                      final n = ref.read(vaultFilterProvider.notifier);
                      n.reset();
                      n.setFavoritesOnly(false);
                      context.go('/vault');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.category_rounded,
                    value: '${categories.length}',
                    label: 'Categories',
                    color: AppColors.secondary,
                    onTap: () => context.push('/categories'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.star_rounded,
                    value: '${stats?.favorites ?? '—'}',
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
            const SizedBox(height: 22),
            if (isEmptyVault)
              VaultixCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [scheme.primary.withValues(alpha: 0.22), scheme.secondary.withValues(alpha: 0.12)],
                        ),
                      ),
                      child: Icon(Icons.shield_rounded, size: 38, color: scheme.primary),
                    ),
                    const SizedBox(height: 14),
                    Text('Start your vault', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(AppConstants.tagline, textAlign: TextAlign.center, style: TextStyle(color: muted)),
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
              if (frequent.isNotEmpty) ...[
                const SectionHeader(title: 'Frequently used'),
                CredentialMiniList(items: frequent, categories: byId, onOpen: _open),
                const SizedBox(height: 16),
              ],
              if (accessed.isNotEmpty) ...[
                const SectionHeader(title: 'Recently accessed'),
                CredentialMiniList(items: accessed, categories: byId, onOpen: _open),
                const SizedBox(height: 16),
              ],
            ],
            const SectionHeader(title: 'Security overview'),
            SecurityOverviewCard(report: health, onTap: () => context.push('/health')),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Quick actions'),
            Row(
              children: [
                Expanded(child: QuickAction(icon: Icons.add_rounded, label: 'Add', onTap: () => context.push('/vault/new'))),
                const SizedBox(width: 10),
                Expanded(child: QuickAction(icon: Icons.password_rounded, label: 'Generate', onTap: () => context.go('/generator'))),
                const SizedBox(width: 10),
                Expanded(child: QuickAction(icon: Icons.category_rounded, label: 'Categories', onTap: () => context.push('/categories'))),
                const SizedBox(width: 10),
                Expanded(child: QuickAction(icon: Icons.lock_rounded, label: 'Lock', onTap: ref.read(authControllerProvider.notifier).lock)),
              ],
            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


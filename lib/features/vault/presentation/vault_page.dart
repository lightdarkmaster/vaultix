import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state.dart';
import '../../categories/presentation/category_providers.dart';
import '../data/vault_providers.dart';
import '../domain/credential.dart';
import 'vault_state.dart';
import 'widgets/credential_tile.dart';

class VaultPage extends ConsumerStatefulWidget {
  const VaultPage({super.key});

  @override
  ConsumerState<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends ConsumerState<VaultPage> {
  late final TextEditingController _search;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(vaultFilterProvider).query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {}); // refresh the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250),
        () => ref.read(vaultFilterProvider.notifier).setQuery(value));
  }

  Future<void> _toggleFavorite(CredentialSummary c) async {
    await ref
        .read(credentialRepositoryProvider)
        .setFavorite(c.id, !c.isFavorite);
    ref.invalidate(credentialListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(vaultFilterProvider);
    final notifier = ref.read(vaultFilterProvider.notifier);
    final list = ref.watch(credentialListProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final byId = {for (final c in categories) c.category.id: c.category};

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        tooltip: 'Add password',
        onPressed: () => context.push('/vault/new'),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text('Vault',
                      style: Theme.of(context).textTheme.headlineMedium),
                ),
                IconButton(
                  tooltip: 'Favorites only',
                  onPressed: notifier.toggleFavorites,
                  icon: Icon(
                    filter.favoritesOnly
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: filter.favoritesOnly ? AppColors.warning : null,
                  ),
                ),
                PopupMenuButton<CredentialSort>(
                  tooltip: 'Sort',
                  icon: const Icon(Icons.sort_rounded),
                  onSelected: notifier.setSort,
                  itemBuilder: (_) => [
                    CheckedPopupMenuItem(
                      value: CredentialSort.title,
                      checked: filter.sort == CredentialSort.title,
                      child: const Text('Alphabetical'),
                    ),
                    CheckedPopupMenuItem(
                      value: CredentialSort.recentlyAdded,
                      checked: filter.sort == CredentialSort.recentlyAdded,
                      child: const Text('Recently added'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name, website, username or tag',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                          notifier.setQuery('');
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: filter.categoryId == null,
                    onSelected: (_) => notifier.setCategory(null),
                  ),
                ),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(CategoryIcons.resolve(c.category.iconKey),
                          size: 18, color: Color(c.category.color)),
                      label: Text(c.category.name),
                      selected: filter.categoryId == c.category.id,
                      onSelected: (sel) =>
                          notifier.setCategory(sel ? c.category.id : null),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Could not load your vault',
                message: 'Something went wrong reading the database.',
                actionLabel: 'Try again',
                onAction: () => ref.invalidate(credentialListProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return filter.isDefault
                      ? EmptyState(
                          icon: Icons.lock_outline_rounded,
                          title: 'Your vault is empty',
                          message:
                              'Add your first password. It is encrypted on this device before it is saved.',
                          actionLabel: 'Add password',
                          onAction: () => context.push('/vault/new'),
                        )
                      : EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No matches',
                          message: 'Try a different search or clear your filters.',
                          actionLabel: 'Clear filters',
                          onAction: () {
                            _search.clear();
                            notifier.reset();
                          },
                        );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final c = items[i];
                    return CredentialTile(
                      credential: c,
                      category: byId[c.categoryId],
                      onTap: () => context.push('/vault/${c.id}'),
                      onToggleFavorite: () => _toggleFavorite(c),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

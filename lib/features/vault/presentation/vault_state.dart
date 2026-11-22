import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../categories/presentation/category_providers.dart';
import '../data/vault_providers.dart';
import '../domain/credential.dart';
import '../domain/vault_filter.dart';

class VaultFilterNotifier extends Notifier<VaultFilter> {
  @override
  VaultFilter build() => const VaultFilter();

  void setQuery(String q) => state = state.copyWith(query: q);
  void setCategory(int? id) => state =
      id == null ? state.copyWith(clearCategory: true) : state.copyWith(categoryId: id);
  void toggleFavorites() =>
      state = state.copyWith(favoritesOnly: !state.favoritesOnly);
  void setSort(CredentialSort s) => state = state.copyWith(sort: s);

  /// Clears search and filters but keeps the chosen sort order.
  void reset() => state = VaultFilter(sort: state.sort);
}

final vaultFilterProvider =
    NotifierProvider<VaultFilterNotifier, VaultFilter>(VaultFilterNotifier.new);

/// Non-secret summaries for the vault list.
final credentialListProvider =
    FutureProvider.autoDispose<List<CredentialSummary>>((ref) {
  final f = ref.watch(vaultFilterProvider);
  return ref.watch(credentialRepositoryProvider).list(
        query: f.query,
        categoryId: f.categoryId,
        favoritesOnly: f.favoritesOnly,
        sort: f.sort,
      );
});

/// One decrypted entry. autoDispose means the plaintext is released as soon
/// as the detail / edit screen is closed.
final credentialDetailProvider =
    FutureProvider.autoDispose.family<Credential?, int>(
  (ref, id) => ref.watch(credentialRepositoryProvider).get(id),
);

/// Call after any add / edit / delete / favorite change.
void refreshVault(WidgetRef ref) {
  ref.invalidate(credentialListProvider);
  ref.invalidate(categoriesProvider);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/presentation/auth_controller.dart';
import '../../categories/presentation/category_providers.dart';
import '../../dashboard/presentation/dashboard_state.dart';
import '../data/vault_providers.dart';
import '../domain/credential.dart';
import '../domain/vault_filter.dart';

class VaultFilterNotifier extends Notifier<VaultFilter> {
  @override
  VaultFilter build() {
    // Don't leave a search term behind after the vault locks.
    ref.listen<AuthStatus>(
      authControllerProvider.select((s) => s.status),
      (_, status) {
        if (status != AuthStatus.unlocked) state = const VaultFilter();
      },
    );
    return const VaultFilter();
  }

  void setQuery(String q) => state = state.copyWith(query: q);
  void setCategory(int? id) => state =
      id == null ? state.copyWith(clearCategory: true) : state.copyWith(categoryId: id);
  void toggleFavorites() =>
      state = state.copyWith(favoritesOnly: !state.favoritesOnly);
  void setFavoritesOnly(bool value) =>
      state = state.copyWith(favoritesOnly: value);
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
  refreshDashboard(ref);
}

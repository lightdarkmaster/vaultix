import 'credential.dart';

class VaultFilter {
  const VaultFilter({
    this.query = '',
    this.categoryId,
    this.favoritesOnly = false,
    this.sort = CredentialSort.title,
  });

  final String query;
  final int? categoryId;
  final bool favoritesOnly;
  final CredentialSort sort;

  /// True when no search or filter is applied (sorting doesn't count).
  bool get isDefault => query.trim().isEmpty && categoryId == null && !favoritesOnly;

  VaultFilter copyWith({
    String? query,
    int? categoryId,
    bool clearCategory = false,
    bool? favoritesOnly,
    CredentialSort? sort,
  }) =>
      VaultFilter(
        query: query ?? this.query,
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        favoritesOnly: favoritesOnly ?? this.favoritesOnly,
        sort: sort ?? this.sort,
      );
}

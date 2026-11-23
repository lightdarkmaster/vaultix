import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../password_health/presentation/health_providers.dart';
import '../../vault/data/vault_providers.dart';
import '../../vault/domain/credential.dart';

class DashboardStats {
  const DashboardStats({required this.total, required this.favorites});
  final int total;
  final int favorites;
}

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final repo = ref.watch(credentialRepositoryProvider);
  return DashboardStats(
    total: await repo.count(),
    favorites: await repo.favoriteCount(),
  );
});

final recentlyAddedProvider =
    FutureProvider.autoDispose<List<CredentialSummary>>(
  (ref) => ref.watch(credentialRepositoryProvider).recentlyAdded(limit: 6),
);

final recentlyAccessedProvider =
    FutureProvider.autoDispose<List<CredentialSummary>>(
  (ref) => ref.watch(credentialRepositoryProvider).recentlyAccessed(limit: 6),
);

final frequentlyUsedProvider =
    FutureProvider.autoDispose<List<CredentialSummary>>(
  (ref) => ref.watch(credentialRepositoryProvider).frequentlyUsed(limit: 6),
);

/// Re-fetches everything on the dashboard (after add / edit / delete).
void refreshDashboard(WidgetRef ref) {
  ref.invalidate(dashboardStatsProvider);
  ref.invalidate(recentlyAddedProvider);
  ref.invalidate(recentlyAccessedProvider);
  ref.invalidate(frequentlyUsedProvider);
  ref.invalidate(passwordHealthProvider);
  ref.invalidate(healthEntriesProvider);
}

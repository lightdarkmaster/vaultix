import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../vault/data/vault_providers.dart';
import '../../vault/domain/credential.dart';
import '../domain/password_health.dart';

/// Decrypts every password, analyses them locally and keeps only the
/// secret-free [HealthReport]. Nothing leaves the device.
final passwordHealthProvider = FutureProvider.autoDispose<HealthReport>((ref) async {
  final records =
      await ref.watch(credentialRepositoryProvider).allForAnalysis();
  return const PasswordHealthAnalyzer().analyze(records);
});

/// Non-secret summaries keyed by id, used to show titles on the health screen.
final healthEntriesProvider =
    FutureProvider.autoDispose<Map<int, CredentialSummary>>((ref) async {
  final list = await ref.watch(credentialRepositoryProvider).list();
  return {for (final c in list) c.id: c};
});

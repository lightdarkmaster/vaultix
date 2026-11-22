import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../vault/data/vault_providers.dart';
import '../domain/password_health.dart';

/// Decrypts every password, analyses them locally and keeps only the
/// secret-free [HealthReport]. Nothing leaves the device.
final passwordHealthProvider = FutureProvider.autoDispose<HealthReport>((ref) async {
  final records =
      await ref.watch(credentialRepositoryProvider).allForAnalysis();
  return const PasswordHealthAnalyzer().analyze(records);
});

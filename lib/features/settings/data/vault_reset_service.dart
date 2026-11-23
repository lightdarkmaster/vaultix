import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/security/secure_store.dart';
import '../../../core/security/security_providers.dart';
import '../../../core/theme/theme_provider.dart';

/// Erases everything Vaultix stores: the database (entries, categories, the
/// wrapped vault key), PIN and biometric keys, and failed-attempt counters.
/// Appearance and generator preferences are kept.
class VaultResetService {
  VaultResetService(this._db, this._store, this._prefs);

  final AppDatabase _db;
  final SecureStore _store;
  final SharedPreferences _prefs;

  Future<void> wipeAll() async {
    await _db.wipe();
    await _store.deleteAll();
    await _prefs.remove(AppConstants.prefLastBackupAt);
  }
}

final vaultResetServiceProvider = Provider<VaultResetService>(
  (ref) => VaultResetService(
    ref.watch(appDatabaseProvider),
    ref.watch(secureStoreProvider),
    ref.watch(sharedPreferencesProvider),
  ),
);

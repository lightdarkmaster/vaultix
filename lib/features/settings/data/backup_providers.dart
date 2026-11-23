import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/security/security_providers.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/exceptions.dart';
import '../../authentication/presentation/auth_controller.dart';
import '../../vault/data/vault_providers.dart';
import 'backup_codec.dart';
import 'backup_service.dart';
import 'storage_info.dart';

final backupCodecProvider =
    Provider<BackupCodec>((ref) => BackupCodec(ref.watch(cryptoServiceProvider)));

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    ref.watch(appDatabaseProvider),
    ref.watch(backupCodecProvider),
    ref.watch(credentialCipherProvider),
    () {
      final key = ref.read(vaultKeyProvider);
      if (key == null) throw const VaultLockedException();
      return key;
    },
  ),
);

final storageInfoServiceProvider = Provider<StorageInfoService>(
  (ref) => StorageInfoService(ref.watch(appDatabaseProvider)),
);

/// When the last backup was exported (null if never).
class LastBackupNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() {
    final ms = ref
        .watch(sharedPreferencesProvider)
        .getInt(AppConstants.prefLastBackupAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> markNow() async {
    final now = DateTime.now();
    state = now;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(AppConstants.prefLastBackupAt, now.millisecondsSinceEpoch);
  }
}

final lastBackupProvider =
    NotifierProvider<LastBackupNotifier, DateTime?>(LastBackupNotifier.new);

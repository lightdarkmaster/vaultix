import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/security_providers.dart';
import '../../../core/utils/exceptions.dart';
import '../../authentication/presentation/auth_controller.dart';
import 'credential_cipher.dart';
import 'credential_repository.dart';

final credentialCipherProvider = Provider<CredentialCipher>(
  (ref) => CredentialCipher(ref.watch(cryptoServiceProvider)),
);

final credentialRepositoryProvider = Provider<CredentialRepository>(
  (ref) => CredentialRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(credentialCipherProvider),
    () {
      final key = ref.read(vaultKeyProvider);
      if (key == null) throw const VaultLockedException();
      return key;
    },
  ),
);

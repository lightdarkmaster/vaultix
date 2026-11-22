import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeys {
  SecureKeys._();
  static const pinBlob = 'vaultix_pin_blob';
  static const pinFailed = 'vaultix_pin_failed';
  static const biometricKey = 'vaultix_biometric_vault_key';
  static const failedCount = 'vaultix_failed_count';
  static const lockoutUntil = 'vaultix_lockout_until';
}

/// Thin wrapper over flutter_secure_storage (Android Keystore-backed
/// EncryptedSharedPreferences).
class SecureStore {
  SecureStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> deleteAll() => _storage.deleteAll();
}

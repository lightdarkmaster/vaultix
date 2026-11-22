import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:local_auth/local_auth.dart';

import '../../../core/security/crypto_service.dart';
import '../../../core/security/kdf_params.dart';
import '../../../core/security/secure_store.dart';
import '../data/security_repository.dart';

enum UnlockStatus {
  success,
  wrong,
  lockedOut,
  pinRemoved,
  cancelled,
  unavailable,
}

class UnlockOutcome {
  const UnlockOutcome._(
    this.status, {
    this.vaultKey,
    this.lockedFor,
    this.attemptsLeft,
  });

  factory UnlockOutcome.success(Uint8List key) =>
      UnlockOutcome._(UnlockStatus.success, vaultKey: key);
  factory UnlockOutcome.wrong({int? attemptsLeft}) =>
      UnlockOutcome._(UnlockStatus.wrong, attemptsLeft: attemptsLeft);
  factory UnlockOutcome.lockedOut(Duration d) =>
      UnlockOutcome._(UnlockStatus.lockedOut, lockedFor: d);
  const UnlockOutcome.pinRemoved() : this._(UnlockStatus.pinRemoved);
  const UnlockOutcome.cancelled() : this._(UnlockStatus.cancelled);
  const UnlockOutcome.unavailable() : this._(UnlockStatus.unavailable);

  final UnlockStatus status;
  final Uint8List? vaultKey;
  final Duration? lockedFor;
  final int? attemptsLeft;

  bool get isSuccess => status == UnlockStatus.success;
}

/// Key hierarchy:
///   master password --Argon2id(salt)--> KEK --AES-GCM--> wraps random vault key
/// The vault key encrypts credentials (Phase 4). It exists in memory only
/// while the vault is unlocked. PIN and biometric unlock store a wrapped /
/// protected copy in Keystore-backed secure storage.
class AuthService {
  AuthService(
    this._repo,
    this._crypto,
    this._store, [
    LocalAuthentication? localAuth,
  ]) : _localAuth = localAuth ?? LocalAuthentication();

  final SecurityRepository _repo;
  final CryptoService _crypto;
  final SecureStore _store;
  final LocalAuthentication _localAuth;

  static const freeAttempts = 5;
  static const maxPinAttempts = 5;

  // ---- vault lifecycle ----------------------------------------------------

  Future<bool> hasVault() async => (await _repo.load()) != null;

  Future<KdfParams?> kdfParams() async => (await _repo.load())?.kdfParams;

  Future<Uint8List> createVault(String masterPassword) async {
    final salt = _crypto.randomBytes(16);
    const params = KdfParams.defaults;
    final kek = await _crypto.deriveKey(masterPassword, salt, params);
    final vaultKey = _crypto.randomBytes(CryptoService.keyLength);
    final wrapped = await _crypto.encrypt(kek, vaultKey);
    CryptoService.wipe(kek);
    await _repo.save(SecurityRecord(
      salt: salt,
      kdfParams: params,
      encryptedVaultKey: wrapped,
      createdAt: DateTime.now(),
    ));
    await _store.delete(SecureKeys.pinBlob);
    await _store.delete(SecureKeys.biometricKey);
    await _resetFailures();
    return vaultKey;
  }

  Future<UnlockOutcome> unlockWithMasterPassword(String password) async {
    final lock = await lockoutRemaining();
    if (lock != null) return UnlockOutcome.lockedOut(lock);
    final rec = await _repo.load();
    if (rec == null) return const UnlockOutcome.unavailable();

    final kek = await _crypto.deriveKey(password, rec.salt, rec.kdfParams);
    final key = await _crypto.decrypt(kek, rec.encryptedVaultKey);
    CryptoService.wipe(kek);
    if (key == null) return _registerFailure();
    await _resetFailures();
    return UnlockOutcome.success(key);
  }

  /// Re-wraps the same vault key under a new password, so stored credentials
  /// and PIN/biometric unlock keep working.
  Future<UnlockOutcome> changeMasterPassword({
    required String current,
    required String next,
  }) async {
    final lock = await lockoutRemaining();
    if (lock != null) return UnlockOutcome.lockedOut(lock);
    final rec = await _repo.load();
    if (rec == null) return const UnlockOutcome.unavailable();

    final oldKek = await _crypto.deriveKey(current, rec.salt, rec.kdfParams);
    final vaultKey = await _crypto.decrypt(oldKek, rec.encryptedVaultKey);
    CryptoService.wipe(oldKek);
    if (vaultKey == null) return _registerFailure();

    final salt = _crypto.randomBytes(16);
    const params = KdfParams.defaults;
    final newKek = await _crypto.deriveKey(next, salt, params);
    final wrapped = await _crypto.encrypt(newKek, vaultKey);
    CryptoService.wipe(newKek);
    await _repo.save(SecurityRecord(
      salt: salt,
      kdfParams: params,
      encryptedVaultKey: wrapped,
      createdAt: rec.createdAt,
    ));
    await _resetFailures();
    return UnlockOutcome.success(vaultKey);
  }

  // ---- PIN ------------------------------------------------------------------

  Future<bool> isPinEnabled() async =>
      (await _store.read(SecureKeys.pinBlob)) != null;

  Future<void> enablePin(String pin, Uint8List vaultKey) async {
    final salt = _crypto.randomBytes(16);
    const params = KdfParams.defaults;
    final kek = await _crypto.deriveKey(pin, salt, params);
    final wrapped = await _crypto.encrypt(kek, vaultKey);
    CryptoService.wipe(kek);
    await _store.write(
      SecureKeys.pinBlob,
      jsonEncode({
        'salt': base64Encode(salt),
        'kdf': params.toMap(),
        'blob': base64Encode(wrapped),
      }),
    );
    await _store.delete(SecureKeys.pinFailed);
  }

  Future<void> disablePin() async {
    await _store.delete(SecureKeys.pinBlob);
    await _store.delete(SecureKeys.pinFailed);
  }

  Future<UnlockOutcome> unlockWithPin(String pin) async {
    final lock = await lockoutRemaining();
    if (lock != null) return UnlockOutcome.lockedOut(lock);
    final raw = await _store.read(SecureKeys.pinBlob);
    if (raw == null) return const UnlockOutcome.unavailable();

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final kek = await _crypto.deriveKey(
      pin,
      Uint8List.fromList(base64Decode(data['salt'] as String)),
      KdfParams.fromMap(data['kdf'] as Map<String, dynamic>),
    );
    final key = await _crypto.decrypt(
      kek,
      Uint8List.fromList(base64Decode(data['blob'] as String)),
    );
    CryptoService.wipe(kek);

    if (key == null) {
      final fails =
          (int.tryParse(await _store.read(SecureKeys.pinFailed) ?? '') ?? 0) +
              1;
      if (fails >= maxPinAttempts) {
        await disablePin();
        await _registerFailure();
        return const UnlockOutcome.pinRemoved();
      }
      await _store.write(SecureKeys.pinFailed, '$fails');
      return _registerFailure();
    }
    await _store.delete(SecureKeys.pinFailed);
    await _resetFailures();
    return UnlockOutcome.success(key);
  }

  // ---- biometrics -------------------------------------------------------------

  Future<bool> biometricAvailable() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      return (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async =>
      (await _store.read(SecureKeys.biometricKey)) != null;

  Future<bool> _promptBiometric(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> enableBiometric(Uint8List vaultKey) async {
    if (!await _promptBiometric('Confirm to enable biometric unlock')) {
      return false;
    }
    await _store.write(SecureKeys.biometricKey, base64Encode(vaultKey));
    return true;
  }

  Future<void> disableBiometric() => _store.delete(SecureKeys.biometricKey);

  Future<UnlockOutcome> unlockWithBiometric() async {
    final lock = await lockoutRemaining();
    if (lock != null) return UnlockOutcome.lockedOut(lock);
    final stored = await _store.read(SecureKeys.biometricKey);
    if (stored == null) return const UnlockOutcome.unavailable();
    if (!await _promptBiometric('Unlock your Vaultix vault')) {
      return const UnlockOutcome.cancelled();
    }
    await _resetFailures();
    return UnlockOutcome.success(Uint8List.fromList(base64Decode(stored)));
  }

  // ---- failed-attempt handling ---------------------------------------------------

  Future<Duration?> lockoutRemaining() async {
    final until = int.tryParse(await _store.read(SecureKeys.lockoutUntil) ?? '');
    if (until == null) return null;
    final left = until - DateTime.now().millisecondsSinceEpoch;
    return left > 0 ? Duration(milliseconds: left) : null;
  }

  Future<UnlockOutcome> _registerFailure() async {
    final count =
        (int.tryParse(await _store.read(SecureKeys.failedCount) ?? '') ?? 0) +
            1;
    await _store.write(SecureKeys.failedCount, '$count');
    if (count >= freeAttempts) {
      // 30s, 60s, 120s ... capped at 15 minutes.
      final secs = min(30 * (1 << min(count - freeAttempts, 5)), 900);
      final until = DateTime.now().millisecondsSinceEpoch + secs * 1000;
      await _store.write(SecureKeys.lockoutUntil, '$until');
      return UnlockOutcome.lockedOut(Duration(seconds: secs));
    }
    return UnlockOutcome.wrong(attemptsLeft: freeAttempts - count);
  }

  Future<void> _resetFailures() async {
    await _store.delete(SecureKeys.failedCount);
    await _store.delete(SecureKeys.lockoutUntil);
  }
}

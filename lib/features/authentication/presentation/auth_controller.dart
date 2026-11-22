import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/security/crypto_service.dart';
import '../../../core/security/security_providers.dart';
import '../data/security_repository.dart';
import '../domain/auth_service.dart';

final securityRepositoryProvider = Provider<SecurityRepository>(
  (ref) => SecurityRepository(ref.watch(appDatabaseProvider)),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(
    ref.watch(securityRepositoryProvider),
    ref.watch(cryptoServiceProvider),
    ref.watch(secureStoreProvider),
  ),
);

/// The decrypted vault key. Non-null only while the vault is unlocked.
class VaultKeyNotifier extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;

  void set(Uint8List key) {
    final old = state;
    state = key;
    if (old != null) CryptoService.wipe(old);
  }

  void clear() {
    final old = state;
    state = null;
    if (old != null) CryptoService.wipe(old);
  }
}

final vaultKeyProvider =
    NotifierProvider<VaultKeyNotifier, Uint8List?>(VaultKeyNotifier.new);

enum AuthStatus { loading, setupRequired, locked, unlocked }

class AuthState {
  const AuthState({
    this.status = AuthStatus.loading,
    this.pinEnabled = false,
    this.biometricEnabled = false,
    this.biometricAvailable = false,
  });

  final AuthStatus status;
  final bool pinEnabled;
  final bool biometricEnabled;
  final bool biometricAvailable;

  AuthState copyWith({
    AuthStatus? status,
    bool? pinEnabled,
    bool? biometricEnabled,
    bool? biometricAvailable,
  }) =>
      AuthState(
        status: status ?? this.status,
        pinEnabled: pinEnabled ?? this.pinEnabled,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      );
}

class AuthController extends Notifier<AuthState> {
  AuthService get _service => ref.read(authServiceProvider);

  @override
  AuthState build() {
    Future.microtask(initialize);
    return const AuthState();
  }

  Future<void> initialize() async {
    final hasVault = await _service.hasVault();
    final pin = await _service.isPinEnabled();
    final bio = await _service.isBiometricEnabled();
    final bioAvailable = await _service.biometricAvailable();
    state = AuthState(
      status: hasVault ? AuthStatus.locked : AuthStatus.setupRequired,
      pinEnabled: pin && hasVault,
      biometricEnabled: bio && hasVault && bioAvailable,
      biometricAvailable: bioAvailable,
    );
  }

  Future<void> _refreshQuickUnlock() async {
    state = state.copyWith(
      pinEnabled: await _service.isPinEnabled(),
      biometricEnabled: await _service.isBiometricEnabled(),
    );
  }

  void _open(Uint8List key) {
    ref.read(vaultKeyProvider.notifier).set(key);
    state = state.copyWith(status: AuthStatus.unlocked);
  }

  Future<Duration?> lockoutRemaining() => _service.lockoutRemaining();

  Future<void> setupMasterPassword(String password) async {
    final key = await _service.createVault(password);
    state = state.copyWith(pinEnabled: false, biometricEnabled: false);
    _open(key);
  }

  Future<UnlockOutcome> _finish(UnlockOutcome outcome) async {
    if (outcome.isSuccess) {
      _open(outcome.vaultKey!);
    } else if (outcome.status == UnlockStatus.pinRemoved) {
      await _refreshQuickUnlock();
    }
    return outcome;
  }

  Future<UnlockOutcome> unlockWithPassword(String password) async =>
      _finish(await _service.unlockWithMasterPassword(password));

  Future<UnlockOutcome> unlockWithPin(String pin) async =>
      _finish(await _service.unlockWithPin(pin));

  Future<UnlockOutcome> unlockWithBiometric() async =>
      _finish(await _service.unlockWithBiometric());

  void lock() {
    if (state.status != AuthStatus.unlocked) return;
    ref.read(vaultKeyProvider.notifier).clear();
    state = state.copyWith(status: AuthStatus.locked);
  }

  Future<UnlockOutcome> changeMasterPassword({
    required String current,
    required String next,
  }) async {
    final outcome = await _service.changeMasterPassword(
      current: current,
      next: next,
    );
    if (outcome.isSuccess) CryptoService.wipe(outcome.vaultKey!);
    return outcome;
  }

  Future<void> enablePin(String pin) async {
    final key = ref.read(vaultKeyProvider);
    if (key == null) return;
    await _service.enablePin(pin, key);
    await _refreshQuickUnlock();
  }

  Future<void> disablePin() async {
    await _service.disablePin();
    await _refreshQuickUnlock();
  }

  Future<bool> setBiometric(bool enabled) async {
    if (enabled) {
      final key = ref.read(vaultKeyProvider);
      if (key == null) return false;
      final ok = await _service.enableBiometric(key);
      await _refreshQuickUnlock();
      return ok;
    }
    await _service.disableBiometric();
    await _refreshQuickUnlock();
    return true;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// User-facing validation problem (message is safe to show in the UI).
class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when vault data is requested while the vault is locked.
class VaultLockedException implements Exception {
  const VaultLockedException();
  @override
  String toString() => 'The vault is locked';
}

/// Thrown when stored data cannot be decrypted (wrong key or tampering).
class CredentialDecryptionException implements Exception {
  const CredentialDecryptionException();
  @override
  String toString() => 'This entry could not be decrypted';
}

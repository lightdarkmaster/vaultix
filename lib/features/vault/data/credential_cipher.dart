import 'dart:convert';
import 'dart:typed_data';

import '../../../core/security/crypto_service.dart';
import '../../../core/utils/exceptions.dart';

/// Encrypts the secret columns of a credential with the vault key.
///
/// Each field type uses its own AAD label, so a ciphertext copied from the
/// password column into the notes column (or vice versa) fails to decrypt.
class CredentialCipher {
  CredentialCipher(this._crypto);
  final CryptoService _crypto;

  static final _passwordAad = utf8.encode('vaultix.credential.password.v1');
  static final _notesAad = utf8.encode('vaultix.credential.notes.v1');

  Future<Uint8List> encryptPassword(Uint8List key, String password) =>
      _crypto.encrypt(key, utf8.encode(password), aad: _passwordAad);

  Future<String> decryptPassword(Uint8List key, Uint8List blob) async {
    final clear = await _crypto.decrypt(key, blob, aad: _passwordAad);
    if (clear == null) throw const CredentialDecryptionException();
    return utf8.decode(clear);
  }

  /// Returns base64 for the TEXT `notes` column, or null when empty.
  Future<String?> encryptNotes(Uint8List key, String? notes) async {
    if (notes == null || notes.isEmpty) return null;
    final blob = await _crypto.encrypt(key, utf8.encode(notes), aad: _notesAad);
    return base64Encode(blob);
  }

  Future<String?> decryptNotes(Uint8List key, String? stored) async {
    if (stored == null || stored.isEmpty) return null;
    Uint8List blob;
    try {
      blob = Uint8List.fromList(base64Decode(stored));
    } catch (_) {
      throw const CredentialDecryptionException();
    }
    final clear = await _crypto.decrypt(key, blob, aad: _notesAad);
    if (clear == null) throw const CredentialDecryptionException();
    return utf8.decode(clear);
  }
}

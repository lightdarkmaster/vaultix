import 'dart:convert';
import 'dart:typed_data';

import '../../../core/security/crypto_service.dart';
import '../../../core/security/kdf_params.dart';
import '../domain/backup_models.dart';

class _Header {
  const _Header(this.params, this.salt, this.data);
  final KdfParams params;
  final Uint8List salt;
  final Uint8List data;
}

/// Turns [BackupContents] into an encrypted file and back.
///
/// File = JSON header { format, version, kdf, salt, data }. `data` is the
/// payload JSON encrypted with AES-256-GCM under a key derived from the
/// backup password with Argon2id. The password is separate from the master
/// password, and the file contains no plaintext vault data.
class BackupCodec {
  BackupCodec(this._crypto);
  final CryptoService _crypto;

  static const format = 'vaultix-backup';
  static const version = 1;
  static const maxFileBytes = 64 * 1024 * 1024;

  static final List<int> _aad = utf8.encode('vaultix-backup-v1');

  Future<Uint8List> encode(
    BackupContents contents,
    String password, {
    KdfParams params = KdfParams.defaults,
  }) async {
    final salt = _crypto.randomBytes(16);
    final key = await _crypto.deriveKey(password, salt, params);
    try {
      final plain = utf8.encode(jsonEncode(contents.toJson()));
      final blob = await _crypto.encrypt(key, plain, aad: _aad);
      final file = {
        'format': format,
        'version': version,
        'kdf': params.toMap(),
        'salt': base64Encode(salt),
        'data': base64Encode(blob),
      };
      return Uint8List.fromList(utf8.encode(jsonEncode(file)));
    } finally {
      CryptoService.wipe(key);
    }
  }

  Future<BackupContents> decode(Uint8List bytes, String password) async {
    if (bytes.length > maxFileBytes) {
      throw const BackupException('This file is too large to be a Vaultix backup.');
    }
    final header = _parseHeader(bytes);
    final key = await _crypto.deriveKey(password, header.salt, header.params);
    try {
      final clear = await _crypto.decrypt(key, header.data, aad: _aad);
      if (clear == null) {
        throw const BackupException(
            'Incorrect backup password, or the file is damaged.');
      }
      try {
        return BackupContents.fromJson(
            jsonDecode(utf8.decode(clear)) as Map<String, dynamic>);
      } on BackupException {
        rethrow;
      } catch (_) {
        throw const BackupException('The backup contents are not valid.');
      }
    } finally {
      CryptoService.wipe(key);
    }
  }

  _Header _parseHeader(Uint8List bytes) {
    try {
      final m = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (m['format'] != format) {
        throw const BackupException('This is not a Vaultix backup file.');
      }
      final v = m['version'];
      if (v is! int || v < 1) {
        throw const BackupException('This backup file is not valid.');
      }
      if (v > version) {
        throw const BackupException(
            'This backup was made by a newer version of Vaultix. Update the app and try again.');
      }
      final params = KdfParams.fromMap(m['kdf'] as Map<String, dynamic>);
      _checkParams(params);
      final salt = Uint8List.fromList(base64Decode(m['salt'] as String));
      final data = Uint8List.fromList(base64Decode(m['data'] as String));
      if (salt.length < 16 ||
          salt.length > 64 ||
          data.length < CryptoService.nonceLength + CryptoService.macLength) {
        throw const BackupException('This backup file is not valid.');
      }
      return _Header(params, salt, data);
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException('This is not a valid Vaultix backup file.');
    }
  }

  /// Refuse absurd parameters so a crafted file can't exhaust memory or CPU.
  void _checkParams(KdfParams p) {
    final ok = p.algorithm == 'argon2id' &&
        p.parallelism >= 1 &&
        p.parallelism <= 8 &&
        p.iterations >= 1 &&
        p.iterations <= 10 &&
        p.memoryKiB >= 8 * p.parallelism &&
        p.memoryKiB <= 262144 &&
        p.hashLength == 32;
    if (!ok) {
      throw const BackupException('This backup file is not valid.');
    }
  }
}

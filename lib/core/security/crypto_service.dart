import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'kdf_params.dart';

class _KdfJob {
  const _KdfJob(this.secret, this.salt, this.params);
  final String secret;
  final Uint8List salt;
  final KdfParams params;
}

Future<Uint8List> _runArgon2id(_KdfJob job) async {
  final algo = Argon2id(
    memory: job.params.memoryKiB,
    parallelism: job.params.parallelism,
    iterations: job.params.iterations,
    hashLength: job.params.hashLength,
  );
  final key = await algo.deriveKeyFromPassword(
    password: job.secret,
    nonce: job.salt,
  );
  return Uint8List.fromList(await key.extractBytes());
}

/// All cryptography used by Vaultix goes through here.
///
/// Blob format for encrypted data: nonce (12) || ciphertext || GCM tag (16).
class CryptoService {
  CryptoService();

  static const nonceLength = 12;
  static const macLength = 16;
  static const keyLength = 32;

  final AesGcm _aes = AesGcm.with256bits();
  final Random _random = Random.secure();

  /// Cryptographically secure random bytes (OS CSPRNG).
  Uint8List randomBytes(int length) => Uint8List.fromList(
        List<int>.generate(length, (_) => _random.nextInt(256)),
      );

  /// Argon2id runs in a background isolate so the UI stays responsive.
  Future<Uint8List> deriveKey(
    String secret,
    Uint8List salt,
    KdfParams params,
  ) {
    final job = _KdfJob(secret, salt, params);
    return Isolate.run(() => _runArgon2id(job));
  }

  /// AES-256-GCM with a fresh random nonce for every call.
  ///
  /// [aad] (additional authenticated data) is not encrypted but is bound to
  /// the ciphertext: decrypting with different AAD fails. Used to stop
  /// encrypted fields being swapped between columns.
  Future<Uint8List> encrypt(
    Uint8List key,
    List<int> plaintext, {
    List<int> aad = const [],
  }) async {
    final box = await _aes.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: randomBytes(nonceLength),
      aad: aad,
    );
    return Uint8List.fromList(box.concatenation());
  }

  /// Returns null when the key is wrong or the data was tampered with.
  Future<Uint8List?> decrypt(
    Uint8List key,
    Uint8List blob, {
    List<int> aad = const [],
  }) async {
    try {
      final box = SecretBox.fromConcatenation(
        blob,
        nonceLength: nonceLength,
        macLength: macLength,
      );
      final clear = await _aes.decrypt(box, secretKey: SecretKey(key), aad: aad);
      return Uint8List.fromList(clear);
    } catch (_) {
      return null;
    }
  }

  Future<String> encryptString(Uint8List key, String text) async =>
      base64Encode(await encrypt(key, utf8.encode(text)));

  Future<String?> decryptString(Uint8List key, String encoded) async {
    final clear = await decrypt(key, base64Decode(encoded));
    return clear == null ? null : utf8.decode(clear);
  }

  /// Best-effort zeroing of key material we own.
  static void wipe(Uint8List bytes) => bytes.fillRange(0, bytes.length, 0);
}

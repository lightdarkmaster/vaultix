import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vaultix/core/security/crypto_service.dart';
import 'package:vaultix/core/security/kdf_params.dart';
import 'package:vaultix/core/utils/password_strength.dart';

void main() {
  final crypto = CryptoService();
  // Small parameters keep the test fast; production uses KdfParams.defaults.
  const fast = KdfParams(memoryKiB: 64, iterations: 1, parallelism: 1);

  test('AES-GCM round trip', () async {
    final key = crypto.randomBytes(32);
    final blob = await crypto.encryptString(key, 'hunter2');
    expect(await crypto.decryptString(key, blob), 'hunter2');
  });

  test('wrong key and tampered data are rejected', () async {
    final key = crypto.randomBytes(32);
    final blob = await crypto.encrypt(key, [1, 2, 3, 4]);
    expect(await crypto.decrypt(crypto.randomBytes(32), blob), isNull);
    final tampered = Uint8List.fromList(blob)..[blob.length - 1] ^= 0xFF;
    expect(await crypto.decrypt(key, tampered), isNull);
  });

  test('nonces are unique per encryption', () async {
    final key = crypto.randomBytes(32);
    final a = await crypto.encrypt(key, [9, 9, 9]);
    final b = await crypto.encrypt(key, [9, 9, 9]);
    expect(a, isNot(equals(b)));
  });

  test('Argon2id is deterministic per salt and differs across salts', () async {
    final salt = crypto.randomBytes(16);
    final k1 = await crypto.deriveKey('correct horse', salt, fast);
    final k2 = await crypto.deriveKey('correct horse', salt, fast);
    final k3 = await crypto.deriveKey('correct horse', crypto.randomBytes(16), fast);
    expect(k1, equals(k2));
    expect(k1, isNot(equals(k3)));
    expect(k1.length, 32);
  });

  test('wrapped vault key only opens with the right password', () async {
    final salt = crypto.randomBytes(16);
    final kek = await crypto.deriveKey('right-password-123', salt, fast);
    final vaultKey = crypto.randomBytes(32);
    final wrapped = await crypto.encrypt(kek, vaultKey);
    final bad = await crypto.deriveKey('wrong-password-123', salt, fast);
    expect(await crypto.decrypt(bad, wrapped), isNull);
    expect(await crypto.decrypt(kek, wrapped), equals(vaultKey));
  });

  test('password strength ordering', () {
    expect(estimatePasswordStrength('password').isAcceptable, isFalse);
    expect(estimatePasswordStrength('12345678').isAcceptable, isFalse);
    expect(estimatePasswordStrength('correct-Horse-battery-7-staple').score,
        greaterThanOrEqualTo(3));
  });
}

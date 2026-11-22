import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vaultix/core/constants/category_icons.dart';
import 'package:vaultix/core/constants/default_categories.dart';
import 'package:vaultix/core/security/crypto_service.dart';
import 'package:vaultix/core/utils/exceptions.dart';
import 'package:vaultix/features/vault/data/credential_cipher.dart';
import 'package:vaultix/features/vault/domain/credential.dart';

void main() {
  final crypto = CryptoService();
  final cipher = CredentialCipher(crypto);
  final key = crypto.randomBytes(32);

  test('password round trip, ciphertext differs from plaintext', () async {
    final blob = await cipher.encryptPassword(key, 's3cret-Pa55!');
    expect(utf8.decode(blob, allowMalformed: true), isNot(contains('s3cret')));
    expect(await cipher.decryptPassword(key, blob), 's3cret-Pa55!');
  });

  test('notes: empty becomes null, text round trips', () async {
    expect(await cipher.encryptNotes(key, null), isNull);
    expect(await cipher.encryptNotes(key, ''), isNull);
    final stored = await cipher.encryptNotes(key, 'recovery code 1234');
    expect(stored, isNotNull);
    expect(await cipher.decryptNotes(key, stored), 'recovery code 1234');
    expect(await cipher.decryptNotes(key, null), isNull);
  });

  test('wrong key throws', () async {
    final blob = await cipher.encryptPassword(key, 'abc');
    expect(
      () => cipher.decryptPassword(crypto.randomBytes(32), blob),
      throwsA(isA<CredentialDecryptionException>()),
    );
  });

  test('password ciphertext cannot be moved into the notes column', () async {
    final blob = await cipher.encryptPassword(key, 'abc');
    expect(
      () => cipher.decryptNotes(key, base64Encode(blob)),
      throwsA(isA<CredentialDecryptionException>()),
    );
  });

  test('tampered password blob is rejected', () async {
    final blob = await cipher.encryptPassword(key, 'abc');
    final bad = Uint8List.fromList(blob)..[20] ^= 0x01;
    expect(() => cipher.decryptPassword(key, bad),
        throwsA(isA<CredentialDecryptionException>()));
  });

  test('tag parsing normalizes, de-duplicates and limits', () {
    expect(parseTagInput(' Work, work ,Bank,,  '), ['work', 'bank']);
    expect(parseTagInput(''), isEmpty);
    expect(parseTagInput(List.generate(15, (i) => 't$i').join(',')).length, 10);
    expect(decodeTags(encodeTags(['a', 'b'])), ['a', 'b']);
    expect(decodeTags('not json'), isEmpty);
    expect(decodeTags(null), isEmpty);
  });

  test('default categories: 8, unique names, all icons resolvable', () {
    expect(DefaultCategories.all.length, 8);
    expect(DefaultCategories.names.length, 8);
    for (final c in DefaultCategories.all) {
      expect(CategoryIcons.all.containsKey(c.iconKey), isTrue,
          reason: c.iconKey);
    }
  });
}

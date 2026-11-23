import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vaultix/core/security/crypto_service.dart';
import 'package:vaultix/core/security/kdf_params.dart';
import 'package:vaultix/features/settings/data/backup_codec.dart';
import 'package:vaultix/features/settings/domain/backup_models.dart';

void main() {
  final codec = BackupCodec(CryptoService());
  // Small parameters keep tests fast; the app uses KdfParams.defaults.
  const fast = KdfParams(memoryKiB: 64, iterations: 1, parallelism: 1);
  const password = 'correct horse battery staple';

  final created = DateTime.fromMillisecondsSinceEpoch(1700000000000);
  final contents = BackupContents(
    exportedAt: created,
    categories: [
      BackupCategory(name: 'Email', iconKey: 'email', color: 0xFFE65B65, createdAt: created),
      BackupCategory(name: 'Pets', iconKey: 'pets', color: 0xFF20B486, createdAt: created),
    ],
    credentials: [
      BackupCredential(
        title: 'Example Bank',
        websiteUrl: 'https://bank.example.com',
        username: 'me@example.com',
        password: 'hunter2-Secret!',
        categoryName: 'Pets',
        notes: 'recovery code 8841',
        tags: const ['money', 'important'],
        isFavorite: true,
        createdAt: created,
        updatedAt: created,
        lastAccessedAt: created,
        passwordUpdatedAt: created,
        accessCount: 3,
      ),
      BackupCredential(
        title: 'Plain entry',
        password: 'x1',
        createdAt: created,
        updatedAt: created,
        passwordUpdatedAt: created,
      ),
    ],
  );

  Future<Uint8List> make() => codec.encode(contents, password, params: fast);

  Map<String, dynamic> parse(Uint8List b) =>
      jsonDecode(utf8.decode(b)) as Map<String, dynamic>;
  Uint8List write(Map<String, dynamic> m) =>
      Uint8List.fromList(utf8.encode(jsonEncode(m)));

  test('round trip restores every field', () async {
    final out = await codec.decode(await make(), password);
    expect(out.exportedAt, created);
    expect(out.categories.map((c) => c.name), ['Email', 'Pets']);
    expect(out.credentials.length, 2);
    final c = out.credentials.first;
    expect(c.title, 'Example Bank');
    expect(c.websiteUrl, 'https://bank.example.com');
    expect(c.username, 'me@example.com');
    expect(c.password, 'hunter2-Secret!');
    expect(c.categoryName, 'Pets');
    expect(c.notes, 'recovery code 8841');
    expect(c.tags, ['money', 'important']);
    expect(c.isFavorite, isTrue);
    expect(c.accessCount, 3);
    expect(c.lastAccessedAt, created);
    final p = out.credentials.last;
    expect(p.websiteUrl, isNull);
    expect(p.notes, isNull);
    expect(p.categoryName, isNull);
  });

  test('file contains no plaintext vault data', () async {
    final text = utf8.decode(await make());
    for (final secret in ['hunter2', 'Example Bank', 'me@example.com', '8841']) {
      expect(text.contains(secret), isFalse, reason: secret);
    }
    expect(parse(await make())['format'], 'vaultix-backup');
  });

  test('wrong password is rejected', () async {
    final bytes = await make();
    expect(() => codec.decode(bytes, 'not the password'),
        throwsA(isA<BackupException>()));
  });

  test('tampered ciphertext is rejected', () async {
    final m = parse(await make());
    final data = base64Decode(m['data'] as String);
    data[data.length ~/ 2] ^= 0x01;
    m['data'] = base64Encode(data);
    expect(() => codec.decode(write(m), password),
        throwsA(isA<BackupException>()));
  });

  test('tampered KDF header is rejected', () async {
    final m = parse(await make());
    (m['kdf'] as Map<String, dynamic>)['iterations'] = 2;
    expect(() => codec.decode(write(m), password),
        throwsA(isA<BackupException>()));
  });

  test('non-backup and garbage files are rejected', () async {
    expect(() => codec.decode(write({'hello': 1}), password),
        throwsA(isA<BackupException>()));
    expect(() => codec.decode(Uint8List.fromList([1, 2, 3, 4]), password),
        throwsA(isA<BackupException>()));
    expect(() => codec.decode(Uint8List(0), password),
        throwsA(isA<BackupException>()));
  });

  test('newer file versions are refused with a helpful message', () async {
    final m = parse(await make())..['version'] = 99;
    await expectLater(
      codec.decode(write(m), password),
      throwsA(isA<BackupException>()
          .having((e) => e.message, 'message', contains('newer version'))),
    );
  });

  test('absurd KDF parameters are refused before any work is done', () async {
    final m = parse(await make());
    (m['kdf'] as Map<String, dynamic>)['memoryKiB'] = 999999999;
    await expectLater(codec.decode(write(m), password),
        throwsA(isA<BackupException>()));
  });

  test('entries with an empty title or password are rejected', () {
    final bad = {
      'exportedAt': 1,
      'categories': <dynamic>[],
      'credentials': [
        {
          'title': '  ',
          'password': 'x',
          'createdAt': 1,
          'updatedAt': 1,
          'passwordUpdatedAt': 1,
        }
      ],
    };
    expect(() => BackupContents.fromJson(bad), throwsA(isA<BackupException>()));
  });

  test('each export uses a fresh salt, so files differ', () async {
    final a = await make();
    final b = await make();
    expect(a, isNot(equals(b)));
  });
}

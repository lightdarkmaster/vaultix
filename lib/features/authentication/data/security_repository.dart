import 'dart:typed_data';

import '../../../core/database/app_database.dart';
import '../../../core/security/kdf_params.dart';
import 'dart:convert';

class SecurityRecord {
  const SecurityRecord({
    required this.salt,
    required this.kdfParams,
    required this.encryptedVaultKey,
    required this.createdAt,
  });

  final Uint8List salt;
  final KdfParams kdfParams;
  final Uint8List encryptedVaultKey;
  final DateTime createdAt;
}

class SecurityRepository {
  SecurityRepository(this._db);
  final AppDatabase _db;

  Future<SecurityRecord?> load() async {
    final db = await _db.database;
    final rows = await db.query('security', limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return SecurityRecord(
      salt: Uint8List.fromList(r['salt'] as List<int>),
      kdfParams: KdfParams.fromMap(
        jsonDecode(r['key_derivation_parameters'] as String)
            as Map<String, dynamic>,
      ),
      encryptedVaultKey:
          Uint8List.fromList(r['encrypted_vault_key'] as List<int>),
      createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
    );
  }

  /// There is only ever one security row.
  Future<void> save(SecurityRecord record) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete('security');
      await txn.insert('security', {
        'salt': record.salt,
        'key_derivation_parameters': jsonEncode(record.kdfParams.toMap()),
        'encrypted_vault_key': record.encryptedVaultKey,
        'created_at': record.createdAt.millisecondsSinceEpoch,
      });
    });
  }
}

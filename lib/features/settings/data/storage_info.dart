import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../../../core/constants/default_categories.dart';
import '../../../core/database/app_database.dart';
import '../../../core/security/kdf_params.dart';

class StorageInfo {
  const StorageInfo({
    required this.credentialCount,
    required this.categoryCount,
    required this.customCategoryCount,
    required this.databaseBytes,
    required this.vaultCreatedAt,
    required this.kdfParams,
  });

  final int credentialCount;
  final int categoryCount;
  final int customCategoryCount;
  final int databaseBytes;
  final DateTime? vaultCreatedAt;
  final KdfParams? kdfParams;
}

class StorageInfoService {
  StorageInfoService(this._db);
  final AppDatabase _db;

  Future<StorageInfo> load() async {
    final db = await _db.database;
    final credentials = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM credentials')) ??
        0;
    final categories = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM categories')) ??
        0;
    final defaults = DefaultCategories.names.toList();
    final custom = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM categories WHERE name NOT IN '
          '(${defaults.map((_) => '?').join(',')})',
          defaults,
        )) ??
        0;

    final file = File(await _db.databasePath());
    final size = await file.exists() ? await file.length() : 0;

    final sec = await db.query('security', limit: 1);
    DateTime? created;
    KdfParams? kdf;
    if (sec.isNotEmpty) {
      created = DateTime.fromMillisecondsSinceEpoch(sec.first['created_at'] as int);
      try {
        kdf = KdfParams.fromMap(
          jsonDecode(sec.first['key_derivation_parameters'] as String)
              as Map<String, dynamic>,
        );
      } catch (_) {}
    }
    return StorageInfo(
      credentialCount: credentials,
      categoryCount: categories,
      customCategoryCount: custom,
      databaseBytes: size,
      vaultCreatedAt: created,
      kdfParams: kdf,
    );
  }
}

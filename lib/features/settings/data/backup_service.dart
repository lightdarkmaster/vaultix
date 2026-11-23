import 'dart:typed_data';

import '../../../core/constants/category_icons.dart';
import '../../../core/constants/default_categories.dart';
import '../../../core/database/app_database.dart';
import '../../vault/data/credential_cipher.dart';
import '../../vault/domain/credential.dart';
import '../domain/backup_models.dart';
import 'backup_codec.dart';

class _Prepared {
  const _Prepared(this.credential, this.encryptedPassword, this.encryptedNotes);
  final BackupCredential credential;
  final Uint8List encryptedPassword;
  final String? encryptedNotes;
}

class BackupService {
  BackupService(this._db, this._codec, this._cipher, this._keyProvider);

  final AppDatabase _db;
  final BackupCodec _codec;
  final CredentialCipher _cipher;
  final Uint8List Function() _keyProvider;

  /// Reads the whole vault, decrypts it with the vault key, and returns the
  /// bytes of a backup file encrypted with [backupPassword].
  Future<Uint8List> createBackup(String backupPassword) async {
    final key = _keyProvider();
    final db = await _db.database;
    final catRows = await db.query('categories', orderBy: 'id ASC');
    final nameById = {
      for (final r in catRows) r['id'] as int: r['name'] as String,
    };
    final credRows = await db.query('credentials', orderBy: 'id ASC');

    final credentials = <BackupCredential>[];
    for (final r in credRows) {
      final s = CredentialSummary.fromRow(r);
      credentials.add(BackupCredential(
        title: s.title,
        websiteUrl: s.websiteUrl,
        username: s.username,
        password: await _cipher.decryptPassword(
          key,
          Uint8List.fromList(r['encrypted_password'] as List<int>),
        ),
        categoryName: nameById[s.categoryId],
        notes: await _cipher.decryptNotes(key, r['notes'] as String?),
        tags: s.tags,
        isFavorite: s.isFavorite,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
        lastAccessedAt: s.lastAccessedAt,
        passwordUpdatedAt: s.passwordUpdatedAt,
        accessCount: s.accessCount,
      ));
    }

    final contents = BackupContents(
      exportedAt: DateTime.now(),
      categories: [
        for (final r in catRows)
          BackupCategory(
            name: r['name'] as String,
            iconKey: r['icon'] as String,
            color: r['color'] as int,
            createdAt:
                DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
          ),
      ],
      credentials: credentials,
    );
    return _codec.encode(contents, backupPassword);
  }

  static String _identity(String title, String? username, String? url) =>
      '${title.trim().toLowerCase()}|${(username ?? '').trim().toLowerCase()}|'
      '${(url ?? '').trim().toLowerCase()}';

  /// Writes [contents] into the vault in one transaction (all or nothing).
  ///
  /// merge:   keeps everything; adds missing categories; skips entries whose
  ///          name + username + website already exist.
  /// replace: deletes all current entries and custom categories first.
  Future<ImportResult> importBackup(
    BackupContents contents,
    ImportMode mode,
  ) async {
    final key = _keyProvider();

    // Encrypt everything before opening the transaction.
    final prepared = <_Prepared>[];
    for (final c in contents.credentials) {
      prepared.add(_Prepared(
        c,
        await _cipher.encryptPassword(key, c.password),
        await _cipher.encryptNotes(key, c.notes),
      ));
    }

    final db = await _db.database;
    return db.transaction<ImportResult>((txn) async {
      if (mode == ImportMode.replace) {
        await txn.delete('credentials');
        final defaults = DefaultCategories.names.toList();
        await txn.delete(
          'categories',
          where: 'name NOT IN (${defaults.map((_) => '?').join(',')})',
          whereArgs: defaults,
        );
      }

      final idByName = <String, int>{
        for (final r in await txn.query('categories'))
          (r['name'] as String).toLowerCase(): r['id'] as int,
      };
      var categoriesAdded = 0;
      for (final cat in contents.categories) {
        final icon =
            CategoryIcons.all.containsKey(cat.iconKey) ? cat.iconKey : 'folder';
        final existingId = idByName[cat.name.toLowerCase()];
        if (existingId == null) {
          idByName[cat.name.toLowerCase()] = await txn.insert('categories', {
            'name': cat.name,
            'icon': icon,
            'color': cat.color,
            'created_at': cat.createdAt.millisecondsSinceEpoch,
          });
          categoriesAdded++;
        } else if (mode == ImportMode.replace) {
          await txn.update(
            'categories',
            {'icon': icon, 'color': cat.color},
            where: 'id = ?',
            whereArgs: [existingId],
          );
        }
      }
      final otherId = idByName[DefaultCategories.otherName.toLowerCase()];

      final seen = <String>{};
      if (mode == ImportMode.merge) {
        final rows = await txn.query('credentials',
            columns: ['title', 'username', 'website_url']);
        for (final r in rows) {
          seen.add(_identity(r['title'] as String, r['username'] as String?,
              r['website_url'] as String?));
        }
      }

      var added = 0;
      var skipped = 0;
      for (final p in prepared) {
        final c = p.credential;
        if (mode == ImportMode.merge &&
            !seen.add(_identity(c.title, c.username, c.websiteUrl))) {
          skipped++;
          continue;
        }
        final categoryId = c.categoryName == null
            ? otherId
            : (idByName[c.categoryName!.toLowerCase()] ?? otherId);
        await txn.insert('credentials', {
          'title': c.title,
          'website_url': c.websiteUrl,
          'username': c.username,
          'encrypted_password': p.encryptedPassword,
          'category_id': categoryId,
          'notes': p.encryptedNotes,
          'tags': encodeTags(parseTagInput(c.tags.join(','))),
          'is_favorite': c.isFavorite ? 1 : 0,
          'created_at': c.createdAt.millisecondsSinceEpoch,
          'updated_at': c.updatedAt.millisecondsSinceEpoch,
          'last_accessed_at': c.lastAccessedAt?.millisecondsSinceEpoch,
          'password_updated_at': c.passwordUpdatedAt.millisecondsSinceEpoch,
          'access_count': c.accessCount,
        });
        added++;
      }
      return ImportResult(
        added: added,
        skipped: skipped,
        categoriesAdded: categoriesAdded,
      );
    });
  }
}

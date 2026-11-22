import 'dart:typed_data';

import '../../../core/database/app_database.dart';
import '../../../core/utils/exceptions.dart';
import '../domain/credential.dart';
import 'credential_cipher.dart';

/// All credential persistence. Passwords and notes are encrypted before they
/// reach SQLite; lists only ever return [CredentialSummary] (no secrets).
///
/// The vault key is fetched per call via [_keyProvider], which throws
/// [VaultLockedException] while the vault is locked.
class CredentialRepository {
  CredentialRepository(this._db, this._cipher, this._keyProvider);

  final AppDatabase _db;
  final CredentialCipher _cipher;
  final Uint8List Function() _keyProvider;

  // ---- reads ------------------------------------------------------------------

  /// Search matches title, website, username and tags. Notes are encrypted
  /// and therefore not searchable.
  Future<List<CredentialSummary>> list({
    String query = '',
    int? categoryId,
    bool favoritesOnly = false,
    CredentialSort sort = CredentialSort.title,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    final q = query.trim();
    if (q.isNotEmpty) {
      final like = '%${_escapeLike(q)}%';
      where.add("(title LIKE ? ESCAPE '\\' OR website_url LIKE ? ESCAPE '\\' "
          "OR username LIKE ? ESCAPE '\\' OR tags LIKE ? ESCAPE '\\')");
      args.addAll([like, like, like, like]);
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    if (favoritesOnly) where.add('is_favorite = 1');

    return _summaries(
      where: where.isEmpty ? null : where.join(' AND '),
      args: args,
      orderBy: switch (sort) {
        CredentialSort.title => 'title COLLATE NOCASE ASC',
        CredentialSort.recentlyAdded => 'created_at DESC',
      },
    );
  }

  Future<List<CredentialSummary>> recentlyAdded({int limit = 5}) =>
      _summaries(orderBy: 'created_at DESC', limit: limit);

  Future<List<CredentialSummary>> recentlyAccessed({int limit = 5}) =>
      _summaries(
        where: 'last_accessed_at IS NOT NULL',
        orderBy: 'last_accessed_at DESC',
        limit: limit,
      );

  Future<List<CredentialSummary>> frequentlyUsed({int limit = 5}) =>
      _summaries(
        where: 'access_count > 0',
        orderBy: 'access_count DESC, last_accessed_at DESC',
        limit: limit,
      );

  Future<int> count() async {
    final db = await _db.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM credentials');
    return (rows.first['c'] as int?) ?? 0;
  }

  /// Decrypts one entry. Does not count as an "access"; call [markAccessed]
  /// when the user actually views or copies the secret.
  Future<Credential?> get(int id) async {
    final key = _keyProvider();
    final db = await _db.database;
    final rows =
        await db.query('credentials', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    final row = rows.first;
    return Credential(
      summary: CredentialSummary.fromRow(row),
      password: await _cipher.decryptPassword(
        key,
        Uint8List.fromList(row['encrypted_password'] as List<int>),
      ),
      notes: await _cipher.decryptNotes(key, row['notes'] as String?),
    );
  }

  // ---- writes -----------------------------------------------------------------

  Future<int> add(CredentialDraft draft) async {
    _validate(draft);
    final key = _keyProvider();
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _db.database;
    return db.insert('credentials', {
      ..._plainColumns(draft),
      'encrypted_password': await _cipher.encryptPassword(key, draft.password),
      'notes': await _cipher.encryptNotes(key, _blankToNull(draft.notes)),
      'created_at': now,
      'updated_at': now,
      'password_updated_at': now,
      'access_count': 0,
    });
  }

  Future<void> update(int id, CredentialDraft draft) async {
    _validate(draft);
    final key = _keyProvider();
    final db = await _db.database;

    final existing = await db.query(
      'credentials',
      columns: ['encrypted_password'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (existing.isEmpty) {
      throw const ValidationException('This entry no longer exists');
    }
    final oldPassword = await _cipher.decryptPassword(
      key,
      Uint8List.fromList(existing.first['encrypted_password'] as List<int>),
    );
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'credentials',
      {
        ..._plainColumns(draft),
        'encrypted_password': await _cipher.encryptPassword(key, draft.password),
        'notes': await _cipher.encryptNotes(key, _blankToNull(draft.notes)),
        'updated_at': now,
        if (oldPassword != draft.password) 'password_updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('credentials', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setFavorite(int id, bool value) async {
    final db = await _db.database;
    await db.update(
      'credentials',
      {'is_favorite': value ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAccessed(int id) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE credentials SET last_accessed_at = ?, '
      'access_count = access_count + 1 WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, id],
    );
  }

  // ---- helpers ------------------------------------------------------------------

  Future<List<CredentialSummary>> _summaries({
    String? where,
    List<Object?> args = const [],
    required String orderBy,
    int? limit,
  }) async {
    final db = await _db.database;
    final rows = await db.query(
      'credentials',
      columns: CredentialSummary.columns,
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy,
      limit: limit,
    );
    return rows.map(CredentialSummary.fromRow).toList();
  }

  Map<String, Object?> _plainColumns(CredentialDraft d) => {
        'title': d.title.trim(),
        'website_url': _blankToNull(d.websiteUrl),
        'username': _blankToNull(d.username),
        'category_id': d.categoryId,
        'tags': encodeTags(d.tags),
        'is_favorite': d.isFavorite ? 1 : 0,
      };

  void _validate(CredentialDraft d) {
    if (d.title.trim().isEmpty) {
      throw const ValidationException('Enter a name for this entry');
    }
    if (d.password.isEmpty) {
      throw const ValidationException('Enter a password');
    }
  }

  String? _blankToNull(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  String _escapeLike(String v) => v
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
}

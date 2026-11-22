import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../constants/default_categories.dart';

/// SQLite persistence.
///
/// Schema history:
///  v1  initial schema (Phase 2)
///  v2  credentials.password_updated_at, credentials.access_count,
///      default categories seeded (Phase 3)
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _fileName = 'vaultix.db';
  static const _version = 2;

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _fileName);
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        created_at INTEGER NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE credentials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        website_url TEXT,
        username TEXT,
        encrypted_password BLOB NOT NULL,
        category_id INTEGER,
        notes TEXT,
        tags TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        last_accessed_at INTEGER,
        password_updated_at INTEGER,
        access_count INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )''');
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting_key TEXT NOT NULL UNIQUE,
        setting_value TEXT
      )''');
    await db.execute('''
      CREATE TABLE security (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        salt BLOB NOT NULL,
        key_derivation_parameters TEXT NOT NULL,
        encrypted_vault_key BLOB NOT NULL,
        created_at INTEGER NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX idx_credentials_category ON credentials (category_id)');
    await _seedDefaultCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE credentials ADD COLUMN password_updated_at INTEGER');
      await db.execute(
          'ALTER TABLE credentials ADD COLUMN access_count INTEGER NOT NULL DEFAULT 0');
      await db.execute(
          'UPDATE credentials SET password_updated_at = updated_at '
          'WHERE password_updated_at IS NULL');
      await _seedDefaultCategories(db);
    }
  }

  Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = db.batch();
    for (final c in DefaultCategories.all) {
      batch.rawInsert(
        'INSERT OR IGNORE INTO categories (name, icon, color, created_at) '
        'VALUES (?, ?, ?, ?)',
        [c.name, c.iconKey, c.color, now],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

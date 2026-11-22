import '../../../core/constants/category_icons.dart';
import '../../../core/constants/default_categories.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/exceptions.dart';
import '../domain/category.dart';

class CategoryRepository {
  CategoryRepository(this._db);
  final AppDatabase _db;

  /// Default categories first (lowest ids), then custom ones in creation order.
  Future<List<CategoryWithCount>> listWithCounts() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT c.id, c.name, c.icon, c.color, c.created_at,
             COUNT(cr.id) AS cnt
      FROM categories c
      LEFT JOIN credentials cr ON cr.category_id = c.id
      GROUP BY c.id
      ORDER BY c.id ASC''');
    return [
      for (final r in rows)
        CategoryWithCount(Category.fromRow(r), (r['cnt'] as int?) ?? 0),
    ];
  }

  Future<Category> create({
    required String name,
    required String iconKey,
    required int color,
  }) async {
    final clean = _validName(name);
    final db = await _db.database;
    await _ensureNameFree(clean);
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert('categories', {
      'name': clean,
      'icon': _validIcon(iconKey),
      'color': color,
      'created_at': now,
    });
    return Category(
      id: id,
      name: clean,
      iconKey: _validIcon(iconKey),
      color: color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  Future<void> update(
    int id, {
    required String name,
    required String iconKey,
    required int color,
  }) async {
    final existing = await _get(id);
    final clean = _validName(name);
    if (existing.isDefault && clean != existing.name) {
      throw const ValidationException('Default categories cannot be renamed');
    }
    if (clean.toLowerCase() != existing.name.toLowerCase()) {
      await _ensureNameFree(clean, exceptId: id);
    }
    final db = await _db.database;
    await db.update(
      'categories',
      {'name': clean, 'icon': _validIcon(iconKey), 'color': color},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Credentials in the deleted category move to "Other".
  Future<void> delete(int id) async {
    final existing = await _get(id);
    if (existing.isDefault) {
      throw const ValidationException('Default categories cannot be deleted');
    }
    final db = await _db.database;
    await db.transaction((txn) async {
      final other = await txn.query(
        'categories',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [DefaultCategories.otherName],
        limit: 1,
      );
      if (other.isNotEmpty) {
        await txn.update(
          'credentials',
          {'category_id': other.first['id']},
          where: 'category_id = ?',
          whereArgs: [id],
        );
      }
      await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int?> otherCategoryId() async {
    final db = await _db.database;
    final rows = await db.query(
      'categories',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [DefaultCategories.otherName],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  // ---- helpers ----------------------------------------------------------------

  Future<Category> _get(int id) async {
    final db = await _db.database;
    final rows =
        await db.query('categories', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      throw const ValidationException('This category no longer exists');
    }
    return Category.fromRow(rows.first);
  }

  String _validName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) throw const ValidationException('Enter a category name');
    if (clean.length > 30) {
      throw const ValidationException('Keep the name to 30 characters or fewer');
    }
    return clean;
  }

  String _validIcon(String key) =>
      CategoryIcons.all.containsKey(key) ? key : 'folder';

  Future<void> _ensureNameFree(String name, {int? exceptId}) async {
    final db = await _db.database;
    final rows = await db.query(
      'categories',
      columns: ['id'],
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name],
    );
    final taken = rows.any((r) => r['id'] != exceptId);
    if (taken) {
      throw const ValidationException('A category with that name already exists');
    }
  }
}

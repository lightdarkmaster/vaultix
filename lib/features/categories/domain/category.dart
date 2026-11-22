import '../../../core/constants/default_categories.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.color,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String iconKey;
  final int color; // ARGB
  final DateTime createdAt;

  /// Predefined categories can't be renamed or deleted.
  bool get isDefault => DefaultCategories.names.contains(name);

  factory Category.fromRow(Map<String, Object?> r) => Category(
        id: r['id'] as int,
        name: r['name'] as String,
        iconKey: r['icon'] as String,
        color: r['color'] as int,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
      );
}

class CategoryWithCount {
  const CategoryWithCount(this.category, this.credentialCount);
  final Category category;
  final int credentialCount;
}

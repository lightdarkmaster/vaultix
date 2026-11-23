/// Thrown for any problem reading or writing a backup. [message] is safe to
/// show to the user.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum ImportMode { merge, replace }

class ImportResult {
  const ImportResult({
    required this.added,
    required this.skipped,
    required this.categoriesAdded,
  });
  final int added;
  final int skipped;
  final int categoriesAdded;
}

class BackupCategory {
  const BackupCategory({
    required this.name,
    required this.iconKey,
    required this.color,
    required this.createdAt,
  });

  final String name;
  final String iconKey;
  final int color;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'name': name,
        'icon': iconKey,
        'color': color,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory BackupCategory.fromJson(Map<String, dynamic> j) {
    final name = (j['name'] as String).trim();
    if (name.isEmpty) {
      throw const BackupException('The backup contains an invalid category.');
    }
    return BackupCategory(
      name: name,
      iconKey: j['icon'] as String,
      color: j['color'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(j['createdAt'] as int),
    );
  }
}

/// A credential with its password and notes in plaintext. Exists only while a
/// backup is being created or read; never persist or log it.
class BackupCredential {
  const BackupCredential({
    required this.title,
    required this.password,
    this.websiteUrl,
    this.username,
    this.categoryName,
    this.notes,
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.lastAccessedAt,
    required this.passwordUpdatedAt,
    this.accessCount = 0,
  });

  final String title;
  final String password;
  final String? websiteUrl;
  final String? username;
  final String? categoryName;
  final String? notes;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAccessedAt;
  final DateTime passwordUpdatedAt;
  final int accessCount;

  Map<String, Object?> toJson() => {
        'title': title,
        'websiteUrl': websiteUrl,
        'username': username,
        'password': password,
        'categoryName': categoryName,
        'notes': notes,
        'tags': tags,
        'isFavorite': isFavorite,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'lastAccessedAt': lastAccessedAt?.millisecondsSinceEpoch,
        'passwordUpdatedAt': passwordUpdatedAt.millisecondsSinceEpoch,
        'accessCount': accessCount,
      };

  factory BackupCredential.fromJson(Map<String, dynamic> j) {
    final title = (j['title'] as String).trim();
    final password = j['password'] as String;
    if (title.isEmpty || password.isEmpty) {
      throw const BackupException('The backup contains an invalid entry.');
    }
    DateTime ms(Object? v) => DateTime.fromMillisecondsSinceEpoch(v as int);
    return BackupCredential(
      title: title,
      password: password,
      websiteUrl: j['websiteUrl'] as String?,
      username: j['username'] as String?,
      categoryName: j['categoryName'] as String?,
      notes: j['notes'] as String?,
      tags: ((j['tags'] as List?) ?? const []).whereType<String>().toList(),
      isFavorite: (j['isFavorite'] as bool?) ?? false,
      createdAt: ms(j['createdAt']),
      updatedAt: ms(j['updatedAt']),
      lastAccessedAt:
          j['lastAccessedAt'] == null ? null : ms(j['lastAccessedAt']),
      passwordUpdatedAt: ms(j['passwordUpdatedAt']),
      accessCount: (j['accessCount'] as int?) ?? 0,
    );
  }
}

class BackupContents {
  const BackupContents({
    required this.exportedAt,
    required this.categories,
    required this.credentials,
  });

  final DateTime exportedAt;
  final List<BackupCategory> categories;
  final List<BackupCredential> credentials;

  Map<String, Object?> toJson() => {
        'exportedAt': exportedAt.millisecondsSinceEpoch,
        'categories': [for (final c in categories) c.toJson()],
        'credentials': [for (final c in credentials) c.toJson()],
      };

  factory BackupContents.fromJson(Map<String, dynamic> j) => BackupContents(
        exportedAt: DateTime.fromMillisecondsSinceEpoch(j['exportedAt'] as int),
        categories: [
          for (final c in (j['categories'] as List))
            BackupCategory.fromJson(c as Map<String, dynamic>),
        ],
        credentials: [
          for (final c in (j['credentials'] as List))
            BackupCredential.fromJson(c as Map<String, dynamic>),
        ],
      );
}

import 'dart:convert';

/// Splits "work, Bank,, work" into ['work', 'bank'] (lowercase, de-duplicated,
/// max 10 tags of up to 24 characters).
List<String> parseTagInput(String raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final part in raw.split(',')) {
    var t = part.trim().toLowerCase();
    if (t.isEmpty) continue;
    if (t.length > 24) t = t.substring(0, 24);
    if (!seen.add(t)) continue;
    out.add(t);
    if (out.length == 10) break;
  }
  return out;
}

String encodeTags(List<String> tags) => jsonEncode(tags);

List<String> decodeTags(String? stored) {
  if (stored == null || stored.isEmpty) return const [];
  try {
    final decoded = jsonDecode(stored);
    return decoded is List ? decoded.whereType<String>().toList() : const [];
  } catch (_) {
    return const [];
  }
}

enum CredentialSort { title, recentlyAdded }

/// Everything except the secret fields. Safe to hold in list state because
/// no password or notes are decrypted.
class CredentialSummary {
  const CredentialSummary({
    required this.id,
    required this.title,
    required this.websiteUrl,
    required this.username,
    required this.categoryId,
    required this.tags,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    required this.lastAccessedAt,
    required this.passwordUpdatedAt,
    required this.accessCount,
  });

  final int id;
  final String title;
  final String? websiteUrl;
  final String? username;
  final int? categoryId;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastAccessedAt;
  final DateTime passwordUpdatedAt;
  final int accessCount;

  static const columns = [
    'id',
    'title',
    'website_url',
    'username',
    'category_id',
    'tags',
    'is_favorite',
    'created_at',
    'updated_at',
    'last_accessed_at',
    'password_updated_at',
    'access_count',
  ];

  factory CredentialSummary.fromRow(Map<String, Object?> r) {
    DateTime ms(Object? v) => DateTime.fromMillisecondsSinceEpoch(v as int);
    final updated = ms(r['updated_at']);
    return CredentialSummary(
      id: r['id'] as int,
      title: r['title'] as String,
      websiteUrl: r['website_url'] as String?,
      username: r['username'] as String?,
      categoryId: r['category_id'] as int?,
      tags: decodeTags(r['tags'] as String?),
      isFavorite: (r['is_favorite'] as int) == 1,
      createdAt: ms(r['created_at']),
      updatedAt: updated,
      lastAccessedAt:
          r['last_accessed_at'] == null ? null : ms(r['last_accessed_at']),
      passwordUpdatedAt: r['password_updated_at'] == null
          ? updated
          : ms(r['password_updated_at']),
      accessCount: (r['access_count'] as int?) ?? 0,
    );
  }
}

/// A fully decrypted entry. Only create these on demand (detail / edit
/// screens) and let them go out of scope when the screen closes.
class Credential {
  const Credential({
    required this.summary,
    required this.password,
    this.notes,
  });

  final CredentialSummary summary;
  final String password;
  final String? notes;

  int get id => summary.id;
}

/// Data entered in the add / edit form.
class CredentialDraft {
  const CredentialDraft({
    required this.title,
    required this.password,
    this.websiteUrl,
    this.username,
    this.categoryId,
    this.notes,
    this.tags = const [],
    this.isFavorite = false,
  });

  final String title;
  final String password;
  final String? websiteUrl;
  final String? username;
  final int? categoryId;
  final String? notes;
  final List<String> tags;
  final bool isFavorite;
}

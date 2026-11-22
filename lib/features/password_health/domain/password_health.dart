import 'dart:math';

import '../../../core/utils/password_strength.dart';

/// A decrypted password plus just enough metadata to analyse it. Only ever
/// held transiently while an analysis runs.
class PasswordRecord {
  const PasswordRecord({
    required this.id,
    required this.title,
    required this.password,
    required this.passwordUpdatedAt,
  });

  final int id;
  final String title;
  final String password;
  final DateTime passwordUpdatedAt;
}

/// Result of an analysis. Holds ids and counts only, never passwords, so it is
/// safe to keep in provider state.
class HealthReport {
  const HealthReport({
    required this.total,
    required this.weakIds,
    required this.fairIds,
    required this.strongIds,
    required this.reusedIds,
    required this.reuseGroups,
    required this.oldIds,
    required this.score,
  });

  final int total;
  final List<int> weakIds;
  final List<int> fairIds;
  final List<int> strongIds;

  /// Every entry that shares its password with at least one other entry.
  final List<int> reusedIds;

  /// Entries grouped by the password they share (each group has 2+ ids).
  final List<List<int>> reuseGroups;

  /// Entries whose password hasn't changed in a long time.
  final List<int> oldIds;

  /// 0-100, or null when there is nothing to analyse.
  final int? score;

  int get weakCount => weakIds.length;
  int get strongCount => strongIds.length;
  int get reusedCount => reusedIds.length;
  int get oldCount => oldIds.length;

  /// Passwords that should be updated: weak, reused or old.
  Set<int> get needsUpdateIds => {...weakIds, ...reusedIds, ...oldIds};

  String get scoreLabel {
    final s = score;
    if (s == null) return 'No data';
    if (s >= 85) return 'Excellent';
    if (s >= 70) return 'Good';
    if (s >= 50) return 'Fair';
    return 'At risk';
  }
}

class PasswordHealthAnalyzer {
  const PasswordHealthAnalyzer({this.oldAfter = const Duration(days: 180)});

  /// A password unchanged for longer than this is flagged as old.
  final Duration oldAfter;

  HealthReport analyze(List<PasswordRecord> records, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final byPassword = <String, List<int>>{};
    final penalty = <int, double>{};
    final weak = <int>[];
    final fair = <int>[];
    final strong = <int>[];
    final old = <int>[];

    for (final r in records) {
      byPassword.putIfAbsent(r.password, () => []).add(r.id);

      var p = 0.0;
      final level = estimatePasswordStrength(r.password).score;
      if (level <= StrengthLevel.weak.index) {
        weak.add(r.id);
        p += 0.8;
      } else if (level == StrengthLevel.fair.index) {
        fair.add(r.id);
        p += 0.25;
      } else {
        strong.add(r.id);
      }
      if (clock.difference(r.passwordUpdatedAt) > oldAfter) {
        old.add(r.id);
        p += 0.3;
      }
      penalty[r.id] = p;
    }

    final reused = <int>[];
    final groups = <List<int>>[];
    for (final ids in byPassword.values) {
      if (ids.length < 2) continue;
      groups.add(List.unmodifiable(ids));
      for (final id in ids) {
        reused.add(id);
        penalty[id] = penalty[id]! + 0.6;
      }
    }

    int? score;
    if (records.isNotEmpty) {
      final avg = penalty.values.map((p) => min(1.0, p)).reduce((a, b) => a + b) /
          records.length;
      score = (100 * (1 - avg)).round();
    }

    return HealthReport(
      total: records.length,
      weakIds: weak,
      fairIds: fair,
      strongIds: strong,
      reusedIds: reused,
      reuseGroups: groups,
      oldIds: old,
      score: score,
    );
  }
}

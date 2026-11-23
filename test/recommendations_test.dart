import 'package:flutter_test/flutter_test.dart';
import 'package:vaultix/features/password_health/domain/password_health.dart';
import 'package:vaultix/features/password_health/domain/recommendations.dart';

HealthReport report({
  int total = 10,
  List<int> weak = const [],
  List<int> fair = const [],
  List<List<int>> groups = const [],
  List<int> old = const [],
}) {
  final reused = [for (final g in groups) ...g];
  return HealthReport(
    total: total,
    weakIds: weak,
    fairIds: fair,
    strongIds: const [],
    reusedIds: reused,
    reuseGroups: groups,
    oldIds: old,
    score: 50,
  );
}

void main() {
  test('empty vault produces no recommendations', () {
    expect(buildRecommendations(report(total: 0)), isEmpty);
  });

  test('healthy vault gets a single positive message', () {
    final recs = buildRecommendations(report());
    expect(recs.length, 1);
    expect(recs.single.severity, RecommendationSeverity.good);
  });

  test('problems are listed most urgent first', () {
    final recs = buildRecommendations(report(
      weak: [1],
      fair: [2],
      groups: [
        [3, 4]
      ],
      old: [5],
    ));
    expect(recs.map((r) => r.severity).toList(), [
      RecommendationSeverity.high,
      RecommendationSeverity.high,
      RecommendationSeverity.medium,
      RecommendationSeverity.low,
    ]);
    expect(recs.first.title, 'Replace 1 weak password');
  });

  test('wording is pluralised correctly', () {
    final recs = buildRecommendations(report(weak: [1, 2, 3]));
    expect(recs.first.title, 'Replace 3 weak passwords');
    final reuse = buildRecommendations(report(groups: [
      [1, 2],
      [3, 4, 5]
    ]));
    expect(reuse.first.message, contains('5 entries'));
    expect(reuse.first.message, contains('2 groups'));
  });

  test('no good message when there are problems', () {
    final recs = buildRecommendations(report(old: [1]));
    expect(recs.any((r) => r.severity == RecommendationSeverity.good), isFalse);
  });
}

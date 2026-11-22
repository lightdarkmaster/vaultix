import 'package:flutter_test/flutter_test.dart';
import 'package:vaultix/features/password_health/domain/password_health.dart';

void main() {
  const analyzer = PasswordHealthAnalyzer();
  final now = DateTime(2026, 6, 1);

  PasswordRecord rec(int id, String pw, {int ageDays = 10}) => PasswordRecord(
        id: id,
        title: 'Site $id',
        password: pw,
        passwordUpdatedAt: now.subtract(Duration(days: ageDays)),
      );

  const strongA = 'q7#Lm2!vXp9\$Kd4@Rz8w';
  const strongB = 'Zt5&nB1*hY6^Wc3(Ve0u';

  test('empty vault has no score', () {
    final r = analyzer.analyze(const [], now: now);
    expect(r.total, 0);
    expect(r.score, isNull);
    expect(r.scoreLabel, 'No data');
  });

  test('unique strong recent passwords score 100', () {
    final r = analyzer.analyze([rec(1, strongA), rec(2, strongB)], now: now);
    expect(r.score, 100);
    expect(r.strongCount, 2);
    expect(r.weakCount, 0);
    expect(r.reusedCount, 0);
    expect(r.oldCount, 0);
    expect(r.needsUpdateIds, isEmpty);
    expect(r.scoreLabel, 'Excellent');
  });

  test('flags weak passwords', () {
    final r = analyzer.analyze(
        [rec(1, 'password1'), rec(2, '12345678'), rec(3, strongA)],
        now: now);
    expect(r.weakIds, containsAll([1, 2]));
    expect(r.weakIds, isNot(contains(3)));
    expect(r.strongIds, [3]);
  });

  test('flags reused passwords and groups them', () {
    final r = analyzer.analyze(
        [rec(1, strongA), rec(2, strongA), rec(3, strongB), rec(4, strongA)],
        now: now);
    expect(r.reusedIds.toSet(), {1, 2, 4});
    expect(r.reuseGroups.length, 1);
    expect(r.reuseGroups.first.toSet(), {1, 2, 4});
    expect(r.reusedIds, isNot(contains(3)));
  });

  test('flags old passwords relative to the injected clock', () {
    final r = analyzer.analyze(
        [rec(1, strongA, ageDays: 200), rec(2, strongB, ageDays: 30)],
        now: now);
    expect(r.oldIds, [1]);
    expect(r.needsUpdateIds, {1});
  });

  test('score drops with problems and is clamped to 0..100', () {
    final healthy = analyzer.analyze([rec(1, strongA)], now: now).score!;
    final oneWeak =
        analyzer.analyze([rec(1, strongA), rec(2, 'password1')], now: now).score!;
    expect(oneWeak, lessThan(healthy));
    expect(oneWeak, 60); // average penalty 0.4

    final worst = analyzer.analyze(
        [rec(1, '123', ageDays: 999), rec(2, '123', ageDays: 999)],
        now: now);
    expect(worst.score, 0);
    expect(worst.scoreLabel, 'At risk');
  });

  test('report keeps ids only, never passwords', () {
    final r = analyzer.analyze([rec(1, strongA)], now: now);
    expect(r.toString().contains(strongA), isFalse);
  });
}

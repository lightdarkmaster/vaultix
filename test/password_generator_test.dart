import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vaultix/features/password_generator/domain/password_generator.dart';

void main() {
  final gen = PasswordGenerator();

  test('respects requested length, including the limits', () {
    for (final n in [8, 20, 64]) {
      expect(gen.generate(GeneratorOptions(length: n)).length, n);
    }
  });

  test('copyWith clamps length to 8..64', () {
    expect(const GeneratorOptions().copyWith(length: 3).length, 8);
    expect(const GeneratorOptions().copyWith(length: 500).length, 64);
  });

  test('every selected character type appears at least once', () {
    for (var i = 0; i < 300; i++) {
      final p = gen.generate(const GeneratorOptions(length: 8));
      expect(RegExp(r'[a-z]').hasMatch(p), isTrue, reason: p);
      expect(RegExp(r'[A-Z]').hasMatch(p), isTrue, reason: p);
      expect(RegExp(r'[0-9]').hasMatch(p), isTrue, reason: p);
      expect(RegExp(r'[^A-Za-z0-9]').hasMatch(p), isTrue, reason: p);
    }
  });

  test('only selected character types are used', () {
    final p = gen.generate(const GeneratorOptions(
        length: 64, upper: false, lower: true, digits: true, symbols: false));
    expect(RegExp(r'^[a-z0-9]+$').hasMatch(p), isTrue);
    final digitsOnly = gen.generate(const GeneratorOptions(
        length: 30, upper: false, lower: false, digits: true, symbols: false));
    expect(RegExp(r'^[0-9]+$').hasMatch(digitsOnly), isTrue);
  });

  test('exclude similar removes confusable characters', () {
    for (var i = 0; i < 200; i++) {
      final p = gen.generate(
          const GeneratorOptions(length: 64, excludeSimilar: true));
      expect(RegExp(r'[Il1L|O0o]').hasMatch(p), isFalse, reason: p);
    }
  });

  test('throws when no character type is selected', () {
    expect(
      () => gen.generate(const GeneratorOptions(
          upper: false, lower: false, digits: false, symbols: false)),
      throwsArgumentError,
    );
  });

  test('passwords are unique and positions are shuffled', () {
    final seen = <String>{};
    for (var i = 0; i < 1000; i++) {
      seen.add(gen.generate(const GeneratorOptions(length: 16)));
    }
    expect(seen.length, 1000);

    // The guaranteed symbol should not always land in the same slot.
    final symbolPositions = <int>{};
    for (var i = 0; i < 300; i++) {
      final p = gen.generate(const GeneratorOptions(
          length: 8, upper: false, lower: true, digits: false, symbols: true));
      symbolPositions.addAll([
        for (var k = 0; k < p.length; k++)
          if (RegExp(r'[^a-z]').hasMatch(p[k])) k
      ]);
    }
    expect(symbolPositions.length, greaterThan(4));
  });

  test('a seeded Random makes output reproducible (injection works)', () {
    final a = PasswordGenerator(Random(7)).generate(const GeneratorOptions());
    final b = PasswordGenerator(Random(7)).generate(const GeneratorOptions());
    expect(a, b);
  });

  test('pool size reflects exclusions', () {
    expect(gen.poolSize(const GeneratorOptions()), 26 + 26 + 10 + 25);
    expect(gen.poolSize(const GeneratorOptions(excludeSimilar: true)),
        26 + 26 + 10 + 25 - 8 + 1); // '|' is not in the symbol pool
  });
}

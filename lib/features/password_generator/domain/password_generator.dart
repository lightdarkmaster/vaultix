import 'dart:math';

class GeneratorOptions {
  const GeneratorOptions({
    this.length = 20,
    this.upper = true,
    this.lower = true,
    this.digits = true,
    this.symbols = true,
    this.excludeSimilar = false,
  });

  static const minLength = 8;
  static const maxLength = 64;

  final int length;
  final bool upper;
  final bool lower;
  final bool digits;
  final bool symbols;
  final bool excludeSimilar;

  bool get hasAnyPool => upper || lower || digits || symbols;

  int get activePoolCount =>
      [upper, lower, digits, symbols].where((e) => e).length;

  GeneratorOptions copyWith({
    int? length,
    bool? upper,
    bool? lower,
    bool? digits,
    bool? symbols,
    bool? excludeSimilar,
  }) =>
      GeneratorOptions(
        length: max(minLength, min(maxLength, length ?? this.length)),
        upper: upper ?? this.upper,
        lower: lower ?? this.lower,
        digits: digits ?? this.digits,
        symbols: symbols ?? this.symbols,
        excludeSimilar: excludeSimilar ?? this.excludeSimilar,
      );
}

/// Generates random passwords with a cryptographically secure RNG
/// (`Random.secure()`, backed by the OS CSPRNG).
///
/// Every selected character class appears at least once, the remaining
/// positions are drawn uniformly from the combined pool, and the result is
/// shuffled with Fisher-Yates so the guaranteed characters are not predictable
/// positions.
class PasswordGenerator {
  PasswordGenerator([Random? random]) : _random = random ?? Random.secure();

  final Random _random;

  static const lowerChars = 'abcdefghijklmnopqrstuvwxyz';
  static const upperChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const digitChars = '0123456789';
  static const symbolChars = r'!@#$%^&*()-_=+[]{};:,.<>?';

  /// Characters that are easy to confuse when read or typed.
  static const similarChars = 'Il1L|O0o';

  List<String> _pools(GeneratorOptions o) {
    String clean(String pool) => o.excludeSimilar
        ? pool.split('').where((c) => !similarChars.contains(c)).join()
        : pool;
    return [
      if (o.lower) clean(lowerChars),
      if (o.upper) clean(upperChars),
      if (o.digits) clean(digitChars),
      if (o.symbols) clean(symbolChars),
    ];
  }

  /// Size of the combined character pool (used for entropy estimates).
  int poolSize(GeneratorOptions o) => _pools(o).join().length;

  String generate(GeneratorOptions o) {
    final pools = _pools(o);
    if (pools.isEmpty) {
      throw ArgumentError('Select at least one character type');
    }
    final all = pools.join();
    final length = max(o.length, pools.length);

    final chars = <String>[
      for (final p in pools) p[_random.nextInt(p.length)],
    ];
    while (chars.length < length) {
      chars.add(all[_random.nextInt(all.length)]);
    }
    for (var i = chars.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = chars[i];
      chars[i] = chars[j];
      chars[j] = tmp;
    }
    return chars.join();
  }
}

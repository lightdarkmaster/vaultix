import 'dart:math';

enum StrengthLevel { veryWeak, weak, fair, good, strong }

class PasswordStrength {
  const PasswordStrength(this.level, this.entropyBits);

  final StrengthLevel level;
  final double entropyBits;

  int get score => level.index;
  String get label =>
      const ['Very weak', 'Weak', 'Fair', 'Good', 'Strong'][score];
  bool get isAcceptable => score >= StrengthLevel.fair.index;
}

const _commonFragments = [
  'password', 'qwerty', 'letmein', 'welcome', 'admin', 'login', 'iloveyou',
  '123456', '111111', 'abc123', 'dragon', 'monkey', 'football', 'secret',
];

/// Local, offline heuristic: character-pool entropy with penalties for
/// repetition, sequences and common words. Nothing leaves the device.
PasswordStrength estimatePasswordStrength(String password) {
  if (password.isEmpty) {
    return const PasswordStrength(StrengthLevel.veryWeak, 0);
  }
  var pool = 0;
  if (RegExp(r'[a-z]').hasMatch(password)) pool += 26;
  if (RegExp(r'[A-Z]').hasMatch(password)) pool += 26;
  if (RegExp(r'[0-9]').hasMatch(password)) pool += 10;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) pool += 33;

  final runes = password.runes.toList();
  final distinct = runes.toSet().length;
  final effectiveLength = distinct + (runes.length - distinct) * 0.25;
  var bits = effectiveLength * (log(pool) / ln2);

  bits -= _sequenceCount(runes) * 3.0;

  final lower = password.toLowerCase();
  for (final fragment in _commonFragments) {
    if (lower.contains(fragment)) {
      bits -= 20;
      break;
    }
  }
  bits = max(0, bits);

  final level = bits < 28
      ? StrengthLevel.veryWeak
      : bits < 36
          ? StrengthLevel.weak
          : bits < 60
              ? StrengthLevel.fair
              : bits < 80
                  ? StrengthLevel.good
                  : StrengthLevel.strong;
  return PasswordStrength(level, bits);
}

int _sequenceCount(List<int> r) {
  var count = 0;
  for (var i = 0; i + 2 < r.length; i++) {
    final d1 = r[i + 1] - r[i];
    final d2 = r[i + 2] - r[i + 1];
    if (d1 == d2 && d1.abs() == 1) count++;
  }
  return count;
}

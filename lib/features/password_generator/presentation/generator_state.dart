import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_provider.dart';
import '../domain/password_generator.dart';

class GeneratorState {
  const GeneratorState(this.options, this.password);
  final GeneratorOptions options;
  final String password;
}

/// autoDispose: the generated password is dropped from memory as soon as no
/// screen is showing it. Options (not secret) persist in SharedPreferences.
class GeneratorNotifier extends AutoDisposeNotifier<GeneratorState> {
  final PasswordGenerator _generator = PasswordGenerator();

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  GeneratorState build() {
    final options = _load();
    return GeneratorState(options, _generator.generate(options));
  }

  GeneratorOptions _load() {
    final p = _prefs;
    final options = const GeneratorOptions().copyWith(
      length: p.getInt(AppConstants.prefGenLength),
      upper: p.getBool(AppConstants.prefGenUpper),
      lower: p.getBool(AppConstants.prefGenLower),
      digits: p.getBool(AppConstants.prefGenDigits),
      symbols: p.getBool(AppConstants.prefGenSymbols),
      excludeSimilar: p.getBool(AppConstants.prefGenExcludeSimilar),
    );
    return options.hasAnyPool ? options : const GeneratorOptions();
  }

  Future<void> _save(GeneratorOptions o) async {
    final p = _prefs;
    await p.setInt(AppConstants.prefGenLength, o.length);
    await p.setBool(AppConstants.prefGenUpper, o.upper);
    await p.setBool(AppConstants.prefGenLower, o.lower);
    await p.setBool(AppConstants.prefGenDigits, o.digits);
    await p.setBool(AppConstants.prefGenSymbols, o.symbols);
    await p.setBool(AppConstants.prefGenExcludeSimilar, o.excludeSimilar);
  }

  /// Applies new options and generates a fresh password. Ignored if it would
  /// leave no character type selected.
  void update(GeneratorOptions options) {
    if (!options.hasAnyPool) return;
    state = GeneratorState(options, _generator.generate(options));
    _save(options);
  }

  void regenerate() =>
      state = GeneratorState(state.options, _generator.generate(state.options));
}

final generatorProvider =
    NotifierProvider.autoDispose<GeneratorNotifier, GeneratorState>(
  GeneratorNotifier.new,
);

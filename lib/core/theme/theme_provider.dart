import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import 'app_colors.dart';

/// Overridden in main() with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

class ThemeSettings {
  const ThemeSettings({required this.themeMode, required this.accent});

  final ThemeMode themeMode;
  final Color accent;

  ThemeSettings copyWith({ThemeMode? themeMode, Color? accent}) =>
      ThemeSettings(
        themeMode: themeMode ?? this.themeMode,
        accent: accent ?? this.accent,
      );
}

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  late final SharedPreferences _prefs;

  @override
  ThemeSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final modeIndex = _prefs.getInt(AppConstants.prefThemeMode);
    final accentValue = _prefs.getInt(AppConstants.prefAccentColor);
    return ThemeSettings(
      themeMode: (modeIndex != null &&
              modeIndex >= 0 &&
              modeIndex < ThemeMode.values.length)
          ? ThemeMode.values[modeIndex]
          : ThemeMode.system,
      accent: accentValue != null ? Color(accentValue) : AppColors.primary,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt(AppConstants.prefThemeMode, mode.index);
  }

  Future<void> setAccent(Color color) async {
    state = state.copyWith(accent: color);
    await _prefs.setInt(AppConstants.prefAccentColor, color.toARGB32());
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  ThemeSettingsNotifier.new,
);

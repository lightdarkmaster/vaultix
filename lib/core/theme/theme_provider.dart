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
  const ThemeSettings({
    required this.themeMode,
    required this.accent,
    this.amoledDark = false,
  });

  final ThemeMode themeMode;
  final Color accent;
  final bool amoledDark;

  ThemeSettings copyWith({
    ThemeMode? themeMode,
    Color? accent,
    bool? amoledDark,
  }) =>
      ThemeSettings(
        themeMode: themeMode ?? this.themeMode,
        accent: accent ?? this.accent,
        amoledDark: amoledDark ?? this.amoledDark,
      );
}

class ThemeSettingsNotifier extends Notifier<ThemeSettings> {
  late final SharedPreferences _prefs;

  @override
  ThemeSettings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final modeIndex = _prefs.getInt(AppConstants.prefThemeMode);
    final accentValue = _prefs.getInt(AppConstants.prefAccentColor);
    final amoledDark = _prefs.getBool(AppConstants.prefAmoledDark) ?? false;
    return ThemeSettings(
      themeMode: ThemeMode.values[modeIndex ?? ThemeMode.system.index],
      accent: accentValue != null ? Color(accentValue) : AppColors.primary,
      amoledDark: amoledDark,
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

  Future<void> setAmoledDark(bool value) async {
    state = state.copyWith(amoledDark: value);
    await _prefs.setBool(AppConstants.prefAmoledDark, value);
  }
}

final themeSettingsProvider =
    NotifierProvider<ThemeSettingsNotifier, ThemeSettings>(
  ThemeSettingsNotifier.new,
);

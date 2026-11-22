import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF7655E8);
  static const secondary = Color(0xFF536DFE);

  static const backgroundDark = Color(0xFF101116);
  static const surfaceDark = Color(0xFF1B1C24);
  static const backgroundLight = Color(0xFFF7F7FB);
  static const surfaceLight = Color(0xFFFFFFFF);

  static const success = Color(0xFF20B486);
  static const warning = Color(0xFFF4B740);
  static const error = Color(0xFFE65B65);

  /// Accent colors the user can pick from in Settings.
  static const accentOptions = <Color>[
    primary,
    secondary,
    Color(0xFF20B486),
    Color(0xFFE65B65),
    Color(0xFFF4B740),
    Color(0xFFE8559B),
    Color(0xFF14A3C7),
  ];
}

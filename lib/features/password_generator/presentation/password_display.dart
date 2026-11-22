import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Monospace password with digits and symbols tinted so it is easy to read.
class PasswordDisplay extends StatelessWidget {
  const PasswordDisplay({super.key, required this.password, this.fontSize = 24});

  final String password;
  final double fontSize;

  static final _digit = RegExp(r'[0-9]');
  static final _letter = RegExp(r'[A-Za-z]');

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          for (final ch in password.split(''))
            TextSpan(
              text: ch,
              style: _digit.hasMatch(ch)
                  ? const TextStyle(color: AppColors.secondary)
                  : _letter.hasMatch(ch)
                      ? null
                      : const TextStyle(color: AppColors.error),
            ),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        height: 1.4,
        letterSpacing: 0.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

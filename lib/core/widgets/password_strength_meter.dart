import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/password_strength.dart';

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final s = estimatePasswordStrength(password);
    final color = switch (s.level) {
      StrengthLevel.veryWeak || StrengthLevel.weak => AppColors.error,
      StrengthLevel.fair => AppColors.warning,
      StrengthLevel.good || StrengthLevel.strong => AppColors.success,
    };
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: (s.score + 1) / 5),
                duration: const Duration(milliseconds: 250),
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 8,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(s.label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

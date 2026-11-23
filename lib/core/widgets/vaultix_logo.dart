import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The Vaultix mark: white shield with a keyhole on the brand gradient.
class VaultixLogo extends StatelessWidget {
  const VaultixLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.secondary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.shield_rounded, size: size * 0.62, color: Colors.white),
          Padding(
            padding: EdgeInsets.only(bottom: size * 0.02),
            child: Icon(Icons.lock_rounded,
                size: size * 0.26, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

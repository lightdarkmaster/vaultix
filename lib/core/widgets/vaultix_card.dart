import 'package:flutter/material.dart';

import 'glass.dart';

class VaultixCard extends StatelessWidget {
  const VaultixCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderRadius = 22,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = scheme.primary;
    final card = GlassSurface(
      borderRadius: borderRadius,
      padding: padding,
      onTap: onTap,
      color: color ??
          Color.lerp(
            isDark ? const Color(0xFF1A1F2B) : Colors.white,
            accent,
            isDark ? 0.10 : 0.06,
          )!
              .withValues(alpha: isDark ? 0.72 : 0.74),
      borderOpacity: isDark ? 0.22 : 0.45,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.045),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: accent.withValues(alpha: isDark ? 0.08 : 0.05),
          blurRadius: 24,
          offset: const Offset(0, 2),
        ),
      ],
      child: child,
    );

    if (onTap == null) return card;
    return PressableScale(child: card);
  }
}

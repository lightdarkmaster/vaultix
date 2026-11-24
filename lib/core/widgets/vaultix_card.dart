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
    final card = GlassSurface(
      borderRadius: borderRadius,
      padding: padding,
      onTap: onTap,
      color: color ??
          (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.62)),
      borderOpacity: isDark ? 0.14 : 0.5,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.045),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        if (!isDark)
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.03),
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

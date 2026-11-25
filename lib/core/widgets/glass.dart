import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A reusable glassmorphism surface.
///
/// Uses a subtle blur by default only for floating surfaces (nav/dialog/sheet)
/// to avoid expensive backdrop filters in long scrolling lists.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 22,
    this.blurSigma = 0,
    this.opacity,
    this.borderOpacity,
    this.color,
    this.onTap,
    this.gradient,
    this.shadows,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurSigma;
  final double? opacity;
  final double? borderOpacity;
  final Color? color;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final List<BoxShadow>? shadows;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(borderRadius);
    final baseOpacity = opacity ?? (isDark ? 0.16 : 0.62);
    final baseBorderOpacity = borderOpacity ?? (isDark ? 0.18 : 0.45);
    final fill = color ??
        (isDark ? Colors.white.withValues(alpha: baseOpacity) : Colors.white.withValues(alpha: baseOpacity));
    final borderColor = (isDark ? Colors.white : scheme.outlineVariant)
        .withValues(alpha: baseBorderOpacity);

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: gradient,
        color: gradient == null ? fill : null,
        border: Border.all(color: borderColor, width: 1),
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                blurRadius: isDark ? 24 : 18,
                offset: const Offset(0, 8),
              ),
            ],
      ),
      child: child,
    );

    if (blurSigma > 0) {
      content = RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          clipBehavior: clipBehavior,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: content,
          ),
        ),
      );
    } else {
      content = ClipRRect(borderRadius: radius, clipBehavior: clipBehavior, child: content);
    }

    if (onTap != null) {
      content = Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }
    return content;
  }
}

class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;
    final amoled = isDark && theme.colorScheme.surface == Colors.black;
    final bg = isDark
        ? (amoled ? Colors.black : AppColors.backgroundDark)
        : AppColors.backgroundLight;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? (amoled
                  ? [Colors.black, Color.lerp(Colors.black, accent, 0.08)!, Colors.black]
                  : [
                      bg,
                      Color.lerp(bg, accent, 0.10)!,
                      Color.lerp(bg, const Color(0xFF0B1020), 0.55)!,
                    ])
              : [
                  Color.lerp(bg, accent, 0.05)!,
                  bg,
                  Color.lerp(bg, accent, 0.08)!,
                ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, -0.8),
                  radius: 1.1,
                  colors: [
                    accent.withValues(alpha: isDark ? (amoled ? 0.10 : 0.18) : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.9, 0.9),
                  radius: 1.2,
                  colors: [
                    theme.colorScheme.secondary.withValues(alpha: isDark ? (amoled ? 0.06 : 0.12) : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.98,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;
  final Duration duration;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed && widget.enabled ? widget.pressedScale : 1,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

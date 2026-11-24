import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = <_NavSpec>[
    _NavSpec(icon: Icons.home_outlined, selected: Icons.home_rounded, label: 'Home'),
    _NavSpec(icon: Icons.lock_outline_rounded, selected: Icons.lock_rounded, label: 'Vault'),
    _NavSpec(icon: Icons.password_outlined, selected: Icons.password_rounded, label: 'Generator'),
    _NavSpec(icon: Icons.settings_outlined, selected: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      // GoRouter's StatefulShellRoute owns branch state. Wrapping it in a
      // keyed AnimatedSwitcher would recreate the shell on every tab change
      // and discard cached branch pages, so keep it stable.
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: EdgeInsets.fromLTRB(16, 8, 16, bottomInset > 0 ? 10 : 14),
        child: _GlassNavBar(
          selectedIndex: navigationShell.currentIndex,
          items: _items,
          onSelected: (i) {
            if (i == navigationShell.currentIndex) {
              navigationShell.goBranch(i, initialLocation: true);
              return;
            }
            HapticFeedback.selectionClick();
            navigationShell.goBranch(i);
          },
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec({required this.icon, required this.selected, required this.label});
  final IconData icon;
  final IconData selected;
  final String label;
}

class _GlassNavBar extends StatelessWidget {
  const _GlassNavBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<_NavSpec> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(30);

    final glassColor = isDark
        ? const Color(0xFF171B24).withValues(alpha: 0.58)
        : Colors.white.withValues(alpha: 0.58);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.72);

    return Align(
      alignment: Alignment.bottomCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                color: glassColor,
                border: Border.all(color: borderColor, width: 1),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (isDark ? Colors.white : Colors.white).withValues(alpha: isDark ? 0.08 : 0.45),
                    (isDark ? Colors.white : scheme.primary).withValues(alpha: isDark ? 0.02 : 0.04),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: isDark ? 0.10 : 0.07),
                    blurRadius: 20,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / items.length;
                    const barHeight = 66.0;
                    const indicatorInsetX = 5.0;
                    const indicatorInsetY = 4.0;
                    return SizedBox(
                      height: barHeight,
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 360),
                            curve: Curves.easeOutCubic,
                            left: selectedIndex * itemWidth + indicatorInsetX,
                            top: indicatorInsetY,
                            width: itemWidth - indicatorInsetX * 2,
                            height: barHeight - indicatorInsetY * 2,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      scheme.primary.withValues(alpha: isDark ? 0.30 : 0.18),
                                      scheme.secondary.withValues(alpha: isDark ? 0.18 : 0.10),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: scheme.primary.withValues(alpha: isDark ? 0.30 : 0.20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < items.length; i++)
                                Expanded(
                                  child: _NavItem(
                                    spec: items[i],
                                    selected: i == selectedIndex,
                                    onTap: () => onSelected(i),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({required this.spec, required this.selected, required this.onTap});

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final selected = widget.selected;
    final activeColor = scheme.primary;
    final inactiveColor = scheme.onSurface.withValues(alpha: isDark ? 0.62 : 0.58);
    final color = selected ? activeColor : inactiveColor;

    return Semantics(
      button: true,
      selected: selected,
      label: widget.spec.label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          type: MaterialType.transparency,
          child: InkResponse(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            radius: 34,
            containedInkWell: true,
            highlightShape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(22),
            splashColor: scheme.primary.withValues(alpha: 0.10),
            highlightColor: scheme.primary.withValues(alpha: 0.06),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              scale: _pressed ? 0.96 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutBack,
                      scale: selected ? 1.08 : 1.0,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: Icon(
                          selected ? widget.spec.selected : widget.spec.icon,
                          key: ValueKey<bool>(selected),
                          size: 24,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      offset: selected ? Offset.zero : const Offset(0, 0.08),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.1,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: color,
                          letterSpacing: 0.1,
                        ),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          opacity: selected ? 1 : 0.92,
                          child: Text(
                            widget.spec.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

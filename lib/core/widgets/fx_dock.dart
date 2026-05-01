import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/brand_palette.dart';
import '../theme/design_tokens.dart';
import 'fx_icon.dart';

/// Floating glass dock — design spec: iOS 26 style, 5 tabs, backdrop blur 24px.
///
/// Positioned by [MainShell] at bottom: safeArea + 18px, left/right: 14px.
/// Background: dark rgba(20,26,48,0.72) / light rgba(255,255,255,0.78).
/// Border: 0.5px, borderRadius: 28, shadow: 0 16px 48px -12px rgba(0,0,0,0.32).
class FxDock extends StatelessWidget {
  const FxDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  static const _items = [
    _FxDockItem(icon: 'home', label: 'Hoje'),
    _FxDockItem(icon: 'users', label: 'Alunos'),
    _FxDockItem(icon: 'dumbbell', label: 'Treinos'),
    _FxDockItem(icon: 'calendar', label: 'Agenda'),
    _FxDockItem(icon: 'spark', label: 'IA'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bgColor = isDark
        ? const Color.fromRGBO(20, 26, 48, 0.72)
        : const Color.fromRGBO(255, 255, 255, 0.78);
    final borderColor = isDark
        ? const Color.fromRGBO(255, 255, 255, 0.12)
        : const Color.fromRGBO(0, 0, 0, 0.06);
    final inactiveColor =
        (isDark ? EagleTokens.darkInk : EagleTokens.ink).withValues(alpha: 0.45);

    // Shadow is on the outer container; ClipRRect clips content only.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.32),
            blurRadius: 48,
            offset: Offset(0, 16),
            spreadRadius: -12,
          ),
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.18),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 14),
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final active = i == currentIndex;
                final color = active ? primary : inactiveColor;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 44,
                          height: 30,
                          decoration: BoxDecoration(
                            color: active
                                ? BrandPalette.soft(primary, dark: isDark)
                                    .withValues(alpha: isDark ? 0.42 : 0.72)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: FxIcon(
                              name: item.icon,
                              size: 22,
                              color: color,
                              strokeWidth: active ? 2.2 : 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _FxDockItem {
  final String icon;
  final String label;
  const _FxDockItem({required this.icon, required this.label});
}

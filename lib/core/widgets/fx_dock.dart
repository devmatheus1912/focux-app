import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/brand_palette.dart';
import '../theme/design_tokens.dart';
import '../theme/tokens_strip.dart';
import 'fx_icon.dart';

class FxDockItem {
  final String icon;
  final String label;

  const FxDockItem({required this.icon, required this.label});
}

class FxDockItems {
  static const personal = [
    FxDockItem(icon: 'home', label: 'Hoje'),
    FxDockItem(icon: 'users', label: 'Alunos'),
    FxDockItem(icon: 'dumbbell', label: 'Treinos'),
    FxDockItem(icon: 'calendar', label: 'Agenda'),
    FxDockItem(icon: 'spark', label: 'IA'),
  ];

  static const aluno = [
    FxDockItem(icon: 'home', label: 'Hoje'),
    FxDockItem(icon: 'dumbbell', label: 'Treinos'),
    FxDockItem(icon: 'trend', label: 'Saúde'),
    FxDockItem(icon: 'users', label: 'Perfil'),
  ];
}

/// Floating glass dock — cinematic redesign with brand dot indicator.
class FxDock extends StatelessWidget {
  const FxDock({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    this.cinematicChrome = false,
  });

  final List<FxDockItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final bool cinematicChrome;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;

    final onCinematic = cinematicChrome || isDark;

    final bgColor =
        onCinematic
            ? isDark
                ? EagleTokens.darkCard.withValues(alpha: 0.78)
                : Colors.white.withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.75);
    final inactiveColor = (isDark ? EagleTokens.darkInk : EagleTokens.ink)
        .withValues(alpha: 0.40);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensStrip.rXl),
        boxShadow: [
          ...TokensStrip.elevation(16, dark: isDark, accent: primary),
          if (onCinematic)
            ...TokensStrip.interactiveGlow(
              primary,
              intensity: 0.35,
              dark: isDark,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokensStrip.rXl),
        child: BackdropFilter(
          filter: TokensStrip.blurFilter(TokensStrip.blurHeavy),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(TokensStrip.rXl),
              border: Border.all(
                color: TokensStrip.glassBorder(dark: isDark, accent: primary),
                width: 0.8,
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              6,
              compact ? 7 : 8,
              6,
              compact ? 9 : 11,
            ),
            child: Row(
              children: List.generate(items.length, (i) {
                final item = items[i];
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
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: compact ? 38 : 44,
                          height: compact ? 28 : 30,
                          decoration: BoxDecoration(
                            color:
                                active
                                    ? BrandPalette.soft(
                                      primary,
                                      dark: onCinematic,
                                    ).withValues(alpha: onCinematic ? 0.48 : 0.78)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(TokensStrip.rPill),
                            boxShadow:
                                active
                                    ? TokensStrip.interactiveGlow(
                                      primary,
                                      intensity: 0.45,
                                      dark: isDark,
                                    )
                                    : null,
                          ),
                          child: Center(
                            child: FxIcon(
                              name: item.icon,
                              size: compact ? 20 : 22,
                              color: color,
                              strokeWidth: active ? 2.2 : 1.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: GoogleFonts.outfit(
                            fontSize: compact ? 9 : 10,
                            fontWeight: FontWeight.w600,
                            color: color,
                            height: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // ── Active dot indicator ──────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(top: 3),
                          width: active ? 4 : 0,
                          height: active ? 4 : 0,
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
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

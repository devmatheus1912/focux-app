import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_typography.dart';
import '../theme/brand_palette.dart';
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

/// Floating glass bottom navigation — TOKENS STRIP liquid chrome.
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

    final surface = TokensStrip.glassFill(
      dark: isDark,
      opacity: isDark ? 0.90 : 0.94,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensStrip.rXl),
        boxShadow: [
          ...TokensStrip.elevation(12, dark: isDark, accent: primary),
          ...TokensStrip.coloredDepthGlow(primary, strength: 0.18),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokensStrip.rXl),
        child: BackdropFilter(
          filter: TokensStrip.blurFilter(TokensStrip.blurHeavy),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(TokensStrip.rXl),
              border: Border.all(
                color: TokensStrip.glassBorder(dark: isDark, accent: primary),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.06 : 0.55),
                  Colors.transparent,
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                TokensStrip.s2,
                compact ? TokensStrip.s2 : 10,
                TokensStrip.s2,
                compact ? 10 : TokensStrip.s3,
              ),
              child: Row(
                children: List.generate(items.length, (i) {
                  return Expanded(
                    child: _FxDockNavItem(
                      item: items[i],
                      active: i == currentIndex,
                      isDark: isDark,
                      primary: primary,
                      compact: compact,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FxDockNavItem extends StatefulWidget {
  const _FxDockNavItem({
    required this.item,
    required this.active,
    required this.isDark,
    required this.primary,
    required this.compact,
    required this.onTap,
  });

  final FxDockItem item;
  final bool active;
  final bool isDark;
  final Color primary;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_FxDockNavItem> createState() => _FxDockNavItemState();
}

class _FxDockNavItemState extends State<_FxDockNavItem> {
  bool _pressed = false;

  Color get _activePillFill {
    if (!widget.active) return Colors.transparent;
    // Glow radial (ref.): pill suave nos dois temas, sem manchar o glass.
    if (widget.isDark) {
      return BrandPalette.soft(widget.primary, dark: true).withValues(
        alpha: 0.38,
      );
    }
    return widget.primary.withValues(alpha: 0.12);
  }

  @override
  Widget build(BuildContext context) {
    final inactive = TokensStrip.textSecondary.withValues(
      alpha: widget.isDark ? 0.78 : 0.68,
    );
    final color = widget.active ? widget.primary : inactive;
    final iconSize = widget.compact ? 21.0 : 22.0;
    final labelSize = widget.compact ? 10.5 : 11.0;

    return Semantics(
      button: true,
      selected: widget.active,
      label: widget.item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          splashColor: widget.primary.withValues(alpha: 0.12),
          highlightColor: widget.primary.withValues(alpha: 0.06),
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      width: widget.compact ? 40 : 44,
                      height: widget.compact ? 30 : 32,
                      decoration: BoxDecoration(
                        color: _activePillFill,
                        borderRadius: BorderRadius.circular(TokensStrip.rPill),
                        boxShadow:
                            widget.active
                                ? [
                                  BoxShadow(
                                    color: widget.primary.withValues(
                                      alpha: widget.isDark ? 0.55 : 0.32,
                                    ),
                                    blurRadius: widget.isDark ? 18 : 14,
                                    spreadRadius: widget.isDark ? 1 : 0,
                                  ),
                                  ...TokensStrip.interactiveGlow(
                                    widget.primary,
                                    intensity: widget.isDark ? 0.42 : 0.28,
                                    dark: widget.isDark,
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child: FxIcon(
                          name: widget.item.icon,
                          size: iconSize,
                          color: color,
                          strokeWidth: widget.active ? 2.3 : 1.75,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.item.label,
                      style: AppTypography.inter(
                        fontSize: labelSize,
                        fontWeight:
                            widget.active ? FontWeight.w700 : FontWeight.w600,
                        color: color,
                        height: 1.1,
                        letterSpacing: widget.active ? 0.1 : 0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 5),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      width: widget.active ? 18 : 0,
                      height: widget.active ? 3 : 0,
                      decoration: BoxDecoration(
                        color: widget.primary,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow:
                            widget.active
                                ? TokensStrip.coloredDepthGlow(
                                  widget.primary,
                                  strength: 0.55,
                                )
                                : null,
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

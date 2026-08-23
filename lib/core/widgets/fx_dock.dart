import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/focux_hub_typography.dart';
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

/// Dock flutuante — glass profissional, ativo preciso (claro/escuro).
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

  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;

    final surface = TokensStrip.glassFill(
      dark: isDark,
      opacity: isDark ? (cinematicChrome ? 0.88 : 0.92) : 0.92,
    );
    final border = TokensStrip.glassBorder(dark: isDark, accent: primary)
        .withValues(alpha: isDark ? 0.42 : 0.55);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.42 : 0.10),
            blurRadius: isDark ? 28 : 22,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 28,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: BackdropFilter(
          filter: TokensStrip.blurFilter(TokensStrip.blurHeavy),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(_radius),
              border: Border.all(color: border, width: 0.85),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.07 : 0.42),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                TokensStrip.s2,
                compact ? 8 : 9,
                TokensStrip.s2,
                compact ? 8 : 9,
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

  @override
  Widget build(BuildContext context) {
    final inactive = widget.isDark
        ? TokensStrip.textSecondary.withValues(alpha: 0.72)
        : const Color(0xFF5B6B76);
    final color = widget.active ? widget.primary : inactive;
    final iconSize = widget.compact ? 20.0 : 21.0;
    final labelSize = widget.compact ? 10.0 : 10.5;
    final glowSize = widget.compact ? 34.0 : 36.0;

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
          splashColor: widget.primary.withValues(alpha: 0.10),
          highlightColor: widget.primary.withValues(alpha: 0.05),
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: glowSize,
                      height: glowSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedOpacity(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            opacity: widget.active ? 1 : 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    widget.primary.withValues(
                                      alpha: widget.isDark ? 0.38 : 0.22,
                                    ),
                                    widget.primary.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                              child: SizedBox(
                                width: glowSize,
                                height: glowSize,
                              ),
                            ),
                          ),
                          FxIcon(
                            name: widget.item.icon,
                            size: iconSize,
                            color: color,
                            strokeWidth: widget.active ? 2.05 : 1.7,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.label,
                      style: FocuxHubTypography.chip(color).copyWith(
                        fontSize: labelSize,
                        fontWeight:
                            widget.active ? FontWeight.w700 : FontWeight.w600,
                        height: 1.05,
                        letterSpacing: widget.active ? 0.15 : 0.05,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    SizedBox(
                      height: 3,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: widget.active ? 16 : 0,
                          height: 3,
                          decoration: BoxDecoration(
                            color: widget.primary,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow:
                                widget.active
                                    ? [
                                      BoxShadow(
                                        color: widget.primary.withValues(
                                          alpha: 0.45,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                    : null,
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

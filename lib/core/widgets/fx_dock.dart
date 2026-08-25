import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/fx_settings_layout.dart';
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

/// Dock flutuante — glass da marca, anatomia de tab bar iOS (sem poço/underline).
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

  static const double floatGap = 10;
  static const double sideInset = FxSettingsLayout.pageInset;

  static double barHeight({required bool compact}) => compact ? 56 : 58;

  static double shellClearance({
    required double bottomInset,
    required bool compact,
  }) =>
      bottomInset + floatGap + barHeight(compact: compact) + 8;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;

    final surface = TokensStrip.glassFill(
      dark: isDark,
      opacity: isDark ? (cinematicChrome ? 0.88 : 0.92) : 0.94,
    );
    final border = TokensStrip.glassBorder(dark: isDark, accent: primary)
        .withValues(alpha: isDark ? 0.36 : 0.40);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.36 : 0.08),
            blurRadius: isDark ? 18 : 14,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
        child: BackdropFilter(
          filter: TokensStrip.blurFilter(TokensStrip.blurHeavy),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(
                FxSettingsLayout.groupRadius,
              ),
              border: Border.all(color: border, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TokensStrip.s1,
                vertical: 6,
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

    return Semantics(
      button: true,
      selected: widget.active,
      label: widget.item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(FxSettingsLayout.groupRadius),
          splashColor: widget.primary.withValues(alpha: 0.08),
          highlightColor: widget.primary.withValues(alpha: 0.04),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FxIcon(
                      name: widget.item.icon,
                      size: FxSettingsLayout.iconSize,
                      color: color,
                      strokeWidth: widget.active ? 2.0 : 1.7,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.label,
                      style: FocuxHubTypography.chip(color).copyWith(
                        fontSize: widget.compact ? 10.0 : 10.5,
                        fontWeight:
                            widget.active ? FontWeight.w700 : FontWeight.w500,
                        height: 1.05,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
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

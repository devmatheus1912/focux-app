import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_palette.dart';
import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/tokens_strip.dart';

/// Chip toggle inset — paridade Perfil (picker bar / filtros).
class FxToggleChip extends StatelessWidget {
  const FxToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
    this.icon,
    this.showCheckmark = false,
    this.filledWhenSelected = false,
    this.expanded = false,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final bool showCheckmark;
  final bool filledWhenSelected;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;
    final fg = filledWhenSelected && selected ? Colors.white : (selected ? action : ink);

    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$label, selecionado' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            width: expanded ? double.infinity : null,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color:
                  filledWhenSelected && selected
                      ? primary
                      : selected
                      ? action.withValues(alpha: isDark ? 0.22 : 0.12)
                      : (isDark
                          ? EagleTokens.darkCardHi
                          : TokensStrip.cardBg),
              borderRadius: BorderRadius.circular(TokensStrip.rSm),
              border: Border.all(
                color:
                    filledWhenSelected && selected
                        ? primary
                        : selected
                        ? action.withValues(alpha: 0.55)
                        : line.withValues(alpha: isDark ? 0.55 : 0.72),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: FocuxHubTypography.chip(fg).copyWith(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (showCheckmark && selected) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check_rounded, size: 16, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

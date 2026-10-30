import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/focux_hub_typography.dart';
import '../../../../core/theme/tokens_strip.dart';

class ExercisePickerChip extends StatelessWidget {
  const ExercisePickerChip({
    super.key,
    required this.label,
    required this.selected,
    required this.primary,
    required this.isDark,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Semantics(
      button: true,
      toggled: selected,
      label: selected ? '$label, filtro ativo' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            constraints: BoxConstraints(minHeight: 44),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:
                  selected
                      ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
                      : (isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg),
              borderRadius: BorderRadius.circular(TokensStrip.rSm),
              border: Border.all(
                color: selected ? primary : line.withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? primary : ink.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: FocuxHubTypography.bodyMuted(
                      color: selected ? primary : ink,
                      fontWeight: FontWeight.w700,
                    ).copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';

/// Seção de escolha dentro de [FxSettingsGroup] — cadastro/edição de aluno.
class AlunoChoiceSection extends StatelessWidget {
  const AlunoChoiceSection({
    super.key,
    required this.label,
    required this.isDark,
    required this.child,
    this.showDividerAbove = false,
  });

  final String label;
  final bool isDark;
  final Widget child;
  final bool showDividerAbove;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDividerAbove) ...[
          const SizedBox(height: TokensStrip.s3),
          Divider(
            height: 1,
            thickness: FxSettingsLayout.dividerThickness,
            color: line.withValues(alpha: isDark ? 0.55 : 0.7),
          ),
          const SizedBox(height: TokensStrip.s3),
        ] else
          const SizedBox(height: TokensStrip.s2),
        Text(
          label,
          style: FxSettingsLayout.subhead(
            color: mute,
          ).copyWith(fontWeight: FontWeight.w800, fontSize: 11),
        ),
        const SizedBox(height: TokensStrip.s2),
        child,
        const SizedBox(height: TokensStrip.s2),
      ],
    );
  }
}

class AlunoSegmentedChoice extends StatelessWidget {
  const AlunoSegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.isDark,
    required this.onSelect,
  });

  final List<({String value, String label})> options;
  final String? selected;
  final bool isDark;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokensStrip.rSm),
        border: Border.all(color: line.withValues(alpha: isDark ? 0.7 : 0.85)),
      ),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0)
                VerticalDivider(
                  width: 1,
                  thickness: FxSettingsLayout.dividerThickness,
                  color: line.withValues(alpha: isDark ? 0.55 : 0.7),
                ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelect(options[i].value);
                    },
                    borderRadius: BorderRadius.horizontal(
                      left:
                          i == 0
                              ? Radius.circular(TokensStrip.rSm - 1)
                              : Radius.zero,
                      right:
                          i == options.length - 1
                              ? Radius.circular(TokensStrip.rSm - 1)
                              : Radius.zero,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.center,
                      color:
                          selected == options[i].value
                              ? action.withValues(alpha: isDark ? 0.16 : 0.10)
                              : Colors.transparent,
                      child: Text(
                        options[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: FocuxHubTypography.chip(
                          selected == options[i].value ? action : ink,
                        ).copyWith(
                          fontSize: 12,
                          fontWeight:
                              selected == options[i].value
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AlunoOptionChip extends StatelessWidget {
  const AlunoOptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final action = BrandPalette.sectionAction(primary, dark: isDark);
    final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
    final line = isDark ? EagleTokens.darkLine : TokensStrip.borderDefault;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(TokensStrip.rPill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                selected
                    ? action.withValues(alpha: isDark ? 0.16 : 0.10)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(TokensStrip.rPill),
            border: Border.all(
              color:
                  selected
                      ? action.withValues(alpha: 0.5)
                      : line.withValues(alpha: 0.85),
              width: selected ? 1.3 : 1,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.chip(
              selected ? action : ink,
            ).copyWith(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

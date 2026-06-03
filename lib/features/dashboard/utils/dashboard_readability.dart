import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';

/// Texto secundário do dashboard com contraste ≥ 4.5:1 (WCAG AA) em fundos claros.
Color dashboardReadableMuted(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return EagleTokens.darkInkMute.withValues(alpha: 0.92);
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.76);
}

Color dashboardReadableCaption(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return EagleTokens.darkInkMute.withValues(alpha: 0.88);
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.72);
}

/// Texto secundário sobre gradiente teal (hero financeiro) — ≥4.5:1 WCAG AA.
Color dashboardHeroCaptionOnTeal() => Colors.white.withValues(alpha: 0.94);

Color dashboardHeroLabelOnTeal() => Colors.white.withValues(alpha: 0.92);

Color dashboardHeroMutedOnTeal() => Colors.white.withValues(alpha: 0.90);

/// Badge P0/P1/Hoje com contraste AA no card (claro e escuro).
({Color background, Color foreground}) dashboardPriorityBadgeColors({
  required bool isDark,
  required Color accent,
}) {
  if (isDark) {
    return (
      background: accent.withValues(alpha: 0.34),
      foreground: Colors.white.withValues(alpha: 0.96),
    );
  }
  return (
    background: accent.withValues(alpha: 0.14),
    foreground: accent,
  );
}

/// Chip “Ver prioridades” no header quando [isDark].
Color dashboardPrioritiesChipBackground(Color primary, {required bool isDark}) =>
    BrandPalette.soft(primary, dark: isDark).withValues(alpha: isDark ? 0.55 : 1);

Color dashboardPrioritiesChipForeground(Color primary, {required bool isDark}) =>
    isDark
        ? Colors.white.withValues(alpha: 0.96)
        : BrandPalette.sectionAction(primary, dark: false);

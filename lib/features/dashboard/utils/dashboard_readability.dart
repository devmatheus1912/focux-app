import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';

export '../../../core/theme/hero_teal.dart';

/// Texto secundário do dashboard com contraste ≥ 4.5:1 (WCAG AA).
/// Em dark, mistura mute→ink para captions não ficarem “apagadas” no grid.
Color dashboardReadableMuted(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return Color.lerp(EagleTokens.darkInkMute, EagleTokens.darkInk, 0.55)!;
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.88);
}

Color dashboardReadableCaption(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return Color.lerp(EagleTokens.darkInkMute, EagleTokens.darkInk, 0.50)!;
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.88);
}

/// Texto secundário sobre gradiente teal (hero financeiro) — ≥4.5:1 WCAG AA.
Color dashboardHeroCaptionOnTeal() => Colors.white.withValues(alpha: 0.94);

Color dashboardHeroLabelOnTeal() => Colors.white.withValues(alpha: 0.92);

Color dashboardHeroMutedOnTeal() => Colors.white.withValues(alpha: 0.90);

/// Badge P0/P1/Hoje com contraste AA no card (claro e escuro).
({Color background, Color foreground}) dashboardPriorityBadgeColors({
  required bool isDark,
  required Color accent,
  String? badge,
}) {
  final normalized = badge?.trim().toUpperCase();
  if (normalized == 'P0') {
    final warn = EagleTokens.warn;
    if (isDark) {
      return (
        background: warn.withValues(alpha: 0.42),
        foreground: Colors.white,
      );
    }
    // Fundo mais opaco + texto escurecido para contraste AA em fundo claro.
    return (
      background: warn.withValues(alpha: 0.26),
      foreground: Color.lerp(warn, Colors.black, 0.55)!,
    );
  }
  if (normalized == 'P1') {
    if (isDark) {
      return (
        background: accent.withValues(alpha: 0.40),
        foreground: Colors.white.withValues(alpha: 0.96),
      );
    }
    return (
      background: accent.withValues(alpha: 0.18),
      foreground: Color.lerp(accent, Colors.black, 0.28)!,
    );
  }
  if (isDark) {
    return (
      background: accent.withValues(alpha: 0.34),
      foreground: Colors.white.withValues(alpha: 0.96),
    );
  }
  return (background: accent.withValues(alpha: 0.14), foreground: accent);
}

/// Chip “Ver prioridades” no header quando [isDark].
Color dashboardPrioritiesChipBackground(
  Color primary, {
  required bool isDark,
}) => BrandPalette.soft(
  primary,
  dark: isDark,
).withValues(alpha: isDark ? 0.55 : 1);

Color dashboardPrioritiesChipForeground(
  Color primary, {
  required bool isDark,
}) =>
    isDark
        ? Colors.white.withValues(alpha: 0.96)
        : BrandPalette.sectionAction(primary, dark: false);

/// Título de página / saudação — mesmo peso do nome no hero do Perfil.
TextStyle dashboardPageTitleStyle(BuildContext context, {required Color color}) {
  return Theme.of(context).textTheme.titleLarge!.copyWith(
    color: color,
    fontWeight: FontWeight.w900,
    height: 1.05,
    letterSpacing: 0,
  );
}

/// Título de seção (card) — espelha [PerfilCardSection].
TextStyle dashboardSectionTitleStyle(
  BuildContext context, {
  required Color color,
}) {
  return Theme.of(context).textTheme.titleMedium!.copyWith(
    fontWeight: FontWeight.w800,
    color: color,
    letterSpacing: -0.2,
  );
}

/// Eyebrow / micro labels — titleMedium do tema (Perfil app bar).
TextStyle dashboardMicroLabelStyle(
  BuildContext context, {
  required bool isDark,
  Color? color,
  FontWeight fontWeight = FontWeight.w800,
  double letterSpacing = 0.1,
}) {
  return Theme.of(context).textTheme.titleMedium!.copyWith(
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: 1.15,
    color: color ?? dashboardReadableCaption(context, isDark: isDark),
  );
}

/// Chip de ação no canto (Perfil trailing).
TextStyle dashboardActionChipStyle(Color foreground) {
  return TokensStrip.bodyMuted(color: foreground).copyWith(
    fontSize: TokensStrip.fontBodySm - 2,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );
}

TextStyle dashboardHeroEyebrowOnTeal() {
  return AppTypography.inter(
    color: dashboardHeroLabelOnTeal(),
    fontSize: TokensStrip.fontBodySm,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
    height: 1.1,
  );
}

TextStyle dashboardHeroCaptionOnTealStyle({
  FontWeight fontWeight = FontWeight.w500,
}) {
  return AppTypography.inter(
    color: dashboardHeroCaptionOnTeal(),
    fontSize: TokensStrip.fontBodySm,
    fontWeight: fontWeight,
    height: 1.3,
  );
}

TextStyle dashboardHeroMutedOnTealStyle({
  FontWeight fontWeight = FontWeight.w700,
}) {
  return AppTypography.inter(
    color: dashboardHeroMutedOnTeal(),
    fontSize: TokensStrip.fontBodySm,
    fontWeight: fontWeight,
    height: 1.2,
  );
}

TextStyle dashboardCardTitleStyle(Color ink) {
  // Mesmo corpo do título de card do Perfil (titleMedium → w800).
  return AppTypography.inter(
    fontSize: 13.5,
    fontWeight: FontWeight.w800,
    color: ink,
    letterSpacing: -0.2,
    height: 1.2,
  );
}

TextStyle dashboardCardSubtitleStyle(
  BuildContext context, {
  required bool isDark,
  FontWeight fontWeight = FontWeight.w400,
}) {
  return TokensStrip.bodyMuted(
    color: dashboardReadableCaption(context, isDark: isDark),
  ).copyWith(fontWeight: fontWeight, height: 1.35);
}

TextStyle dashboardChipLabelStyle(Color foreground) =>
    dashboardActionChipStyle(foreground);

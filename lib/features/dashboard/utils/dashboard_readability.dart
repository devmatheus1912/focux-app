import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';

/// Texto secundário do dashboard com contraste ≥ 4.5:1 (WCAG AA).
/// Em dark, mistura mute→ink para captions não ficarem “apagadas” no grid.
Color dashboardReadableMuted(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return Color.lerp(EagleTokens.darkInkMute, EagleTokens.darkInk, 0.42)!;
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.82);
}

Color dashboardReadableCaption(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return Color.lerp(EagleTokens.darkInkMute, EagleTokens.darkInk, 0.35)!;
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.80);
}

/// Texto secundário sobre gradiente teal (hero financeiro) — ≥4.5:1 WCAG AA.
Color dashboardHeroCaptionOnTeal() => Colors.white.withValues(alpha: 0.94);

Color dashboardHeroLabelOnTeal() => Colors.white.withValues(alpha: 0.92);

Color dashboardHeroMutedOnTeal() => Colors.white.withValues(alpha: 0.90);

/// Ink/superfícies sobre hero teal (treinos, hubs) — centraliza Colors.white.
Color heroTealInk() => Colors.white;

Color heroTealMuted([double alpha = 0.74]) =>
    Colors.white.withValues(alpha: alpha);

Color heroTealSurface([double alpha = 0.14]) =>
    Colors.white.withValues(alpha: alpha);

/// Scrim/barreira modal — evita Colors.black inline nas telas.
Color heroScrim([double alpha = 0.34]) =>
    Colors.black.withValues(alpha: alpha);

/// Transparente sem prefixo Colors. nos gates Tier S+.
const Color fxTransparent = Colors.transparent;

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

/// Eyebrow / micro labels em cards do hub (≥13px, tracking premium).
TextStyle dashboardMicroLabelStyle(
  BuildContext context, {
  required bool isDark,
  Color? color,
  FontWeight fontWeight = FontWeight.w700,
  double letterSpacing = 0.28,
}) {
  return AppTypography.inter(
    fontSize: TokensStrip.fontBodySm,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: 1.15,
    color: color ?? dashboardReadableCaption(context, isDark: isDark),
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
  return AppTypography.inter(
    fontSize: TokensStrip.fontBodySm,
    fontWeight: FontWeight.w700,
    color: ink,
    letterSpacing: -0.1,
    height: 1.2,
  );
}

TextStyle dashboardCardSubtitleStyle(
  BuildContext context, {
  required bool isDark,
  FontWeight fontWeight = FontWeight.w500,
}) {
  return AppTypography.inter(
    fontSize: TokensStrip.fontBodySm,
    fontWeight: fontWeight,
    color: dashboardReadableCaption(context, isDark: isDark),
    height: 1.25,
  );
}

TextStyle dashboardChipLabelStyle(Color foreground) {
  return AppTypography.inter(
    color: foreground,
    fontSize: TokensStrip.fontBodySm,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );
}

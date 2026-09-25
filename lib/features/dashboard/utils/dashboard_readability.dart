import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';

export '../../../core/theme/focux_hub_typography.dart';
export '../../../core/theme/hero_teal.dart';

/// Texto secundário do dashboard com contraste ≥ 4.5:1 (WCAG AA).
Color dashboardReadableMuted(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return Color.lerp(EagleTokens.darkInkMute, EagleTokens.darkInk, 0.62)!;
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.88);
}

Color dashboardReadableCaption(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return Color.lerp(EagleTokens.darkInkMute, EagleTokens.darkInk, 0.68)!;
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.88);
}

Color dashboardHeroCaptionOnTeal() => Colors.white.withValues(alpha: 0.94);

Color dashboardHeroLabelOnTeal() => Colors.white.withValues(alpha: 0.92);

Color dashboardHeroMutedOnTeal() => Colors.white.withValues(alpha: 0.90);

({Color background, Color foreground}) dashboardPriorityBadgeColors({
  required bool isDark,
  required Color accent,
  String? badge,
}) {
  final normalized = badge?.trim().toUpperCase();
  if (normalized == 'P0') {
    if (isDark) {
      final warn = EagleTokens.warnDark;
      return (
        background: warn,
        foreground: Color.lerp(warn, Colors.black, 0.78)!,
      );
    }
    // Claro: fill profundo + tinta clara — contraste WCAG do badge.
    return (
      background: EagleTokens.warnDeep,
      foreground: Colors.white,
    );
  }
  if (normalized == 'P1') {
    final fill = isDark ? EagleTokens.goodDark : accent;
    return (
      background: fill,
      foreground: Color.lerp(fill, Colors.black, isDark ? 0.72 : 0.55)!,
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

TextStyle dashboardPageTitleStyle(BuildContext context, {required Color color}) =>
    FocuxHubTypography.pageTitle(context, color: color);

TextStyle dashboardSectionTitleStyle(
  BuildContext context, {
  required Color color,
}) => FocuxHubTypography.sectionTitle(context, color: color);

TextStyle dashboardMicroLabelStyle(
  BuildContext context, {
  required bool isDark,
  Color? color,
  FontWeight fontWeight = FontWeight.w800,
  double letterSpacing = 0.1,
}) => FocuxHubTypography.eyebrow(
  context,
  color: color ?? dashboardReadableCaption(context, isDark: isDark),
  fontWeight: fontWeight,
  letterSpacing: letterSpacing,
);

TextStyle dashboardActionChipStyle(Color foreground) =>
    FocuxHubTypography.chip(foreground);

TextStyle dashboardHeroEyebrowOnTeal() => FocuxHubTypography.bodyMuted(
  color: dashboardHeroLabelOnTeal(),
  fontWeight: FontWeight.w600,
  height: 1.1,
).copyWith(letterSpacing: 0.14);

TextStyle dashboardHeroCaptionOnTealStyle({
  FontWeight fontWeight = FontWeight.w500,
}) => FocuxHubTypography.bodyMuted(
  color: dashboardHeroCaptionOnTeal(),
  fontWeight: fontWeight,
  height: 1.3,
);

TextStyle dashboardHeroMutedOnTealStyle({
  FontWeight fontWeight = FontWeight.w700,
}) => FocuxHubTypography.bodyMuted(
  color: dashboardHeroMutedOnTeal(),
  fontWeight: fontWeight,
  height: 1.2,
);

TextStyle dashboardCardTitleStyle(Color ink) =>
    FocuxHubTypography.cardTitle(color: ink);

TextStyle dashboardCardSubtitleStyle(
  BuildContext context, {
  required bool isDark,
  FontWeight fontWeight = FontWeight.w400,
}) => FocuxHubTypography.cardSubtitle(
  color: dashboardReadableCaption(context, isDark: isDark),
  fontWeight: fontWeight,
);

TextStyle dashboardChipLabelStyle(Color foreground) =>
    FocuxHubTypography.chip(foreground);

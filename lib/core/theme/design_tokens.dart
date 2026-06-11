import 'package:flutter/material.dart';

export 'app_typography.dart';

/// FX Design System — Focux · TOKENS STRIP v1.0.0
/// Fonte única de verdade para todos os tokens visuais.
///
/// Palette: Neon cyan-teal + cinematic dark · Liquid Glass surfaces.
/// Typography: Inter (display/body) + JetBrains Mono (technical/numbers).
abstract class EagleTokens {
  // ── Brand (TOKENS STRIP #13C2C2) ───────────────────────────────────
  static const Color brand = Color(0xFF13C2C2);
  static const Color brandInk = Color(0xFF0D9494);
  static const Color brandSecondary = Color(0xFF0D9494);
  static const Color brandSoft = Color(0xFFD9F2F2);
  static const Color brandSofter = Color(0xFFEDF8F8);
  static const Color brandDeep = Color(0xFF0A2E2E);
  static const Color brandAccent = Color(0xFF4DD0E1);

  // ── Neutral Light ───────────────────────────────────────────────────
  static const Color ink = Color(0xFF1A1A2E);
  static const Color inkSoft = Color(0xFF2E3840);
  static const Color inkMute = Color(0xFF6B7280);
  static const Color line = Color(0xFFE5E7EB);
  static const Color lineSoft = Color(0xFFECF0F2);
  static const Color paper = Color(0xFFF4F6F8);
  static const Color card = Color(0xFFFFFFFF);

  // ── Neutral Dark (Cinematic charcoal) ───────────────────────────────
  static const Color darkBg = Color(0xFF0B0E14);
  static const Color darkCard = Color(0xFF121820);
  static const Color darkCardHi = Color(0xFF1A2330);
  static const Color darkLine = Color(0xFF1E2830);
  static const Color darkInk = Color(0xFFE8EDF2);
  static const Color darkInkMute = Color(0xFF7A8A96);

  // ── Semânticos ──────────────────────────────────────────────────────
  static const Color good = Color(0xFF1B8C54);
  static const Color goodSoft = Color(0xFFE2F4EB);
  static const Color warn = Color(0xFFB5760A);
  static const Color warnSoft = Color(0xFFFFF3DD);
  static const Color bad = Color(0xFFC73A3A);
  static const Color badSoft = Color(0xFFFCE8E8);

  /// Variantes cinematográficas para dark mode (alertas, scores, NPS).
  static const Color goodDark = Color(0xFF6FE296);
  static const Color warnDark = Color(0xFFE2B46F);
  static const Color badDark = Color(0xFFFF8B8B);

  static Color semanticGood({bool isDark = false}) => isDark ? goodDark : good;
  static Color semanticWarn({bool isDark = false}) => isDark ? warnDark : warn;
  static Color semanticBad({bool isDark = false}) => isDark ? badDark : bad;
  static Color semanticGoodSoft({bool isDark = false}) =>
      isDark ? goodDark.withValues(alpha: 0.08) : goodSoft;
  static Color semanticWarnSoft({bool isDark = false}) =>
      isDark ? warnDark.withValues(alpha: 0.11) : warnSoft;
  static Color semanticBadSoft({bool isDark = false}) =>
      isDark ? badDark.withValues(alpha: 0.11) : badSoft;

  // Special
  static const Color gold = Color(0xFFE5B84C);
  static const Color goldSoft = Color(0xFFFFF8E6);
  static const Color purple = Color(0xFF6B46C1);

  // ── Glass / Liquid Glass Surfaces ───────────────────────────────────
  static const Color glassFill = Color(0x18FFFFFF);
  static const Color glassBorder = Color(0x24FFFFFF);
  static const Color glassInnerHighlight = Color(0x12FFFFFF);
  static const Color metalMid = Color(0xFF8B9AAB);

  /// Circuit glow — use with BoxShadow internal/tinted, never outer neon.
  /// Apply as: brandAccent.withValues(alpha: 0.35)
  static Color get circuitGlow => brandAccent.withValues(alpha: 0.35);

  /// Hero mesh dark gradient stops for auth/splash backgrounds.
  static const List<Color> heroMeshDark = [
    Color(0xFF0B0E14),
    Color(0xFF0D2830),
    Color(0xFF121820),
  ];

  // ── Adapters de Compatibilidade ─────────────────────────────────────
  static const Color primary = brand;
  static const Color danger = bad;
  static const Color warning = warn;
  static const Color success = good;
  static const Color textSecondary = inkMute;
  static const Color textSecondaryDark = darkInkMute;

  static const Color backgroundLight = paper;
  static const Color backgroundDark = darkBg;
  static const Color surfaceLight = card;
  static const Color surfaceDark = darkCard;
  static const Color textPrimaryLight = ink;
  static const Color textPrimaryDark = darkInk;
  static const Color outlineLight = line;
  static const Color outlineDark = darkLine;

  // ── Radius ──────────────────────────────────────────────────────────
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radius2xl = 32;
  static const double radius3xl = 40;
  static const double radiusPill = 999;

  // ── Hero Gradients ──────────────────────────────────────────────────
  static const List<Color> heroGradientLight = [
    Color(0xFF13C2C2),
    Color(0xFF18B5B5),
  ];

  static const List<Color> heroGradientDark = [
    Color(0xFF0A2E2E),
    Color(0xFF080C10),
  ];

  static LinearGradient heroGradient({bool dark = false}) => LinearGradient(
    colors: dark ? heroGradientDark : heroGradientLight,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Generates a hero gradient from any dynamic primary color.
  /// Used by white-label to derive gradients from the personal's custom color.
  static LinearGradient heroGradientFrom(Color primary, {bool dark = false}) {
    final hsl = HSLColor.fromColor(primary);
    if (dark) {
      final deep =
          hsl
              .withSaturation((hsl.saturation * 0.8).clamp(0.0, 1.0))
              .withLightness((hsl.lightness * 0.35).clamp(0.0, 1.0))
              .toColor();
      final deeper =
          hsl
              .withSaturation((hsl.saturation * 0.7).clamp(0.0, 1.0))
              .withLightness((hsl.lightness * 0.25).clamp(0.0, 1.0))
              .toColor();
      return LinearGradient(
        colors: [deep, deeper],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    final end =
        hsl.withLightness((hsl.lightness * 0.82).clamp(0.0, 1.0)).toColor();
    return LinearGradient(
      colors: [primary, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ── Helper de Aderência ─────────────────────────────────────────────
  static Color aderenciaColor(double taxa, {bool isDark = false}) {
    if (taxa >= 75) return semanticGood(isDark: isDark);
    if (taxa >= 50) return semanticWarn(isDark: isDark);
    return semanticBad(isDark: isDark);
  }

  /// Cor semântica para scores 0–100 (form check, qualidade, etc.).
  static Color scoreColor(int? score, {bool isDark = false}) {
    if (score == null) return isDark ? darkInkMute : inkMute;
    if (score >= 80) return semanticGood(isDark: isDark);
    if (score >= 60) return semanticWarn(isDark: isDark);
    return semanticBad(isDark: isDark);
  }

  /// NPS: promotor (9–10), neutro (7–8), detrator (0–6).
  static Color npsScoreColor(int score, {bool isDark = false}) {
    if (score >= 9) return semanticGood(isDark: isDark);
    if (score >= 7) return isDark ? warnDark : gold;
    return semanticBad(isDark: isDark);
  }

  /// Barra de força de senha (0–1).
  static Color passwordStrengthColor(double score) {
    if (score <= 0.25) return bad;
    if (score <= 0.5) return warn;
    if (score <= 0.75) return gold;
    return good;
  }
}

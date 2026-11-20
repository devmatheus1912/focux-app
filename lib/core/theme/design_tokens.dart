import 'package:flutter/material.dart';

export 'app_typography.dart';

/// FX Design System — Focux · TOKENS STRIP v1.0.0
/// Fonte única de verdade para todos os tokens visuais.
///
/// Palette: Azul petróleo + cinematic dark · Liquid Glass surfaces.
/// Typography: Inter.
abstract class EagleTokens {
  // ── Brand (TOKENS STRIP #0B4F5C — azul petróleo) ───────────────────
  static const Color brand = Color(0xFF0B4F5C);
  static const Color brandSoft = Color(0xFFD5E8EC);
  static const Color brandSofter = Color(0xFFEBF4F6);
  static const Color brandDeep = Color(0xFF051F26);
  static const Color brandAccent = Color(0xFF3D9AAD);

  // ── Neutral Light ───────────────────────────────────────────────────
  static const Color ink = Color(0xFF1A1A2E);
  static const Color inkMute = Color(0xFF6B7280);
  static const Color line = Color(0xFFE5E7EB);
  static const Color lineSoft = Color(0xFFECF0F2);
  static const Color paper = Color(0xFFF4F6F8);
  static const Color card = Color(0xFFFFFFFF);

  // ── Neutral Dark (chão petróleo do guia de marca, seção 4.3) ─────────
  // Elevação por tom fixo: chão → superfície → superfície alta.
  static const Color darkBg = Color(0xFF0A1A1F);
  static const Color darkCard = Color(0xFF10262C);
  static const Color darkCardHi = Color(0xFF16323A);
  static const Color darkLine = Color(0xFF1B3A42);
  static const Color darkInk = Color(0xFFE8EDF2);
  static const Color darkInkMute = Color(0xFF9AA8B3);

  // ── Semânticos ──────────────────────────────────────────────────────
  static const Color good = Color(0xFF1B8C54);
  static const Color goodSoft = Color(0xFFE2F4EB);
  static const Color warn = Color(0xFFB5760A);
  static const Color warnSoft = Color(0xFFFFF3DD);
  static const Color bad = Color(0xFFC73A3A);
  static const Color badSoft = Color(0xFFFCE8E8);

  /// [bad] para texto pequeno no claro: dá ≥ 4,5:1 onde [bad] fica em 4,4:1.
  static const Color badInk = Color(0xFFB42318);

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

  static const Color inkGray = Color(0xFF4B5563);
  static const Color inkSlateMuted = Color(0xFF9AA8B4);
  static const Color warnAccentSoft = Color(0xFFFFB088);
  static const Color warnDeep = Color(0xFF8A4B00);
  static const Color warnDeepDark = Color(0xFF7A5A00);
  static const Color warnSurfaceDark = Color(0xFF3D2A18);
  static const Color warnSurfaceDarkAlt = Color(0xFF2E2618);
  static const Color goodAccent = Color(0xFF9CF0C0);
  static const Color goodSurfaceDark = Color(0xFF1A2E24);
  static const Color riskCoralLight = Color(0xFFFFB4B4);
  static const Color warmPeach = Color(0xFFFFD59A);
  static const Color warmPeachSoft = Color(0xFFE2C48A);
  static const Color dangerBrown = Color(0xFF7C2D12);
  static const Color whatsapp = Color(0xFF25D366);
  static const Color moneyGreen = Color(0xFF0E9F6E);
  static const Color copilotSuccess = Color(0xFF2BB673);
  static const Color avatarMint = Color(0xFF5EEAD4);
  static const Color avatarSky = Color(0xFF7DD3FC);
  static const Color avatarPink = Color(0xFFF9A8D4);
  static const Color avatarLavender = Color(0xFFC4B5FD);
  static const Color avatarOrange = Color(0xFFFDBA74);
  static const Color authErrorSoft = Color(0xFFFFB6B6);
  static const Color authSuccessSoft = Color(0xFF8FE3B3);
  static const Color authErrorBorder = Color(0xFFFF8B8B);
  static const Color tierEnterpriseProInk = Color(0xFF0A6B7A);
  static const Color goldStar = Color(0xFFF59E0B);
  static const Color cinematicBg = darkBg;
  static const Color cinematicBgHi = darkCard;
  static const Color macroProtein = Color(0xFFEF4444);
  static const Color macroCarb = Color(0xFFEAB308);
  static const Color macroFat = Color(0xFFF9A825);
  static const Color planUsageWarn = Color(0xFFFFD28A);
  static const Color shadowSoft = Color(0x33000000);
  static const Color opsNotice = Color(0xFFFFB020);
  static const Color strengthWeak = Color(0xFFFF7A7A);
  static const Color strengthMid = Color(0xFFFFC857);
  static const Color strengthStrong = Color(0xFF38E68A);

  // Special
  static const Color gold = Color(0xFFE5B84C);

  static const Color purple = Color(0xFF6B46C1);

  // ── Glass / Liquid Glass Surfaces ───────────────────────────────────
  static const Color glassFill = Color(0x18FFFFFF);
  static const Color glassBorder = Color(0x24FFFFFF);

  /// Circuit glow — use with BoxShadow internal/tinted, never outer neon.
  /// Apply as: brandAccent.withValues(alpha: 0.35)
  static Color get circuitGlow => brandAccent.withValues(alpha: 0.35);

  /// Paradas do fundo escuro de auth/splash: chão petróleo, sem brilho.

  // ── Adapters de Compatibilidade ─────────────────────────────────────
  static const Color primary = brand;
  static const Color danger = bad;
  static const Color warning = warn;
  static const Color success = good;
  static const Color textSecondary = inkMute;

  // ── Radius ──────────────────────────────────────────────────────────
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

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
}

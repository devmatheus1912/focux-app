import 'package:flutter/material.dart';

/// FX Design System — Focux
/// Fonte única de verdade para todos os tokens visuais.
///
/// Palette: Warm Zinc neutrals + Deep Cobalt accent.
/// Typography: Outfit (display/body) + JetBrains Mono (technical/numbers).
abstract class EagleTokens {
  // ── Brand (Deep Cobalt — desaturated, ~60% sat) ────────────────────────
  static const Color brand = Color(0xFF3454D1);
  static const Color brandInk = Color(0xFF2A44A8);
  static const Color brandSoft = Color(0xFFE8ECFA);
  static const Color brandSofter = Color(0xFFF3F5FD);
  static const Color brandDeep = Color(0xFF0F1A4A);
  static const Color brandAccent = Color(0xFF7BA3F0);

  // ── Neutral Light (Warm Zinc) ──────────────────────────────────────────
  static const Color ink = Color(0xFF111318);
  static const Color inkSoft = Color(0xFF3B3F4A);
  static const Color inkMute = Color(0xFF6E7380);
  static const Color line = Color(0xFFE4E5E7);
  static const Color lineSoft = Color(0xFFEEEFF0);
  static const Color paper = Color(0xFFF8F8F6);
  static const Color card = Color(0xFFFFFFFF);

  // ── Neutral Dark (Charcoal) ────────────────────────────────────────────
  static const Color darkBg = Color(0xFF0D0F14);
  static const Color darkCard = Color(0xFF161921);
  static const Color darkCardHi = Color(0xFF1E2230);
  static const Color darkLine = Color(0xFF252833);
  static const Color darkInk = Color(0xFFF1F2F4);
  static const Color darkInkMute = Color(0xFF8B909E);

  // ── Semânticos ─────────────────────────────────────────────────────────
  static const Color good = Color(0xFF1B8C54);
  static const Color goodSoft = Color(0xFFE2F4EB);
  static const Color warn = Color(0xFFB5760A);
  static const Color warnSoft = Color(0xFFFFF3DD);
  static const Color bad = Color(0xFFC73A3A);
  static const Color badSoft = Color(0xFFFCE8E8);

  // Special
  static const Color gold = Color(0xFFE5B84C);
  static const Color goldSoft = Color(0xFFFFF8E6);
  static const Color purple = Color(0xFF6B46C1);

  // ── Adapters de Compatibilidade ────────────────────────────────────────
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

  // ── Radius ─────────────────────────────────────────────────────────────
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radius2xl = 28;
  static const double radiusPill = 999;

  // ── Hero Gradients ─────────────────────────────────────────────────────
  static const List<Color> heroGradientLight = [
    Color(0xFF3454D1),
    Color(0xFF2A44A8),
  ];

  static const List<Color> heroGradientDark = [
    Color(0xFF0F1A4A),
    Color(0xFF0A1235),
  ];

  static LinearGradient heroGradient({bool dark = false}) => LinearGradient(
    colors: dark ? heroGradientDark : heroGradientLight,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Generates a hero gradient from any dynamic primary color.
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

  // ── Helper de Aderência ────────────────────────────────────────────────
  static Color aderenciaColor(double taxa, {bool isDark = false}) {
    if (taxa >= 75) return isDark ? const Color(0xFF6FE296) : good;
    if (taxa >= 50) return isDark ? const Color(0xFFE2B46F) : warn;
    return isDark ? const Color(0xFFFF8B8B) : bad;
  }
}

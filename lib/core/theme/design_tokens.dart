import 'package:flutter/material.dart';

/// FX Design System — Focux
/// Fonte única de verdade para todos os tokens visuais do Handoff (tokens.jsx).
abstract class EagleTokens {
  // ── Brand (Electric Royal) ─────────────────────────────────────────────
  static const Color brand       = Color(0xFF3B5FE2);
  static const Color brandInk    = Color(0xFF2440B8);
  static const Color brandSoft   = Color(0xFFEAF0FE);
  static const Color brandSofter = Color(0xFFF4F7FE);
  static const Color brandDeep   = Color(0xFF0D1B5C);
  static const Color brandAccent = Color(0xFF7CC0FF);

  // ── Neutral Light (Warm, Subtle) ──────────────────────────────────────
  static const Color ink         = Color(0xFF0B1220);
  static const Color inkSoft     = Color(0xFF3A455C);
  static const Color inkMute     = Color(0xFF6B7689);
  static const Color line        = Color(0xFFE6E6E0);
  static const Color lineSoft    = Color(0xFFF0EFEA);
  static const Color paper       = Color(0xFFFAFAF8);
  static const Color card        = Color(0xFFFFFFFF);

  // ── Neutral Dark (Midnight) ───────────────────────────────────────────
  static const Color darkBg      = Color(0xFF0A0F1E);
  static const Color darkCard    = Color(0xFF121A30);
  static const Color darkCardHi  = Color(0xFF1A2442);
  static const Color darkLine    = Color(0xFF1F2B4A);
  static const Color darkInk     = Color(0xFFF3F4F8);
  static const Color darkInkMute = Color(0xFF8A94AE);

  // ── Semânticos ────────────────────────────────────────────────────────
  static const Color good        = Color(0xFF2B6A3F);
  static const Color goodSoft    = Color(0xFFE4F1E9);
  static const Color warn        = Color(0xFF8A5A12);
  static const Color warnSoft    = Color(0xFFFBEED6);
  static const Color bad         = Color(0xFF9E2B2B);
  static const Color badSoft     = Color(0xFFF7E3E3);

  // Special
  static const Color gold        = Color(0xFFFFD37A);
  static const Color goldSoft    = Color(0xFFFFF9E8);
  static const Color purple      = Color(0xFF6B46C1);

  // ── Adapters de Compatibilidade com Código Legado ─────────────────────
  static const Color primary = brand;
  static const Color danger  = bad;
  static const Color warning = warn;
  static const Color success = good;
  static const Color textSecondary = inkMute;
  static const Color textSecondaryDark = darkInkMute;

  static const Color backgroundLight = paper;
  static const Color backgroundDark  = darkBg;
  static const Color surfaceLight    = card;
  static const Color surfaceDark     = darkCard;
  static const Color textPrimaryLight = ink;
  static const Color textPrimaryDark  = darkInk;
  static const Color outlineLight = line;
  static const Color outlineDark  = darkLine;

  // ── Radius ────────────────────────────────────────────────────────────
  static const double radiusXs  = 8;
  static const double radiusSm  = 12;
  static const double radiusMd  = 16;
  static const double radiusLg  = 20;
  static const double radiusXl  = 24;
  static const double radius2xl = 28;
  static const double radiusPill = 999;

  // ── Hero Gradients ────────────────────────────────────────────────────
  static const List<Color> heroGradientLight = [
    Color(0xFF3B5FE2), // brand
    Color(0xFF2440B8), // brandInk
  ];

  static const List<Color> heroGradientDark = [
    Color(0xFF0D1B5C), // brandDeep
    Color(0xFF16256A), // slightly lighter navy
  ];

  static LinearGradient heroGradient({bool dark = false}) => LinearGradient(
        colors: dark ? heroGradientDark : heroGradientLight,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ── Helper de Aderência ───────────────────────────────────────────────
  static Color aderenciaColor(double taxa, {bool isDark = false}) {
    if (taxa >= 75) return isDark ? const Color(0xFF6FE296) : good;
    if (taxa >= 50) return isDark ? const Color(0xFFE2B46F) : warn;
    return isDark ? const Color(0xFFFF8B8B) : bad;
  }
}

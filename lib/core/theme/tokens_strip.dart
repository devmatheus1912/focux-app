import 'dart:ui';

import 'package:flutter/material.dart';

/// TOKENS STRIP v1.0.0 — Liquid Glass design language.
/// Apple Liquid Glass · Material 3 Expressive · AI-native enterprise UI.
abstract class TokensStrip {
  static const String version = '1.0.0';

  // ── Neon cyan / teal premium ─────────────────────────────────────────
  static const Color neonCyan = Color(0xFF26C6DA);
  static const Color neonTeal = Color(0xFF18B5B5);
  static const Color neonGlow = Color(0xFF4DD0E1);
  static const Color neonDeep = Color(0xFF007D8A);

  // ── Cinematic dark ───────────────────────────────────────────────────
  static const Color cinematicBg = Color(0xFF0B0E14);
  static const Color cinematicSurface = Color(0xFF121820);
  static const Color cinematicElevated = Color(0xFF1A2330);

  // ── Light mesh ───────────────────────────────────────────────────────
  static const Color lightMeshA = Color(0xFFC8E8E6);
  static const Color lightMeshB = Color(0xFFE6F2F3);
  static const Color lightMeshC = Color(0xFFDCE9EB);

  // ── Spacing (8pt grid) ───────────────────────────────────────────────
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 24;
  static const double s6 = 32;
  static const double s7 = 48;
  static const double s8 = 64;
  static const double s9 = 80;

  // ── visionOS fluid radius ────────────────────────────────────────────
  static const double rSm = 14;
  static const double rMd = 20;
  static const double rLg = 26;
  static const double rXl = 32;
  static const double r2xl = 40;
  static const double rPill = 999;

  // ── Blur ─────────────────────────────────────────────────────────────
  static const double blurLight = 16;
  static const double blurMedium = 22;
  static const double blurHeavy = 28;

  /// Multi-layer elevation shadows (0–96dp scale).
  static List<BoxShadow> elevation(
    int level, {
    required bool dark,
    Color? accent,
  }) {
    final tint = accent ?? neonGlow;
    final base = dark ? Colors.black : const Color(0xFF0C1218);

    switch (level) {
      case 0:
        return const [];
      case 1:
        return [
          BoxShadow(
            color: base.withValues(alpha: dark ? 0.22 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
      case 2:
        return [
          BoxShadow(
            color: base.withValues(alpha: dark ? 0.28 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
      case 4:
        return [
          BoxShadow(
            color: base.withValues(alpha: dark ? 0.32 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
        ];
      case 8:
        return [
          BoxShadow(
            color: base.withValues(alpha: dark ? 0.38 : 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: tint.withValues(alpha: dark ? 0.08 : 0.05),
            blurRadius: 32,
            offset: const Offset(0, 10),
            spreadRadius: -8,
          ),
        ];
      case 16:
        return [
          BoxShadow(
            color: base.withValues(alpha: dark ? 0.45 : 0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: -6,
          ),
          BoxShadow(
            color: tint.withValues(alpha: dark ? 0.12 : 0.07),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -10,
          ),
        ];
      case 24:
        return [
          BoxShadow(
            color: base.withValues(alpha: dark ? 0.50 : 0.10),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -8,
          ),
          BoxShadow(
            color: tint.withValues(alpha: dark ? 0.16 : 0.09),
            blurRadius: 52,
            offset: const Offset(0, 20),
            spreadRadius: -12,
          ),
        ];
      default:
        return [
          BoxShadow(
            color: base.withValues(alpha: dark ? 0.55 : 0.12),
            blurRadius: 56,
            offset: const Offset(0, 24),
            spreadRadius: -10,
          ),
          BoxShadow(
            color: tint.withValues(alpha: dark ? 0.20 : 0.12),
            blurRadius: 72,
            offset: const Offset(0, 28),
            spreadRadius: -14,
          ),
        ];
    }
  }

  /// 3D interactive neon glow — use on primary CTAs and active surfaces.
  static List<BoxShadow> interactiveGlow(
    Color accent, {
    double intensity = 1,
    bool dark = true,
  }) {
    final a = intensity.clamp(0.0, 1.5);
    return [
      BoxShadow(
        color: accent.withValues(alpha: dark ? 0.28 * a : 0.18 * a),
        blurRadius: 28,
        spreadRadius: -4,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: neonGlow.withValues(alpha: dark ? 0.14 * a : 0.10 * a),
        blurRadius: 48,
        spreadRadius: -8,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
        blurRadius: 20,
        offset: const Offset(0, 6),
        spreadRadius: -6,
      ),
    ];
  }

  static Color glassFill({required bool dark, double opacity = 1}) {
    if (dark) {
      return cinematicSurface.withValues(alpha: 0.72 * opacity);
    }
    return Colors.white.withValues(alpha: 0.78 * opacity);
  }

  static Color glassBorder({required bool dark, Color? accent}) {
    if (accent != null) {
      return accent.withValues(alpha: dark ? 0.34 : 0.22);
    }
    return dark
        ? Colors.white.withValues(alpha: 0.14)
        : neonGlow.withValues(alpha: 0.16);
  }

  static BoxDecoration glassPanel({
    required bool dark,
    double radius = rLg,
    Color? accent,
    int elevationLevel = 8,
    bool innerHighlight = true,
  }) {
    return BoxDecoration(
      color: glassFill(dark: dark),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: glassBorder(dark: dark, accent: accent),
        width: accent != null ? 1.2 : 1,
      ),
      boxShadow: [
        ...elevation(elevationLevel, dark: dark, accent: accent ?? neonGlow),
        if (innerHighlight)
          BoxShadow(
            color: Colors.white.withValues(alpha: dark ? 0.06 : 0.55),
            blurRadius: 0,
            spreadRadius: -1,
            offset: const Offset(0, 1),
          ),
      ],
    );
  }

  static LinearGradient primaryButtonGradient(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final end = hsl.withLightness((hsl.lightness * 0.88).clamp(0.0, 1.0)).toColor();
    return LinearGradient(
      colors: [primary, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static ImageFilter blurFilter([double sigma = blurMedium]) =>
      ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);

  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }
}

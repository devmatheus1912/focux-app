import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Derives soft/deep/accent variants from any dynamic primary color.
/// Used by white-label: personal's corPrimaria is passed here to generate
/// a harmonious set of tints that work across light and dark modes.
///
/// Tested with cyan (default Focux), warm reds, greens, purples.
class BrandPalette {
  static const Color defaultPrimary = Color(0xFF18B5B5);
  static const Color defaultSecondary = Color(0xFF007D8A);
  static const Color defaultInk = Color(0xFF128989);
  static const String defaultPrimaryHex = '#18B5B5';
  static const String defaultSecondaryHex = '#007D8A';

  /// Previous default cyan kept for reset detection on saved profiles.
  static const String legacyPrimaryHex = '#1EC8C8';
  static const String legacySecondaryHex = '#0097A7';

  static bool isDefaultBrandColors({
    String? corPrimaria,
    String? corSecundaria,
  }) {
    final primary = _normalizeHex(corPrimaria);
    final secondary = _normalizeHex(corSecundaria);
    const primaryDefaults = {defaultPrimaryHex, legacyPrimaryHex};
    const secondaryDefaults = {defaultSecondaryHex, legacySecondaryHex};
    return (primary == null || primaryDefaults.contains(primary)) &&
        (secondary == null || secondaryDefaults.contains(secondary));
  }

  static String toHex(Color color) =>
      '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  /// Slightly darkens a brand color for large surfaces and CTAs.
  static Color softened(Color primary, {double amount = 0.08}) {
    return Color.lerp(primary, EagleTokens.brandDeep, amount)!;
  }

  static String? _normalizeHex(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim().toUpperCase();
    if (!value.startsWith('#')) return '#$value';
    return value;
  }

  static Color soft(Color primary, {bool dark = false}) {
    final hsl = HSLColor.fromColor(primary);
    if (dark) {
      // In dark mode, produce a deeply desaturated, low-lightness tint
      return hsl
          .withSaturation((hsl.saturation * 0.35).clamp(0.0, 1.0))
          .withLightness(0.14)
          .toColor();
    }
    // In light mode, produce a very light tint with reduced saturation
    return hsl
        .withSaturation((hsl.saturation * 0.30).clamp(0.0, 1.0))
        .withLightness(0.93)
        .toColor();
  }

  static Color softer(Color primary, {bool dark = false}) {
    final hsl = HSLColor.fromColor(primary);
    if (dark) {
      return hsl
          .withSaturation((hsl.saturation * 0.25).clamp(0.0, 1.0))
          .withLightness(0.10)
          .toColor();
    }
    return hsl
        .withSaturation((hsl.saturation * 0.20).clamp(0.0, 1.0))
        .withLightness(0.96)
        .toColor();
  }

  static Color deep(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final next = hsl
        .withSaturation((hsl.saturation * 0.95).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.55).clamp(0.0, 1.0));
    return next.toColor();
  }

  static Color accent(Color primary) {
    final hsl = HSLColor.fromColor(primary);
    final next = hsl
        .withSaturation((hsl.saturation * 0.75).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.18).clamp(0.0, 1.0));
    return next.toColor();
  }
}

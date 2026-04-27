import 'package:flutter/material.dart';

class BrandPalette {
  static Color soft(Color primary, {bool dark = false}) {
    final blend = dark ? Colors.black : Colors.white;
    final amount = dark ? 0.74 : 0.86;
    return Color.alphaBlend(blend.withValues(alpha: amount), primary);
  }

  static Color softer(Color primary, {bool dark = false}) {
    final blend = dark ? Colors.black : Colors.white;
    final amount = dark ? 0.82 : 0.92;
    return Color.alphaBlend(blend.withValues(alpha: amount), primary);
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

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG 2.1 contrast utilities — fonte única para gates de legibilidade.
abstract class FocuxContrast {
  static const double wcagAaNormal = 4.5;
  static const double wcagAaLarge = 3.0;
  static const double wcagAaaNormal = 7.0;

  static double contrastRatio(Color a, Color b) {
    final l1 = relativeLuminance(a);
    final l2 = relativeLuminance(b);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  static double relativeLuminance(Color color) {
    double channel(double value) {
      final v = value / 255;
      return v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = channel(color.r * 255);
    final g = channel(color.g * 255);
    final b = channel(color.b * 255);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static bool meetsWcagAa(
    Color foreground,
    Color background, {
    bool largeText = false,
  }) {
    final ratio = contrastRatio(foreground, background);
    return ratio >= (largeText ? wcagAaLarge : wcagAaNormal);
  }

  static Color readableOn(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF111318);
  }
}

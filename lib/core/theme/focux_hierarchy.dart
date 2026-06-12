import 'package:flutter/material.dart';

import 'focux_typography.dart';
import 'tokens_strip.dart';

/// Papéis tipográficos e camadas de elevação — hierarquia visual e foco.
abstract final class FocuxHierarchy {
  FocuxHierarchy._();

  static TextStyle pageTitle({required Color color}) =>
      FocuxTypography.display(color: color);

  static TextStyle sectionTitle({required Color color}) =>
      FocuxTypography.headline(color: color);

  static TextStyle cardTitle({required Color color}) =>
      FocuxTypography.bodySmall(color: color).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.2,
      );

  static TextStyle body({required Color color}) =>
      FocuxTypography.body(color: color);

  static TextStyle caption({required Color color}) =>
      FocuxTypography.bodySmall(color: color);

  static TextStyle eyebrow({required Color color}) =>
      FocuxTypography.bodySmall(color: color).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.28,
        height: 1.15,
      );

  static TextStyle kpi({required Color color}) =>
      FocuxTypography.kpiCondensed(color: color);

  /// Camadas de elevação para foco visual (base → modal).
  static const int layerBase = 0;
  static const int layerRaised = 4;
  static const int layerSticky = 8;
  static const int layerOverlay = 16;
  static const int layerModal = 24;

  static List<BoxShadow> elevationLayer(
    int layer, {
    required bool dark,
    Color? accent,
  }) =>
      TokensStrip.elevation(layer, dark: dark, accent: accent);

  static const double focusRingWidth = 2;
}

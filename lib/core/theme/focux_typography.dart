import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'tokens_strip.dart';

/// Escala tipográfica compartilhada — Inter (UI), JetBrains Mono (métricas), Barlow Condensed (KPI).
abstract final class FocuxTypography {
  FocuxTypography._();

  static TextStyle display({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontH1,
        fontWeight: TokensStrip.weightH1,
        color: color,
        letterSpacing: TokensStrip.trackingH1,
        height: 1.15,
      );

  static TextStyle headline({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontH2,
        fontWeight: TokensStrip.weightH2,
        color: color,
        letterSpacing: TokensStrip.trackingH2,
        height: 1.2,
      );

  static TextStyle body({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontBody,
        fontWeight: TokensStrip.weightBody,
        color: color,
        height: TokensStrip.leadingBody,
      );

  static TextStyle bodySmall({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontBodySm,
        fontWeight: TokensStrip.weightBody,
        color: color,
        height: TokensStrip.leadingBody,
      );

  /// Números, KPIs, valores monetários — JetBrains Mono.
  static TextStyle monoMetric({
    required Color color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
    double? letterSpacing,
  }) =>
      AppTypography.mono(
        fontSize: fontSize ?? TokensStrip.fontBody,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  static TextStyle kpiCondensed({
    required Color color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      AppTypography.condensed(
        fontSize: fontSize ?? TokensStrip.fontH2,
        fontWeight: fontWeight,
        color: color,
        height: 1,
      );
}

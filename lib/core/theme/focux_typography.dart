import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'tokens_strip.dart';

/// Escala tipográfica compartilhada — Inter.
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

  /// Número da interface: Inter forte, dígitos de largura igual.
  static TextStyle numero({
    required Color color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w800,
    double? height,
    double? letterSpacing,
  }) => AppTypography.inter(
    fontSize: fontSize ?? TokensStrip.fontBody,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

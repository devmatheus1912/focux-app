import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'tokens_strip.dart';

/// Escala tipográfica compartilhada — Inter. Os papéis estão em
/// `FocuxHubTypography`; aqui ficam os estilos sem [BuildContext].
abstract final class FocuxTypography {
  FocuxTypography._();

  /// Destaque (32 / 700).
  static TextStyle display({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontDestaque,
        fontWeight: TokensStrip.weightH1,
        color: color,
        letterSpacing: TokensStrip.trackingH1,
        height: 1.1,
      );

  /// Título da página (22 / 700).
  static TextStyle headline({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontTitulo,
        fontWeight: TokensStrip.weightH2,
        color: color,
        letterSpacing: TokensStrip.trackingH2,
        height: 1.2,
      );

  /// Título de seção (17 / 600).
  static TextStyle secao({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontSecao,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.2,
        height: 1.25,
      );

  /// Corpo (15 / 400).
  static TextStyle body({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontBody,
        fontWeight: TokensStrip.weightBody,
        color: color,
        height: TokensStrip.leadingBody,
      );

  /// Secundário (13 / 400).
  static TextStyle bodySmall({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontBodySm,
        fontWeight: TokensStrip.weightBody,
        color: color,
        height: 1.4,
      );

  /// Rótulo (12 / 600).
  static TextStyle rotulo({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontRotulo,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.2,
      );

  /// Mínimo (11 / 500): o único lugar do w500.
  static TextStyle minimo({required Color color}) => AppTypography.inter(
        fontSize: TokensStrip.fontMinimo,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.2,
      );

  /// Número da interface: Inter forte, dígitos de largura igual.
  static TextStyle numero({
    required Color color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
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

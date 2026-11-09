import 'package:flutter/material.dart';

import 'focux_typography.dart';
import 'tokens_strip.dart';

/// Escala tipográfica do app: oito papéis nomeados pelo uso, tamanho e peso
/// fixos; a cor é de quem chama. Três pesos (400, 600, 700); o w500 só no
/// papel mínimo. Nenhuma tela usa `fontSize` literal (contrato de tipografia).
///
/// | Papel | Tamanho / peso / entrelinha |
/// |---|---|
/// | destaque | 32 / 700 / 1.1 |
/// | título da página ([pageTitle]) | 22 / 700 / 1.2 |
/// | título de seção ([sectionTitle]) | 17 / 600 / 1.25 |
/// | título de linha ([cardTitle]) | 15 / 600 / 1.3 |
/// | corpo ([body]) | 15 / 400 / 1.45 |
/// | secundário ([bodyMuted]) | 13 / 400 / 1.4 |
/// | rótulo ([rotulo], [chip], [eyebrow]) | 12 / 600 / 1.2 |
/// | mínimo ([minimo]) | 11 / 500 / 1.2 |
/// | número de tela única ([numeroTela]) | 40 / 700 |
abstract final class FocuxHubTypography {
  FocuxHubTypography._();

  /// Número herói (anel, total do mês).
  static TextStyle destaque({required Color color}) => FocuxTypography.display(
    color: color,
  );

  /// Topo da tela, saudação.
  static TextStyle pageTitle(BuildContext context, {required Color color}) {
    return FocuxTypography.headline(color: color);
  }

  /// Bloco, folha, título da barra do topo.
  static TextStyle sectionTitle(BuildContext context, {required Color color}) {
    return FocuxTypography.secao(color: color);
  }

  /// Eyebrow ("Foco do dia"): papel rótulo.
  static TextStyle eyebrow(
    BuildContext context, {
    required Color color,
    FontWeight fontWeight = FontWeight.w600,
    double letterSpacing = 0,
  }) {
    return rotulo(color: color).copyWith(
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
    );
  }

  /// Texto corrido (15 / 400).
  static TextStyle body({required Color color}) =>
      TokensStrip.body(color: color);

  /// Subtítulo, explicação (13 / 400).
  static TextStyle bodyMuted({
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.4,
  }) {
    return TokensStrip.bodyMuted(color: color).copyWith(
      fontWeight: fontWeight,
      height: height,
    );
  }

  /// Chip / trailing de ação: papel rótulo.
  static TextStyle chip(Color foreground) => rotulo(color: foreground);

  /// Chip, eyebrow, selo (12 / 600).
  static TextStyle rotulo({required Color color}) => FocuxTypography.rotulo(
    color: color,
  );

  /// Metadado, eixo de gráfico, contador (11 / 500).
  static TextStyle minimo({required Color color}) => FocuxTypography.minimo(
    color: color,
  );

  /// Linha de lista, card, botão (15 / 600).
  static TextStyle cardTitle({required Color color}) {
    return FocuxTypography.body(color: color).copyWith(
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
  }

  /// Subtítulo de linha em lista/card.
  static TextStyle cardSubtitle({
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return bodyMuted(color: color, fontWeight: fontWeight);
  }

  /// Todo número da interface: dígitos de largura igual, tamanhos da escala
  /// (32, 22, 17, 15, 13 ou 11).
  static TextStyle metric({
    required Color color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
    double? letterSpacing,
  }) => FocuxTypography.numero(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Número grande de tela única (teclado numérico, contador da série, anel
  /// de prontidão): 40 / 700. Só nesses lugares.
  static TextStyle numeroTela({required Color color, double? height}) =>
      metric(
        color: color,
        fontSize: TokensStrip.fontNumeroTela,
        height: height ?? 1.0,
        letterSpacing: -0.2,
      );
}

import 'package:flutter/material.dart';

import 'focux_hub_typography.dart';
import 'tokens_strip.dart';

/// Arquitetura de **ajustes inset** (ChatGPT iOS / `UITableView.insetGrouped`).
///
/// Identidade, tipografia e cor: os mesmos papéis do Planos/Home
/// (`FocuxHubTypography`). **Não** copia o tema preto/azul do ChatGPT.
///
/// Referência 80 pilares: `D:/Focux Personal/docs/PERFIL_DESIGN_REFERENCE.md`.
///
/// ## O que é ChatGPT/iOS (estrutura)
/// Página inset, grupo arredondado, linha com ícone outline + chevron,
/// divisor depois do ícone, Sair em grupo separado, picker com check.
///
/// ## O que é Planos/Home (tamanho + cor)
/// Nome = `sectionTitle`. Linha = `cardTitle`. Subtítulo = `bodyMuted`.
/// Score = métrica `fontBodySm`. Ícone leading = cor da marca.
/// Chevron muted. Sair: vermelho.
abstract final class FxSettingsLayout {
  FxSettingsLayout._();

  static const double pageInset = TokensStrip.s4;
  static const double groupRadius = 20;
  static const double groupPadH = TokensStrip.s4;
  static const double groupPadV = 2;
  static const double headerToGroup = TokensStrip.s2;
  static const double groupGap = TokensStrip.s5;
  static const double captionAfterHeader = TokensStrip.s1;
  static const double footerAfterGroup = TokensStrip.s2;

  static const double rowMinHeight = 52;
  static const double iconSize = 22;
  /// Largura do slot de ícone em campos/pickers inset (paridade `prefixIcon`).
  static const double insetPrefixWidth = 48;
  static const double iconGap = TokensStrip.s3;
  static const double chevronSize = 17;
  static const double dividerThickness = 0.5;
  static const double avatarSize = TokensStrip.s9;
  static const double editBadge = 28;

  static TextStyle profileName(BuildContext context, {required Color color}) =>
      FocuxHubTypography.sectionTitle(context, color: color);

  static TextStyle avatarInitials({required Color color}) =>
      FocuxHubTypography.cardTitle(color: color);

  static TextStyle rowLabel({required Color color}) =>
      FocuxHubTypography.cardTitle(color: color);

  static TextStyle rowValue({required Color color}) =>
      FocuxHubTypography.bodyMuted(color: color);

  static TextStyle rowMetric({required Color color}) =>
      FocuxHubTypography.metric(
        color: color,
        fontSize: TokensStrip.fontBodySm,
      );

  static TextStyle sectionHeader({required Color color}) =>
      FocuxHubTypography.bodyMuted(
        color: color,
        fontWeight: FontWeight.w600,
      );

  static TextStyle footer({required Color color}) =>
      FocuxHubTypography.bodyMuted(color: color, height: 1.35);

  static TextStyle subhead({required Color color}) =>
      FocuxHubTypography.bodyMuted(color: color, height: 1.35);
}

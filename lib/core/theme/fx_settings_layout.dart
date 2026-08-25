import 'package:flutter/material.dart';

import 'app_typography.dart';

/// Layout de **ajustes inset** (ChatGPT iOS / `UITableView.insetGrouped`).
///
/// Fonte: Inter (Focux). Cor: marca teal + `ShellChrome` da Home.
/// **Não** copia o tema preto/azul do ChatGPT.
/// Tamanhos: Dynamic Type iOS no degrau Large (padrão do app ChatGPT).
///
/// ## Tipografia (pt, degrau Large)
/// | Papel iOS | pt | Peso | Uso Focux |
/// | largeTitle | 34 | regular | não usar em ajustes |
/// | title1 | 28 | regular | não usar em ajustes |
/// | title2 | 22 | regular/semibold | nome no hero |
/// | title3 | 20 | regular | raro |
/// | headline | 17 | semibold | título de navegação |
/// | body | 17 | regular | label da linha |
/// | callout | 16 | regular | valor secundário opcional |
/// | subheadline | 15 | regular | subtítulo do hero |
/// | footnote | 13 | regular | header de grupo, footer, freshness |
/// | caption1 | 12 | regular | chips |
/// | caption2 | 11 | regular | micro |
///
/// ## Espaço e forma
/// - Margem da página: 16
/// - Raio do grupo: 20 (ChatGPT custom; iOS nativo ~10)
/// - Padding interno H: 16
/// - Altura mínima da linha: 52 (iOS 44 + respiro ChatGPT)
/// - Ícone outline: 22, cor = tinta do texto (não poço colorido)
/// - Gap ícone → texto: 12
/// - Chevron: 17, muted
/// - Divider: 0.5pt, começa depois do ícone
/// - Gap entre grupos: 24
/// - Header → card: 8
/// - Avatar: 80; badge editar: 28
///
/// ## Cor (Focux, não ChatGPT)
/// - Superfície: `fxListCardDecoration` / mesh da Home
/// - Texto: ink / mute do `ShellChrome`
/// - Acento (upgrade, sticky, selected): teal da marca
/// - Destrutivo: `EagleTokens.bad`
/// - Ícones de linha: ink (ChatGPT é branco no dark; aqui ink no claro)
///
/// ## O que não copiar
/// Tema #000 / card #212121, CTA azul #007AFF, botão X de modal,
/// wells coloridos, cards de KPI, accordion.
abstract final class FxSettingsLayout {
  FxSettingsLayout._();

  static const double fontNavTitle = 17;
  static const double fontProfileName = 22;
  static const double fontTitle3 = 20;
  static const double fontRow = 17;
  static const double fontCallout = 16;
  static const double fontSubhead = 15;
  static const double fontSection = 13;
  static const double fontFooter = 13;
  static const double fontCaption = 12;
  static const double fontMicro = 11;

  static const FontWeight weightNav = FontWeight.w600;
  static const FontWeight weightName = FontWeight.w700;
  static const FontWeight weightRow = FontWeight.w400;
  static const FontWeight weightSection = FontWeight.w400;

  static const double leadingTight = 1.15;
  static const double leadingBody = 1.25;
  static const double trackingBody = -0.24;
  static const double trackingSection = -0.08;

  static const double pageInset = 16;
  static const double groupRadius = 20;
  static const double groupPadH = 16;
  static const double groupPadV = 2;
  static const double headerToGroup = 8;
  static const double groupGap = 24;
  static const double captionAfterHeader = 4;
  static const double footerAfterGroup = 8;

  static const double rowMinHeight = 52;
  static const double iconSize = 22;
  static const double iconGap = 12;
  static const double chevronSize = 17;
  static const double dividerThickness = 0.5;
  static const double closeButton = 32;
  static const double avatarSize = 80;
  static const double editBadge = 28;
  static const double segmentedMinHeight = 36;

  static TextStyle navTitle({required Color color}) => AppTypography.inter(
    fontSize: fontNavTitle,
    fontWeight: weightNav,
    color: color,
    height: leadingTight,
    letterSpacing: trackingBody,
  );

  static TextStyle profileName({required Color color}) => AppTypography.inter(
    fontSize: fontProfileName,
    fontWeight: weightName,
    color: color,
    height: 1.1,
    letterSpacing: -0.26,
  );

  static TextStyle rowLabel({required Color color}) => AppTypography.inter(
    fontSize: fontRow,
    fontWeight: weightRow,
    color: color,
    height: leadingBody,
    letterSpacing: trackingBody,
  );

  static TextStyle rowValue({required Color color}) => AppTypography.inter(
    fontSize: fontRow,
    fontWeight: weightRow,
    color: color,
    height: leadingBody,
    letterSpacing: trackingBody,
  );

  static TextStyle sectionHeader({required Color color}) => AppTypography.inter(
    fontSize: fontSection,
    fontWeight: weightSection,
    color: color,
    height: leadingTight,
    letterSpacing: trackingSection,
  );

  static TextStyle footer({required Color color}) => AppTypography.inter(
    fontSize: fontFooter,
    fontWeight: weightRow,
    color: color,
    height: 1.3,
    letterSpacing: trackingSection,
  );

  static TextStyle subhead({required Color color}) => AppTypography.inter(
    fontSize: fontSubhead,
    fontWeight: weightRow,
    color: color,
    height: 1.3,
  );

  static TextStyle caption({required Color color}) => AppTypography.inter(
    fontSize: fontCaption,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.1,
  );
}

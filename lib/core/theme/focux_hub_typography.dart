import 'package:flutter/material.dart';

import 'focux_typography.dart';
import 'tokens_strip.dart';

/// Escala tipográfica canônica do hub personal (fonte: Perfil).
///
/// Todas as telas do shell (Hoje, Perfil, Alunos, …) devem usar estes roles
/// em vez de `fontSize` literais (18/20/22) ou `AppTypography.inter` ad-hoc.
abstract final class FocuxHubTypography {
  FocuxHubTypography._();

  /// Métricas intermediárias — evita literais 18/20/22 na UI.
  static const double metricEm = TokensStrip.fontBody + 3; // 18
  static const double metricMd = TokensStrip.fontBody + 5; // 20
  static const double metricLg = TokensStrip.fontH2; // 22

  /// Saudação / nome hero / headline principal do card.
  static TextStyle pageTitle(BuildContext context, {required Color color}) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      color: color,
      fontWeight: FontWeight.w900,
      height: 1.05,
      letterSpacing: 0,
    );
  }

  /// Título de seção / card (FxSettingsGroup e hubs).
  static TextStyle sectionTitle(BuildContext context, {required Color color}) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: -0.2,
    );
  }

  /// Eyebrow / app-bar label (“Foco do dia”, “Perfil”).
  static TextStyle eyebrow(
    BuildContext context, {
    required Color color,
    FontWeight fontWeight = FontWeight.w800,
    double letterSpacing = 0.1,
  }) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: 1.15,
      color: color,
    );
  }

  /// Corpo padrão (15 / w400).
  static TextStyle body({required Color color}) =>
      TokensStrip.body(color: color);

  /// Corpo secundário (13 / muted) com leading de leitura.
  static TextStyle bodyMuted({
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.35,
  }) {
    return TokensStrip.bodyMuted(color: color).copyWith(
      fontWeight: fontWeight,
      height: height,
    );
  }

  /// Chip / trailing de ação (Perfil).
  static TextStyle chip(Color foreground) {
    return TokensStrip.bodyMuted(color: foreground).copyWith(
      fontSize: TokensStrip.fontBodySm - 2,
      fontWeight: FontWeight.w800,
      height: 1.1,
    );
  }

  /// Título de linha em lista/card sem [BuildContext] (equiv. sectionTitle).
  static TextStyle cardTitle({required Color color}) {
    return FocuxTypography.bodySmall(color: color).copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
      height: 1.2,
    );
  }

  /// Subtítulo de linha em lista/card.
  static TextStyle cardSubtitle({
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return bodyMuted(color: color, fontWeight: fontWeight);
  }

  /// Números / KPIs — JetBrains Mono.
  static TextStyle metric({
    required Color color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
    double? height,
    double? letterSpacing,
  }) => FocuxTypography.monoMetric(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// KPI condensado (Barlow).
  static TextStyle kpi({
    required Color color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w700,
  }) => FocuxTypography.kpiCondensed(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}

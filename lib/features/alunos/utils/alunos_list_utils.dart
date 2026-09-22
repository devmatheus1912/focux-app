import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../constants/alunos_list_filters.dart';
import '../data/aluno_repository.dart';

/// Texto secundário da lista — contraste WCAG AA em fundos de card.
Color alunoListSecondaryInk(bool isDark) =>
    isDark ? EagleTokens.inkSlateMuted : EagleTokens.inkGray;

/// Badge «Risco alto» — cores calibradas para leitura em 10px.
(Color, Color) alunoRiscoAltoBadgeColors(bool isDark) =>
    isDark
        ? (EagleTokens.warnAccentSoft, EagleTokens.warnSurfaceDark)
        : (EagleTokens.warnDeep, EagleTokens.warnSoft);

/// Badge «Risco médio» — menos alarme que alto.
(Color, Color) alunoRiscoMedioBadgeColors(bool isDark) =>
    isDark
        ? (EagleTokens.warmPeachSoft, EagleTokens.warnSurfaceDarkAlt)
        : (EagleTokens.warnDeepDark, EagleTokens.warnSoft);

/// Hero metric chip — mesma família cromática da lista, por nível.
(Color, Color) alunoHeroRiscoMetricBadgeColors(bool isDark, String nivel) {
  final upper = nivel.trim().toUpperCase();
  return switch (upper) {
    'ALTO' => alunoRiscoAltoBadgeColors(isDark),
    'MÉDIO' || 'MEDIO' => alunoRiscoMedioBadgeColors(isDark),
    'BAIXO' =>
      isDark
          ? (EagleTokens.goodAccent, EagleTokens.goodSurfaceDark)
          : (EagleTokens.good, EagleTokens.goodSoft),
    _ => alunoRiscoAltoBadgeColors(isDark),
  };
}

/// Pagar em lote só se o plano tem financeiro e algum selecionado está em atraso.
bool alunoListIsOverdue(Aluno aluno) =>
    aluno.inadimplente || aluno.statusFinanceiro == 'INADIMPLENTE';

bool showAlunosBulkPayCta(
  Iterable<Aluno> selected, {
  required bool temFinanceiro,
}) =>
    temFinanceiro && selected.any(alunoListIsOverdue);

/// Banner de contato — some se a base inteira já é o foco (eco do chip).
bool showAlunosContatoBanner({
  required bool modoSelecao,
  required AlunoFiltro filtro,
  required int contatoCount,
  required int totalCount,
}) {
  if (modoSelecao) return false;
  if (filtro != AlunoFiltro.todos) return false;
  if (contatoCount <= 0) return false;
  if (totalCount > 0 && contatoCount >= totalCount) return false;
  return true;
}

/// Banner de risco — só se o de contato não estiver no ar e não for 100% da lista.
bool showAlunosRiscoBanner({
  required bool modoSelecao,
  required AlunoFiltro filtro,
  required int riscoCount,
  required int totalCount,
  required bool contatoBannerVisible,
}) {
  if (contatoBannerVisible) return false;
  if (modoSelecao) return false;
  if (filtro != AlunoFiltro.todos) return false;
  if (riscoCount <= 0) return false;
  if (totalCount > 0 && riscoCount >= totalCount) return false;
  return true;
}

/// Returns true if the status badge should be shown on the card.
bool shouldShowAlunoListBadge(
  String statusText,
  AlunoFiltro activeFiltro, {
  bool triageContextActive = false,
}) {
  if (statusText == 'Ativo') return false;
  if (statusText == 'Risco alto') {
    if (triageContextActive) return false;
    if (activeFiltro == AlunoFiltro.risco ||
        activeFiltro == AlunoFiltro.contatoHoje ||
        activeFiltro == AlunoFiltro.novos) {
      return false;
    }
  }
  if (statusText == 'Inadimplente') {
    if (activeFiltro == AlunoFiltro.inadimplentes) return false;
    if (activeFiltro == AlunoFiltro.contatoHoje) return false;
  }
  if (statusText == 'Inativo' && activeFiltro == AlunoFiltro.ativos) {
    return false;
  }
  return true;
}

String alunoWeeklyCheckinsLabel(int weeklyCheckins) {
  if (weeklyCheckins <= 0) return '';
  return '$weeklyCheckins ${weeklyCheckins == 1 ? 'treino' : 'treinos'}';
}

String adherenceActivityLabel({
  required Aluno aluno,
  required int weeklyCheckins,
}) {
  final dias = aluno.diasSemTreino;
  if (dias != null && dias > 0) {
    return '${dias}d s/ treino';
  }
  return alunoWeeklyCheckinsLabel(weeklyCheckins);
}

bool alunoListHasMeaningfulPercent(int? aderenciaPercent) =>
    aderenciaPercent != null && aderenciaPercent > 0;

/// Sinal operacional no card — paridade Home: número real ou dias; nunca 0%.
String alunoListOpsText({
  required String adherenceLabel,
  required bool triageContextActive,
  required int? aderenciaPercent,
  AlunoFiltro filtro = AlunoFiltro.todos,
}) {
  if (adherenceLabel.isNotEmpty) return adherenceLabel;
  if (filtro == AlunoFiltro.novos) return '';
  if (triageContextActive) return '';
  if (!alunoListHasMeaningfulPercent(aderenciaPercent)) return '';
  return '$aderenciaPercent%';
}

bool shouldShowAlunoListOpsLine({
  required String adherenceLabel,
  required bool triageContextActive,
  required int? aderenciaPercent,
  AlunoFiltro filtro = AlunoFiltro.todos,
}) =>
    alunoListOpsText(
      adherenceLabel: adherenceLabel,
      triageContextActive: triageContextActive,
      aderenciaPercent: aderenciaPercent,
      filtro: filtro,
    ).isNotEmpty;

/// Badge de status do card — lógica fora da UI.
({String label, Color fill, Color foreground}) alunoListStatusBadge(
  Aluno aluno,
  bool isDark,
) {
  if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
    return (
      label: 'Inadimplente',
      fill: EagleTokens.badSoft,
      foreground: EagleTokens.bad,
    );
  }
  if (aluno.status == 'INATIVO') {
    return (
      label: 'Inativo',
      fill: EagleTokens.warnSoft,
      foreground: EagleTokens.warn,
    );
  }
  if (aluno.emRisco) {
    final nivel = (aluno.riscoNivel ?? '').toUpperCase();
    final isAlto = nivel == 'ALTO';
    final riscoColors = isAlto
        ? alunoRiscoAltoBadgeColors(isDark)
        : alunoRiscoMedioBadgeColors(isDark);
    return (
      label: isAlto ? 'Risco alto' : 'Risco médio',
      fill: riscoColors.$2,
      foreground: riscoColors.$1,
    );
  }
  return (
    label: 'Ativo',
    fill: EagleTokens.goodSoft,
    foreground: EagleTokens.good,
  );
}

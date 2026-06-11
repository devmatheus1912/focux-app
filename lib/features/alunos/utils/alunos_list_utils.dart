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

/// Hero metric chip — mesma família cromática da lista, por nível.
(Color, Color) alunoHeroRiscoMetricBadgeColors(bool isDark, String nivel) {
  final upper = nivel.trim().toUpperCase();
  return switch (upper) {
    'ALTO' => alunoRiscoAltoBadgeColors(isDark),
    'MÉDIO' || 'MEDIO' =>
      isDark
          ? (EagleTokens.warmPeachSoft, EagleTokens.warnSurfaceDarkAlt)
          : (EagleTokens.warnDeepDark, EagleTokens.warnSoft),
    'BAIXO' =>
      isDark
          ? (EagleTokens.goodAccent, EagleTokens.goodSurfaceDark)
          : (EagleTokens.good, EagleTokens.goodSoft),
    _ => alunoRiscoAltoBadgeColors(isDark),
  };
}

/// Returns true if the status badge should be shown on the card.
bool shouldShowAlunoListBadge(
  String statusText,
  AlunoFiltro activeFiltro, {
  bool triageContextActive = false,
}) {
  if (statusText == 'Ativo') return false;
  if (statusText == 'Risco alto') {
    if (activeFiltro == AlunoFiltro.risco) return false;
    if (activeFiltro == AlunoFiltro.contatoHoje) return false;
    if (activeFiltro == AlunoFiltro.todos && triageContextActive) {
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
  if (weeklyCheckins <= 0) return 's/ treinos';
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

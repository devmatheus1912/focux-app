import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../constants/alunos_list_filters.dart';
import '../data/aluno_repository.dart';
import 'aluno_display_utils.dart';
import 'aluno_status.dart';

export 'aluno_status.dart';

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
}) => temFinanceiro && selected.any(alunoListIsOverdue);

/// Chips da lista. "Todos" e "Ativos" ficam sempre; os demais só com
/// contagem maior que zero (ou desconhecida) ou se estiverem selecionados.
/// O aluno nunca some da lista: só o chip sem nada a mostrar.
List<AlunoFiltro> filtrosVisiveis({
  required AlunoFiltro selecionado,
  required Map<AlunoFiltro, int?> contagens,
  required bool temFinanceiro,
}) {
  bool mostra(AlunoFiltro filtro) {
    if (filtro == selecionado) return true;
    final n = contagens[filtro];
    return n == null || n > 0;
  }

  return [
    AlunoFiltro.todos,
    if (mostra(AlunoFiltro.contatoHoje)) AlunoFiltro.contatoHoje,
    AlunoFiltro.ativos,
    if (temFinanceiro && mostra(AlunoFiltro.inadimplentes))
      AlunoFiltro.inadimplentes,
    if (mostra(AlunoFiltro.risco)) AlunoFiltro.risco,
    if (mostra(AlunoFiltro.novos)) AlunoFiltro.novos,
    if (mostra(AlunoFiltro.inativos)) AlunoFiltro.inativos,
  ];
}

/// O que a linha 2 do card diz.
enum LinhaDoCardTipo { convite, parado, objetivo, email }

typedef LinhaDoCard = ({String texto, LinhaDoCardTipo tipo});

/// Uma linha só, por prioridade: convite pendente, parado, objetivo ou e-mail.
/// Nunca "Objetivo pendente".
LinhaDoCard linhaDoCard(Aluno aluno, {required String maskedEmail}) {
  if (!aluno.contaAtiva && alunoStatusAtivo(aluno)) {
    return (texto: 'Ainda não entrou', tipo: LinhaDoCardTipo.convite);
  }
  final dias = aluno.diasSemTreino;
  if (dias != null && dias >= 3) {
    return (texto: 'Parado há $dias dias', tipo: LinhaDoCardTipo.parado);
  }
  final objetivo = (aluno.objetivo ?? '').trim();
  if (objetivo.isNotEmpty) {
    return (
      texto: prettyAlunoObjective(objetivo),
      tipo: LinhaDoCardTipo.objetivo,
    );
  }
  return (texto: maskedEmail, tipo: LinhaDoCardTipo.email);
}

/// Returns true if the status badge should be shown on the card.
bool shouldShowAlunoListBadge(
  String statusText,
  AlunoFiltro activeFiltro, {
  bool triageContextActive = false,
}) {
  if (statusText == 'Ativo') return false;
  if (statusText == 'Atenção alta') {
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

/// Série da lista = últimos 7 dias corridos (não a semana do calendário).
String alunoWeeklyCheckinsLabel(int weeklyCheckins) {
  if (weeklyCheckins <= 0) return '';
  return weeklyCheckins == 1
      ? '1 treino em 7 dias'
      : '$weeklyCheckins treinos em 7 dias';
}

String adherenceActivityLabel({
  required Aluno aluno,
  required int weeklyCheckins,
}) {
  final dias = aluno.diasSemTreino;
  // Paridade hero 360: alarme de inatividade a partir de 3 dias.
  if (dias != null && dias >= 3) {
    return 'Parado há ${dias}d';
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
  return alunoListAderenciaLabel(aderenciaPercent!);
}

/// `aderenciaPercent` do servidor cobre os últimos 30 dias.
String alunoListAderenciaLabel(int aderenciaPercent) =>
    '$aderenciaPercent% em 30 dias';

/// Legenda do sparkline do card; curta para caber na largura do gráfico.
const alunoListSparklineLabel = '7 dias';

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

/// O BFF ainda não filtra por status: `inativos` cai em todos e o recorte
/// é feito aqui. Em Prioridade, pausados e bloqueados vão para o fim.
List<Aluno> alunosListVisiveis(
  List<Aluno> alunos, {
  required AlunoFiltro filtro,
  AlunoOrdenacao ordenacao = AlunoOrdenacao.prioridade,
}) {
  if (filtro == AlunoFiltro.inativos) {
    return alunos.where((a) => !alunoStatusAtivo(a)).toList(growable: false);
  }
  if (filtro == AlunoFiltro.todos && ordenacao == AlunoOrdenacao.prioridade) {
    return [
      ...alunos.where(alunoStatusAtivo),
      ...alunos.where((a) => !alunoStatusAtivo(a)),
    ];
  }
  return alunos;
}

/// Vagas do plano esgotadas? Inativos/bloqueados não ocupam vaga.
bool alunoVagasEsgotadas({required int? limiteAlunos, AlunosStats? stats}) {
  if (limiteAlunos == null || limiteAlunos <= 0) return false;
  return (stats?.totalOcupandoVaga ?? 0) >= limiteAlunos;
}

/// Contagem do chip Inativos; `null` quando a lista carregada não basta.
int? alunosInativosCount({
  required int? totalInativos,
  required List<Aluno> carregados,
  required AlunoFiltro filtro,
  required bool temMaisPaginas,
}) {
  if (totalInativos != null) return totalInativos;
  if (temMaisPaginas) return null;
  if (filtro != AlunoFiltro.todos && filtro != AlunoFiltro.inativos) {
    return null;
  }
  return carregados.where((a) => !alunoStatusAtivo(a)).length;
}

/// Badge de status do card — lógica fora da UI.
/// Bloqueado > Inadimplente > Inativo > risco (só ATIVO) > Ativo.
({String label, Color fill, Color foreground}) alunoListStatusBadge(
  Aluno aluno,
  bool isDark,
) {
  final status = alunoStatusNormalizado(aluno.status);
  if (status == AlunoStatus.bloqueado) {
    return (
      label: 'Bloqueado',
      fill: EagleTokens.badSoft,
      foreground: EagleTokens.bad,
    );
  }
  if (aluno.statusFinanceiro == 'INADIMPLENTE' || aluno.inadimplente) {
    return (
      label: 'Inadimplente',
      fill: EagleTokens.badSoft,
      foreground: EagleTokens.bad,
    );
  }
  if (status == AlunoStatus.inativo) {
    return (
      label: 'Inativo',
      fill: EagleTokens.warnSoft,
      foreground: EagleTokens.warn,
    );
  }
  if (aluno.emRisco && status == AlunoStatus.ativo) {
    final nivel = (aluno.riscoNivel ?? '').toUpperCase();
    final isAlto = nivel == 'ALTO';
    final riscoColors =
        isAlto
            ? alunoRiscoAltoBadgeColors(isDark)
            : alunoRiscoMedioBadgeColors(isDark);
    return (
      label: isAlto ? 'Atenção alta' : 'Atenção média',
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

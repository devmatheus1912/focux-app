/// Narrativa única do dia — evita repetir “retomada/aderência” em vários blocos.
class DashboardDayFocus {
  const DashboardDayFocus({
    required this.headline,
    required this.detail,
    required this.semanticLabel,
  });

  final String headline;
  final String detail;
  final String semanticLabel;

  static DashboardDayFocus resolve({
    required int riscoAlto,
    required int alunosAtivos,
    required int checkinsHoje,
    required int agendaHoje,
    required double receitaMes,
    required int vencimentosPendentes,
    required bool riskDominante,
  }) {
    if (vencimentosPendentes > 0 && riscoAlto > 0) {
      return DashboardDayFocus(
        headline: 'Cobrança e retenção hoje',
        detail:
            '$vencimentosPendentes pendência${vencimentosPendentes == 1 ? '' : 's'} · $riscoAlto aluno${riscoAlto == 1 ? '' : 's'} no radar',
        semanticLabel:
            'Foco do dia: cobrança e retenção. $vencimentosPendentes pendências e $riscoAlto alunos no radar.',
      );
    }
    if (riskDominante || riscoAlto >= 2) {
      return DashboardDayFocus(
        headline: 'Retomada urgente da base',
        detail:
            '$riscoAlto de $alunosAtivos precisam de contato hoje — comece pelo P0 abaixo.',
        semanticLabel:
            'Foco do dia: retomada urgente. $riscoAlto de $alunosAtivos alunos precisam de contato.',
      );
    }
    if (riscoAlto > 0) {
      return DashboardDayFocus(
        headline: 'Acompanhar alunos em risco',
        detail: '$riscoAlto no radar · revise o contato ainda hoje.',
        semanticLabel:
            'Foco do dia: $riscoAlto alunos em risco precisam de acompanhamento.',
      );
    }
    if (checkinsHoje == 0 && alunosAtivos > 0) {
      return DashboardDayFocus(
        headline: 'Impulsionar check-ins hoje',
        detail:
            'Nenhum treino registrado ainda · use a agenda para acionar a base.',
        semanticLabel:
            'Foco do dia: nenhum check-in hoje. Acione alunos pela agenda.',
      );
    }
    if (receitaMes <= 0 && alunosAtivos > 0) {
      return DashboardDayFocus(
        headline: 'Ativar receita do mês',
        detail:
            'Registre cobranças ou pacotes para acompanhar meta e inadimplência.',
        semanticLabel:
            'Foco do dia: ativar receita do mês registrando cobranças.',
      );
    }
    if (agendaHoje > 0) {
      return DashboardDayFocus(
        headline: 'Agenda cheia hoje',
        detail:
            '$agendaHoje compromisso${agendaHoje == 1 ? '' : 's'} · confira as próximas ações.',
        semanticLabel: 'Foco do dia: $agendaHoje compromissos na agenda.',
      );
    }
    return const DashboardDayFocus(
      headline: 'Operação sob controle',
      detail: 'Use as próximas ações para a melhor próxima ação.',
      semanticLabel: 'Foco do dia: operação sob controle.',
    );
  }
}

/// Narrativa única do dia — evita repetir “retomada/aderência” em vários blocos.
/// Runtime da Home: só payload BFF (`fromJson`). [resolve] espelha o BE em testes —
/// não usar como SSOT no snapshot da tela.
enum DashboardDayFocusKind {
  cobrancaRetencao,
  retomadaUrgente,
  risco,
  checkins,
  receita,
  agenda,
  estavel,
}

DashboardDayFocusKind? dashboardDayFocusKindFromApi(String? raw) {
  switch (raw) {
    case 'COBRANCA_RETENCAO':
      return DashboardDayFocusKind.cobrancaRetencao;
    case 'RETOMADA_URGENTE':
      return DashboardDayFocusKind.retomadaUrgente;
    case 'RISCO':
      return DashboardDayFocusKind.risco;
    case 'CHECKINS':
      return DashboardDayFocusKind.checkins;
    case 'RECEITA':
      return DashboardDayFocusKind.receita;
    case 'AGENDA':
      return DashboardDayFocusKind.agenda;
    case 'ESTAVEL':
      return DashboardDayFocusKind.estavel;
    default:
      return null;
  }
}

class DashboardDayFocus {
  const DashboardDayFocus({
    required this.headline,
    required this.detail,
    required this.semanticLabel,
    this.kind,
    this.coversRetention,
    this.riskDominante,
  });

  final String headline;
  final String detail;
  final String semanticLabel;
  final DashboardDayFocusKind? kind;
  final bool? coversRetention;
  final bool? riskDominante;

  /// Gap de contrato: BFF omitiu `dayFocus`. Só release; debug falha no assert do snapshot.
  static const estavelSsotGap = DashboardDayFocus(
    kind: DashboardDayFocusKind.estavel,
    coversRetention: false,
    riskDominante: false,
    headline: 'Operação sob controle',
    detail: 'Use as próximas ações para a melhor próxima ação.',
    semanticLabel: 'Foco do dia: operação sob controle.',
  );

  factory DashboardDayFocus.fromJson(Map<String, dynamic> json) {
    return DashboardDayFocus(
      kind: dashboardDayFocusKindFromApi(json['kind'] as String?),
      headline: json['headline'] as String? ?? 'Operação sob controle',
      detail:
          json['detail'] as String? ??
          'Use as próximas ações para a melhor próxima ação.',
      semanticLabel:
          json['semanticLabel'] as String? ?? 'Foco do dia: operação sob controle.',
      coversRetention: json['coversRetention'] as bool?,
      riskDominante: json['riskDominante'] as bool?,
    );
  }

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
        kind: DashboardDayFocusKind.cobrancaRetencao,
        coversRetention: true,
        riskDominante: riskDominante,
        headline: 'Cobrança e retenção hoje',
        detail:
            '$vencimentosPendentes pendência${vencimentosPendentes == 1 ? '' : 's'} · $riscoAlto aluno${riscoAlto == 1 ? '' : 's'} no radar',
        semanticLabel:
            'Foco do dia: cobrança e retenção. $vencimentosPendentes pendências e $riscoAlto alunos no radar.',
      );
    }
    if (riskDominante || riscoAlto >= 2) {
      return DashboardDayFocus(
        kind: DashboardDayFocusKind.retomadaUrgente,
        coversRetention: true,
        riskDominante: riskDominante,
        headline: 'Retomada urgente da base',
        detail:
            '$riscoAlto de $alunosAtivos precisam de contato hoje — comece pelo P0 abaixo.',
        semanticLabel:
            'Foco do dia: retomada urgente. $riscoAlto de $alunosAtivos alunos precisam de contato.',
      );
    }
    if (riscoAlto > 0) {
      return DashboardDayFocus(
        kind: DashboardDayFocusKind.risco,
        coversRetention: true,
        riskDominante: riskDominante,
        headline: 'Acompanhar alunos em risco',
        detail: '$riscoAlto no radar · revise o contato ainda hoje.',
        semanticLabel:
            'Foco do dia: $riscoAlto alunos em risco precisam de acompanhamento.',
      );
    }
    if (checkinsHoje == 0 && alunosAtivos > 0) {
      return DashboardDayFocus(
        kind: DashboardDayFocusKind.checkins,
        coversRetention: false,
        riskDominante: riskDominante,
        headline: 'Impulsionar check-ins hoje',
        detail:
            'Nenhum treino registrado ainda · use a agenda para acionar a base.',
        semanticLabel:
            'Foco do dia: nenhum check-in hoje. Acione alunos pela agenda.',
      );
    }
    if (receitaMes <= 0 && alunosAtivos > 0) {
      return DashboardDayFocus(
        kind: DashboardDayFocusKind.receita,
        coversRetention: false,
        riskDominante: riskDominante,
        headline: 'Ativar receita do mês',
        detail:
            'Registre cobranças ou pacotes para acompanhar meta e inadimplência.',
        semanticLabel:
            'Foco do dia: ativar receita do mês registrando cobranças.',
      );
    }
    if (agendaHoje > 0) {
      return DashboardDayFocus(
        kind: DashboardDayFocusKind.agenda,
        coversRetention: false,
        riskDominante: riskDominante,
        headline: 'Agenda cheia hoje',
        detail:
            '$agendaHoje compromisso${agendaHoje == 1 ? '' : 's'} · confira as próximas ações.',
        semanticLabel: 'Foco do dia: $agendaHoje compromissos na agenda.',
      );
    }
    return DashboardDayFocus(
      kind: DashboardDayFocusKind.estavel,
      coversRetention: false,
      riskDominante: riskDominante,
      headline: 'Operação sob controle',
      detail: 'Use as próximas ações para a melhor próxima ação.',
      semanticLabel: 'Foco do dia: operação sob controle.',
    );
  }
}

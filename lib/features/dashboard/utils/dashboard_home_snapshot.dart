import 'dart:math' as math;

import '../../alunos/data/aluno_repository.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../data/command_center_data.dart';
import '../data/dashboard_repository.dart';
import 'dashboard_day_focus.dart';
import 'dashboard_home_focus.dart';
import 'dashboard_next_actions.dart';
import 'dashboard_screen_helpers.dart';
import 'dashboard_sparkline_helpers.dart';
import 'dashboard_unread.dart';

/// Agregação pura da Home (Hoje) — testável sem widgets.
class DashboardHomeSnapshot {
  const DashboardHomeSnapshot({
    required this.mesLabel,
    required this.pendente,
    required this.metaReceita,
    required this.receitaAtual,
    required this.progressRaw,
    required this.metaSuperada,
    required this.alunosAtivos,
    required this.riscoAlto,
    required this.alunosEmRisco,
    required this.checkinsHoje,
    required this.checkinsTrend,
    required this.receitaTrend,
    required this.agendaHoje,
    required this.riskDominante,
    required this.dayFocus,
    required this.focusRules,
    required this.attentionRiskItems,
    required this.attentionVencItems,
    required this.attentionVisible,
    required this.attentionCollapsedPreview,
    required this.unreadCount,
    required this.cobrancasPendentes,
    required this.dashboardNextActions,
    required this.prioritiesSheetActions,
    required this.showPrioritiesLink,
    required this.filaAcoes,
  });

  final String mesLabel;
  final double pendente;
  final double metaReceita;
  final double receitaAtual;
  final double progressRaw;
  final bool metaSuperada;
  final int alunosAtivos;
  final int riscoAlto;
  final List<Aluno> alunosEmRisco;
  final int checkinsHoje;
  final List<double> checkinsTrend;
  final List<double> receitaTrend;
  final int agendaHoje;
  final bool riskDominante;
  final DashboardDayFocus dayFocus;
  final DashboardHomeFocusRules focusRules;
  final List<Aluno> attentionRiskItems;
  final List<VencimentoItem> attentionVencItems;
  final bool attentionVisible;
  final String? attentionCollapsedPreview;
  final int unreadCount;
  final int cobrancasPendentes;
  final List<CommandActionItem> dashboardNextActions;
  final List<CommandActionItem> prioritiesSheetActions;
  final bool showPrioritiesLink;
  final List<FilaAcaoResumo> filaAcoes;

  static const monthNames = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  factory DashboardHomeSnapshot.build({
    required DashboardHomeBundle home,
    required FinanceiroDashboard? finData,
    required List<Aluno>? alunos,
    required List<ExecucaoTreino>? historicoCheckins,
    required CommandCenterData? commandCenter,
    required int inboxUnread,
    required bool inboxReady,
    required bool focusMode,
    required bool isCommandPreparing,
    DateTime? now,
  }) {
    final clock = now ?? DateTime.now();
    final data = home.personal;
    final mes = monthNames[clock.month - 1];
    final receitaAtual = finData?.receitaMes ?? 0;
    final metaReceita = finData?.previsaoReceita ?? 0;
    final pendente =
        (metaReceita - receitaAtual).clamp(0.0, double.infinity);
    final progressRaw = metaReceita > 0 ? receitaAtual / metaReceita : 0.0;
    final metaSuperada = metaReceita > 0 && receitaAtual >= metaReceita;

    final alunosAtivos =
        alunos != null
            ? alunos.where((a) => a.status == 'ATIVO').length
            : data.alunosAtivos;
    final alunosEmRisco =
        alunos != null
            ? alunos.where((a) => a.emRisco).toList(growable: false)
            : const <Aluno>[];
    final bffRisco = commandCenter?.alunosEmRisco.length ?? 0;
    // Contagem: BFF no first paint; max com lista local quando já carregou.
    final riscoAlto =
        alunos != null
            ? math.max(alunosEmRisco.length, bffRisco)
            : bffRisco;

    final checkinsFromHistorico =
        historicoCheckins == null
            ? 0
            : historicoCheckins.where((e) {
              final concluded = DateTime.tryParse(e.concluidoEm ?? '');
              if (concluded == null) return false;
              final local = concluded.toLocal();
              return local.year == clock.year &&
                  local.month == clock.month &&
                  local.day == clock.day;
            }).length;
    final checkinsHoje = home.pulse?.checkinsHoje ?? checkinsFromHistorico;
    // Sem histórico ready → lista vazia (não zero-fill falso).
    final checkinsTrend =
        historicoCheckins != null
            ? dashboardCheckinsSparklineUltimos7Dias(historicoCheckins)
            : const <double>[];
    final receitaTrend = dashboardReceitaSparklineMensal(
      finData?.evolucaoMensal ?? const [],
    );
    final agendaHoje = commandCenter?.agendaHoje.length ?? 0;
    final riskDominante =
        alunosAtivos > 0 &&
        riscoAlto >= math.max(2, (alunosAtivos * 0.5).ceil());
    final vencimentosCount = finData?.vencimentosProximos.length ?? 0;
    final dayFocus = DashboardDayFocus.resolve(
      riscoAlto: riscoAlto,
      alunosAtivos: alunosAtivos,
      checkinsHoje: checkinsHoje,
      agendaHoje: agendaHoje,
      receitaMes: receitaAtual,
      vencimentosPendentes: vencimentosCount,
      riskDominante: riskDominante,
    );
    final focusRules = DashboardHomeFocusRules.resolve(
      focusMode: focusMode,
      dayFocus: dayFocus,
      riscoAlto: riscoAlto,
      receitaAtual: receitaAtual,
    );
    final dayFocusCoversRetention = focusRules.dayFocusCoversRetention;

    final attentionRiskItems =
        alunosEmRisco
            .take(
              DashboardHomeFocusRules.attentionRiskLimit(
                dayFocusCoversRetention: dayFocusCoversRetention,
                focusMode: focusRules.focusMode,
                riskDominante: riskDominante,
              ),
            )
            .toList(growable: false);
    final attentionVencItems =
        (finData?.vencimentosProximos ?? const <VencimentoItem>[])
            .take(
              DashboardHomeFocusRules.attentionVencLimit(
                dayFocus: dayFocus,
                dayFocusCoversRetention: dayFocusCoversRetention,
                focusMode: focusRules.focusMode,
              ),
            )
            .toList(growable: false);
    final attentionVisible =
        attentionRiskItems.isNotEmpty || attentionVencItems.isNotEmpty;

    String? attentionCollapsedPreview;
    if (attentionRiskItems.isNotEmpty) {
      final first = attentionRiskItems.first;
      attentionCollapsedPreview =
          '${first.nome} · ${attentionSignalLabel(first)}';
    } else if (attentionVencItems.isNotEmpty) {
      final first = attentionVencItems.first;
      attentionCollapsedPreview =
          '${first.alunoNome} · R\$ ${first.valor.toStringAsFixed(0)} pendente';
    }

    final filaAcoes = commandCenter?.filaAcoes ?? const <FilaAcaoResumo>[];
    final unreadCount = dashboardResolveUnreadCount(
      pulseUnread: home.pulse?.mensagensNaoLidas,
      inboxReady: inboxReady,
      inboxUnread: inboxUnread,
    );
    final cobrancasPendentes =
        commandCenter?.cobrancasPendentes.length ??
        finData?.totalInadimplentes ??
        0;
    final riskStudentsForSheet =
        alunosEmRisco.isNotEmpty
            ? alunosEmRisco
                .map((a) => (id: a.id, nome: a.nome))
                .toList(growable: false)
            : (commandCenter?.alunosEmRisco ?? const <AlertaResumo>[])
                .map((a) => (id: a.id, nome: a.nomeAluno))
                .toList(growable: false);
    final dashboardNextActions = buildDashboardNextActions(
      filaAcoes: filaAcoes,
      unreadCount: unreadCount,
      alunosRisco: riscoAlto,
      cobrancasPendentes: cobrancasPendentes,
      agendaHoje: agendaHoje,
      hideRiskSummary: alunosEmRisco.isNotEmpty,
      riskOwnedByDayFocus: dayFocusCoversRetention,
      isCommandPreparing: isCommandPreparing,
      maxItems: focusRules.maxVisibleNextActions,
    );
    final prioritiesSheetActions = buildDashboardSheetActions(
      curated: dashboardNextActions,
      filaAcoes: filaAcoes,
      riskStudents: riskStudentsForSheet,
    );
    final showPrioritiesLink = dashboardShouldShowPrioritiesLink(
      visible: dashboardNextActions,
      sheet: prioritiesSheetActions,
      isPreparing: isCommandPreparing,
    );

    return DashboardHomeSnapshot(
      mesLabel: mes,
      pendente: pendente.toDouble(),
      metaReceita: metaReceita,
      receitaAtual: receitaAtual,
      progressRaw: progressRaw,
      metaSuperada: metaSuperada,
      alunosAtivos: alunosAtivos,
      riscoAlto: riscoAlto,
      alunosEmRisco: alunosEmRisco,
      checkinsHoje: checkinsHoje,
      checkinsTrend: checkinsTrend,
      receitaTrend: receitaTrend,
      agendaHoje: agendaHoje,
      riskDominante: riskDominante,
      dayFocus: dayFocus,
      focusRules: focusRules,
      attentionRiskItems: attentionRiskItems,
      attentionVencItems: attentionVencItems,
      attentionVisible: attentionVisible,
      attentionCollapsedPreview: attentionCollapsedPreview,
      unreadCount: unreadCount,
      cobrancasPendentes: cobrancasPendentes,
      dashboardNextActions: dashboardNextActions,
      prioritiesSheetActions: prioritiesSheetActions,
      showPrioritiesLink: showPrioritiesLink,
      filaAcoes: filaAcoes,
    );
  }
}

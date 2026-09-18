import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_day_focus.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_home_snapshot.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';

FilaAcaoResumo _fila() {
  return FilaAcaoResumo(
    tipo: 'RISCO',
    actionKey: 'RISK_STUDENTS',
    titulo: 'Recuperar alunos em risco',
    descricao: '8 alunos',
    acaoUrl: '/retencao',
    prioridade: 'P0',
    severidade: 'ALTA',
    responsavel: 'Personal',
    sla: 'Hoje',
    status: 'ABERTO',
    ctaLabel: 'Abrir',
    iaSugerida: false,
  );
}

void main() {
  group('DashboardHomeSnapshot', () {
    test('aggregates focus, attention limits and next actions', () {
      final commandCenter = CommandCenterData(
        agendaHoje: const [],
        alunosEmRisco: [
          AlertaResumo(
            id: 42,
            nomeAluno: 'Ana',
            motivo: 'Sem treino',
            nivelRisco: 'ALTO',
          ),
        ],
        alunosScore: const [],
        cobrancasPendentes: const [],
        autonomiaGargalos: const [],
        modoOperacao: const [],
        filaAcoes: [_fila()],
      );
      final financeiro = FinanceiroDashboard(
        receitaMes: 0,
        receitaAcumulada: 0,
        ticketMedio: 0,
        totalInadimplentes: 2,
        previsaoReceita: 5000,
        vencimentosProximos: const [],
        topAlunos: const [],
        evolucaoMensal: const [],
      );
      final home = DashboardHomeBundle(
        personal: DashboardData(
          totalAlunos: 8,
          alunosAtivos: 8,
          planoAtual: 'PRO',
          limiteAlunos: 50,
          nomePersonal: 'Matheus',
        ),
        commandCenter: commandCenter,
        financeiro: financeiro,
        pulse: const DashboardPulseSnapshot(
          checkinsHoje: 0,
          mensagensNaoLidas: 3,
          coachPendentes: 4,
          checkinsTrend: [0, 0, 1, 0, 2, 0, 0],
        ),
        dayFocus: const DashboardDayFocus(
          kind: DashboardDayFocusKind.retomadaUrgente,
          coversRetention: true,
          riskDominante: true,
          headline: 'Retomada urgente da base',
          detail: '1 de 8',
          semanticLabel: 'Foco',
        ),
      );

      final snap = DashboardHomeSnapshot.build(
        home: home,
        finData: financeiro,
        alunos: null,
        commandCenter: commandCenter,
        focusMode: true,
        isCommandPreparing: false,
        now: DateTime(2026, 8, 12),
      );

      expect(snap.mesLabel, 'agosto');
      expect(snap.checkinsHoje, 0);
      expect(snap.checkinsTrend, [0.0, 0.0, 1.0, 0.0, 2.0, 0.0, 0.0]);
      expect(snap.unreadCount, 3);
      expect(home.pulse?.coachPendentes, 4);
      expect(snap.alunosEmRisco, isNotEmpty);
      expect(snap.alunosEmRisco.first.nome, 'Ana');
      expect(snap.focusRules.hideFeaturedTools, isTrue);
      expect(snap.focusRules.omitSecondarySections, isTrue);
      expect(snap.riscoAlto, 1);
      expect(snap.dashboardNextActions.first.priorityBadge, 'P0');
      expect(snap.dashboardNextActions.first.route, '/retencao');
    });

    test('throws when BFF omits dayFocus', () {
      final home = DashboardHomeBundle(
        personal: DashboardData(
          totalAlunos: 1,
          alunosAtivos: 1,
          planoAtual: 'PRO',
          limiteAlunos: 50,
        ),
        commandCenter: CommandCenterData(
          agendaHoje: const [],
          alunosEmRisco: const [],
          alunosScore: const [],
          cobrancasPendentes: const [],
          autonomiaGargalos: const [],
          modoOperacao: const [],
          filaAcoes: const [],
        ),
        financeiro: FinanceiroDashboard(
          receitaMes: 0,
          receitaAcumulada: 0,
          ticketMedio: 0,
          totalInadimplentes: 0,
          previsaoReceita: 0,
          vencimentosProximos: const [],
          topAlunos: const [],
          evolucaoMensal: const [],
        ),
      );
      expect(
        () => DashboardHomeSnapshot.build(
          home: home,
          finData: home.financeiro,
          alunos: null,
          commandCenter: home.commandCenter,
          focusMode: false,
          isCommandPreparing: false,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

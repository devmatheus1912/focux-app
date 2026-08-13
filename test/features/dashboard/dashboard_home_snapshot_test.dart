import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
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
        ),
      );

      final snap = DashboardHomeSnapshot.build(
        home: home,
        finData: financeiro,
        alunos: null,
        historicoCheckins: null,
        commandCenter: commandCenter,
        inboxUnread: 0,
        inboxReady: false,
        focusMode: true,
        isCommandPreparing: false,
        now: DateTime(2026, 8, 12),
      );

      expect(snap.mesLabel, 'agosto');
      expect(snap.checkinsHoje, 0);
      expect(snap.unreadCount, 3);
      expect(snap.focusRules.hideFeaturedTools, isTrue);
      expect(snap.focusRules.collapseQuickLinks, isTrue);
      expect(snap.riscoAlto, 1);
      expect(snap.dashboardNextActions.first.priorityBadge, 'P0');
      expect(snap.dashboardNextActions.first.route, '/retencao');
    });
  });
}

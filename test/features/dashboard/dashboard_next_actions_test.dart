import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_next_actions.dart';

FilaAcaoResumo _fila({
  required String actionKey,
  required String tipo,
  String titulo = 'Cobrar',
  String descricao = 'Pendência',
  String acaoUrl = '/financeiro',
  String prioridade = 'P1',
}) {
  return FilaAcaoResumo(
    tipo: tipo,
    actionKey: actionKey,
    titulo: titulo,
    descricao: descricao,
    acaoUrl: acaoUrl,
    prioridade: prioridade,
    severidade: 'MEDIA',
    responsavel: 'Personal',
    sla: 'Hoje',
    status: 'ABERTO',
    ctaLabel: 'Cobrar',
    iaSugerida: false,
  );
}

void main() {
  group('buildDashboardNextActions', () {
    test('puts risk P0 before billing P1', () {
      final actions = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 8,
        cobrancasPendentes: 1,
        agendaHoje: 0,
        hideRiskSummary: false,
        isCommandPreparing: false,
        maxItems: 2,
      );

      expect(actions, hasLength(2));
      expect(actions.first.title, 'Contato hoje');
      expect(actions.first.priorityBadge, 'P0');
      expect(actions[1].title, 'Cobrar pendências');
      expect(actions[1].priorityBadge, 'P1');
    });

    test('keeps risk P0 when attention already covers radar', () {
      final actions = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 5,
        cobrancasPendentes: 1,
        agendaHoje: 0,
        hideRiskSummary: true,
        isCommandPreparing: false,
        maxItems: 2,
      );

      expect(actions.first.title, 'Recuperar alunos em risco');
      expect(actions.first.priorityBadge, 'P0');
      expect(actions.first.route, '/retencao');
      expect(actions[1].title, 'Cobrar pendências');
    });

    test('prioritizes billing when no risk and respects maxItems', () {
      final actions = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 0,
        cobrancasPendentes: 2,
        agendaHoje: 1,
        hideRiskSummary: false,
        isCommandPreparing: false,
        maxItems: 2,
      );

      expect(actions, hasLength(2));
      expect(actions.first.title, 'Cobrar pendências');
      expect(actions.first.priorityBadge, 'P1');
      expect(actions[1].title, 'Preparar agenda');
    });

    test('falls back to create opportunity when empty', () {
      final actions = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 0,
        cobrancasPendentes: 0,
        agendaHoje: 0,
        hideRiskSummary: false,
        isCommandPreparing: false,
      );

      expect(actions, hasLength(1));
      expect(actions.single.route, '/alunos/novo');
    });
  });

  group('buildDashboardSheetActions', () {
    test('dedupes billing from fila when curated already has money action', () {
      final curated = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 0,
        cobrancasPendentes: 1,
        agendaHoje: 0,
        hideRiskSummary: false,
        isCommandPreparing: false,
      );
      final merged = buildDashboardSheetActions(
        curated: curated,
        filaAcoes: [
          _fila(actionKey: 'BILLING_PENDING', tipo: 'COBRANCA'),
        ],
      );

      expect(merged.where((a) => a.route == '/financeiro').length, 1);
    });

    test('sorts P0 above P1 and dedupes risk from fila', () {
      final curated = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 8,
        cobrancasPendentes: 1,
        agendaHoje: 0,
        hideRiskSummary: true,
        isCommandPreparing: false,
        maxItems: 2,
      );
      final merged = buildDashboardSheetActions(
        curated: curated,
        filaAcoes: [
          _fila(
            actionKey: 'RISK_STUDENTS',
            tipo: 'RISCO',
            titulo: 'Recuperar alunos em risco',
            descricao: '5 alunos com risco de abandono',
            acaoUrl: '/retencao',
            prioridade: 'P0',
          ),
          _fila(actionKey: 'BILLING_PENDING', tipo: 'COBRANCA'),
        ],
      );

      expect(merged.first.priorityBadge, 'P0');
      expect(merged.first.title, 'Recuperar alunos em risco');
      expect(merged[1].priorityBadge, 'P1');
      expect(
        merged.where((a) => a.title.contains('risco')).length,
        1,
      );
    });
  });
}

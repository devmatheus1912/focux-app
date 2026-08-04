import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_next_actions.dart';

FilaAcaoResumo _fila({
  required String actionKey,
  required String tipo,
  String titulo = 'Cobrar',
  String descricao = 'Pendência',
  String acaoUrl = '/financeiro',
}) {
  return FilaAcaoResumo(
    tipo: tipo,
    actionKey: actionKey,
    titulo: titulo,
    descricao: descricao,
    acaoUrl: acaoUrl,
    prioridade: 'P1',
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
    test('prioritizes billing and respects maxItems', () {
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

    test('hides risk summary when already covered by attention rail', () {
      final actions = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 5,
        cobrancasPendentes: 0,
        agendaHoje: 0,
        hideRiskSummary: true,
        isCommandPreparing: false,
      );

      expect(actions.any((a) => a.title == 'Contato hoje'), isFalse);
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
  });
}

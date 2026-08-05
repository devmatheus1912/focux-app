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
    test('puts risk P0 before billing P1 with unified count', () {
      final actions = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 8,
        cobrancasPendentes: 1,
        agendaHoje: 0,
        hideRiskSummary: true,
        isCommandPreparing: false,
        maxItems: 2,
      );

      expect(actions.first.title, 'Recuperar alunos em risco');
      expect(actions.first.subtitle, contains('8 alunos'));
      expect(actions.first.priorityBadge, 'P0');
      expect(actions[1].title, 'Cobrar pendências');
    });

    test('risk owned by day focus opens retention queue without repeating count', () {
      final actions = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 5,
        cobrancasPendentes: 0,
        agendaHoje: 0,
        hideRiskSummary: true,
        riskOwnedByDayFocus: true,
        isCommandPreparing: false,
        maxItems: 2,
      );

      expect(actions.first.title, 'Abrir fila de retenção');
      expect(actions.first.subtitle, 'Trabalhar o P0 agora');
      expect(actions.first.subtitle, isNot(contains('5')));
      expect(actions.first.route, '/retencao');
      expect(actions.first.priorityBadge, 'P0');
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

      expect(actions.single.route, '/alunos/novo');
    });
  });

  group('buildDashboardSheetActions', () {
    test('hides priorities link when sheet mirrors visible list', () {
      final curated = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 0,
        cobrancasPendentes: 1,
        agendaHoje: 0,
        hideRiskSummary: false,
        isCommandPreparing: false,
      );
      final sheet = buildDashboardSheetActions(
        curated: curated,
        filaAcoes: [_fila(actionKey: 'BILLING_PENDING', tipo: 'COBRANCA')],
      );

      expect(
        dashboardShouldShowPrioritiesLink(
          visible: curated,
          sheet: sheet,
          isPreparing: false,
        ),
        isFalse,
      );
    });

    test('shows priorities link when risk students enrich the sheet', () {
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
      final sheet = buildDashboardSheetActions(
        curated: curated,
        filaAcoes: const [],
        riskStudents: [
          (id: 1, nome: 'Ana'),
          (id: 2, nome: 'Bruno'),
        ],
      );

      expect(sheet.where((a) => a.isRadarStudent).length, 2);
      expect(sheet.every((a) => a.isRadarStudent), isTrue);
      expect(
        dashboardShouldShowPrioritiesLink(
          visible: curated,
          sheet: sheet,
          isPreparing: false,
        ),
        isTrue,
      );
    });

    test('omits curated P0/P1 and keeps only extras plus students', () {
      final curated = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 3,
        cobrancasPendentes: 1,
        agendaHoje: 0,
        hideRiskSummary: true,
        isCommandPreparing: false,
        maxItems: 2,
      );
      final sheet = buildDashboardSheetActions(
        curated: curated,
        filaAcoes: [
          _fila(
            actionKey: 'PLAN_REVIEW',
            tipo: 'OPERACAO',
            titulo: 'Revisar planos',
            descricao: '3 planos desatualizados',
            acaoUrl: '/planos',
            prioridade: 'P2',
          ),
        ],
        riskStudents: [(id: 1, nome: 'Ana')],
      );

      final curatedKeys = {
        for (final a in curated) '${a.title}|${a.route}',
      };
      expect(
        sheet.where((a) => !a.isRadarStudent).any(
          (a) => curatedKeys.contains('${a.title}|${a.route}'),
        ),
        isFalse,
      );
      expect(sheet.any((a) => a.title == 'Revisar planos'), isTrue);
      expect(sheet.any((a) => a.isRadarStudent && a.title == 'Ana'), isTrue);
    });
  });
}

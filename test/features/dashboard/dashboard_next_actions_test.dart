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

    test('risk owned by day focus opens named student without repeating count', () {
      final actions = buildDashboardNextActions(
        filaAcoes: const [],
        unreadCount: 0,
        alunosRisco: 5,
        cobrancasPendentes: 0,
        agendaHoje: 0,
        hideRiskSummary: true,
        riskOwnedByDayFocus: true,
        leadRiskStudent: (
          id: 9,
          nome: 'Nathalia Abrantes',
          motivo: null,
          nivelRisco: 'ALTO',
          proximaAcao: null,
        ),
        isCommandPreparing: false,
        maxItems: 2,
      );

      expect(actions.first.title, 'Nathalia Abrantes');
      expect(actions.first.subtitle, 'Contato agora');
      expect(actions.first.subtitle, isNot(contains('5')));
      expect(actions.first.route, '/alunos/9');
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

    test('does not duplicate P0 when RISK_STUDENTS is already in the queue', () {
      final actions = buildDashboardNextActions(
        filaAcoes: [
          _fila(
            actionKey: 'RISK_STUDENTS',
            tipo: 'RISCO',
            titulo: 'Recuperar alunos em risco',
            descricao: '8 alunos com risco de abandono',
            acaoUrl: '/retencao',
            prioridade: 'P0',
          ),
        ],
        unreadCount: 0,
        alunosRisco: 8,
        cobrancasPendentes: 0,
        agendaHoje: 0,
        hideRiskSummary: true,
        riskOwnedByDayFocus: true,
        isCommandPreparing: false,
        maxItems: 3,
      );

      expect(actions.where((a) => a.priorityBadge == 'P0'), hasLength(1));
      expect(actions.first.title, 'Abrir fila de retenção');
      expect(actions.any((a) => a.title == 'Executar próxima ação'), isFalse);
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
          (id: 1, nome: 'Ana', motivo: null, nivelRisco: 'ALTO', proximaAcao: null),
          (id: 2, nome: 'Bruno', motivo: null, nivelRisco: 'MEDIO', proximaAcao: null),
        ],
      );

      expect(sheet.where((a) => a.isRadarStudent).length, 2);
      expect(sheet.every((a) => a.isRadarStudent), isTrue);
      expect(sheet.first.title, 'Ana');
      expect(sheet.first.subtitle, contains('Comece por aqui'));
      expect(sheet[1].subtitle, isNot(equals(sheet.first.subtitle)));
      expect(
        dashboardShouldShowPrioritiesLink(
          visible: curated,
          sheet: sheet,
          isPreparing: false,
        ),
        isTrue,
      );
    });

    test('title-cases radar names and keeps risk order', () {
      final sheet = buildDashboardSheetActions(
        curated: const [],
        filaAcoes: const [],
        riskStudents: [
          (
            id: 9,
            nome: 'thales silva',
            motivo: 'Sem treino ha 10 dias',
            nivelRisco: 'ALTO',
            proximaAcao: 'Retomar treino com mensagem curta',
          ),
          (
            id: 2,
            nome: 'ana',
            motivo: 'Inadimplente',
            nivelRisco: 'MEDIO',
            proximaAcao: 'Regularizar financeiro',
          ),
        ],
      );

      expect(sheet.map((a) => a.title).toList(), ['Thales Silva', 'Ana']);
      expect(sheet.first.subtitle, contains('Comece por aqui'));
      expect(sheet[1].subtitle.toLowerCase(), contains('financeir'));
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
        riskStudents: [
          (id: 1, nome: 'Ana', motivo: null, nivelRisco: null, proximaAcao: null),
        ],
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

    test('colapsa 3+ impactos com o mesmo prefixo e só o lead leva P0', () {
      final sheet = buildDashboardSheetActions(
        curated: const [],
        filaAcoes: [
          _fila(
            actionKey: 'PLAN_REVIEW',
            tipo: 'OPERACAO',
            titulo: 'Gargalo recorrente: Ana',
            descricao: 'Mesmo bloqueio',
            acaoUrl: '/alunos/1',
            prioridade: 'P2',
          ),
          _fila(
            actionKey: 'PLAN_REVIEW',
            tipo: 'OPERACAO',
            titulo: 'Gargalo recorrente: Bruno',
            descricao: 'Mesmo bloqueio',
            acaoUrl: '/alunos/2',
            prioridade: 'P2',
          ),
          _fila(
            actionKey: 'PLAN_REVIEW',
            tipo: 'OPERACAO',
            titulo: 'Gargalo recorrente: Caio',
            descricao: 'Mesmo bloqueio',
            acaoUrl: '/alunos/3',
            prioridade: 'P2',
          ),
        ],
        riskStudents: [
          (id: 1, nome: 'Ana', motivo: null, nivelRisco: 'ALTO', proximaAcao: null),
          (id: 2, nome: 'Bruno', motivo: null, nivelRisco: 'MEDIO', proximaAcao: null),
        ],
      );

      expect(
        sheet.where((a) => !a.isRadarStudent).map((a) => a.title),
        ['Gargalo recorrente · 3'],
      );
      expect(sheet.where((a) => a.priorityBadge == 'P0'), hasLength(1));
      expect(sheet.firstWhere((a) => a.isRadarStudent).title, 'Ana');
    });
  });
}

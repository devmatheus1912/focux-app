import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';

Aluno _aluno({
  bool emRisco = false,
  String? riscoNivel,
  int? aderenciaPercent,
  String? proximoContato,
}) {
  return Aluno(
    id: 1,
    nome: 'Teste',
    email: 't@test.com',
    status: 'ATIVO',
    emRisco: emRisco,
    riscoNivel: riscoNivel,
    aderenciaPercent: aderenciaPercent,
    proximoContato: proximoContato,
  );
}

FilaAcaoResumo _openCopilotAction() {
  return FilaAcaoResumo(
    tipo: 'IA_COPILOTO',
    actionKey: 'k',
    titulo: 'T',
    descricao: 'D',
    acaoUrl: '/x',
    prioridade: 'P2',
    severidade: 'MEDIA',
    responsavel: 'PERSONAL',
    sla: '24h',
    status: 'ABERTO',
    ctaLabel: 'Abrir',
    iaSugerida: true,
    createdFromInsight: false,
  );
}

void main() {
  group('resolveOperacaoStickyAction', () {
    test('open task with proxima acao mirrors radar label', () {
      final action = resolveOperacaoStickyAction(
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Retomar contato e ajustar plano',
          motivo: 'Radar',
          fonte: 'RADAR',
          prioridade: 'P1',
        ),
        hasOpenTask: true,
        followUpDue: false,
      );
      expect(action.label, 'Retomar contato e ajustar plano');
      expect(action.isChatAction, isFalse);
    });

    test('open task without proxima acao falls back to Ver tarefa', () {
      final action = resolveOperacaoStickyAction(
        proximaAcao: const ProximaAcaoResumo(
          acao: '',
          motivo: 'x',
          fonte: 'PADRAO',
          prioridade: 'P2',
        ),
        hasOpenTask: true,
        followUpDue: false,
      );
      expect(action.label, 'Ver tarefa');
    });

    test('uses proxima acao label when no open task', () {
      final action = resolveOperacaoStickyAction(
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Enviar mensagem de follow-up',
          motivo: 'Contato pendente',
          fonte: 'PADRAO',
          prioridade: 'P2',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(action.label, 'Enviar mensagem de follow-up');
      expect(action.isChatAction, isTrue);
    });

    test('truncates long labels', () {
      final action = resolveOperacaoStickyAction(
        proximaAcao: ProximaAcaoResumo(
          acao: 'A' * 40,
          motivo: 'x',
          fonte: 'PADRAO',
          prioridade: 'P2',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(action.label.length, lessThanOrEqualTo(32));
      expect(action.label.endsWith('…'), isTrue);
    });
  });

  group('resolveOperacaoDominantMetric', () {
    test('prioritizes risk when em risco', () {
      final metric = resolveOperacaoDominantMetric(
        _aluno(emRisco: true, riscoNivel: 'ALTO'),
      );
      expect(metric.kind, OperacaoDominantMetricKind.risco);
      expect(metric.label, 'Foco do dia');
    });

    test('falls back to aderencia', () {
      final metric = resolveOperacaoDominantMetric(
        _aluno(aderenciaPercent: 55),
      );
      expect(metric.kind, OperacaoDominantMetricKind.aderencia);
      expect(metric.value, '55%');
    });
  });

  group('aderencia week parsing', () {
    test('summarize empty week', () {
      final summary = summarizeAderenciaWeek(const []);
      expect(summary.hasAnyCheckin, isFalse);
      expect(summary.caption, 'Sem check-ins');
    });

    test('summarize checkins total', () {
      final summary = summarizeAderenciaWeek(
        parseAderenciaSemanal(const [
          {'data': '2026-06-01', 'checkins': 2},
          {'data': '2026-06-02', 'checkins': 0},
        ]),
      );
      expect(summary.totalCheckins, 2);
      expect(summary.caption, '2 check-ins');
    });
  });

  group('copilot open task detection', () {
    test('finds IA copilot action', () {
      expect(findOpenCopilotTask([_openCopilotAction()]), isNotNull);
    });

    test('ignores closed actions', () {
      final closed = FilaAcaoResumo(
        tipo: 'IA_COPILOTO',
        actionKey: 'k',
        titulo: 'T',
        descricao: 'D',
        acaoUrl: '/x',
        prioridade: 'P2',
        severidade: 'MEDIA',
        responsavel: 'PERSONAL',
        sla: '24h',
        status: 'FECHADO',
        ctaLabel: 'Abrir',
        iaSugerida: true,
        createdFromInsight: false,
      );
      expect(findOpenCopilotTask([closed]), isNull);
    });
  });

  group('isAlunoFollowUpDue', () {
    test('true when follow-up date is today or past', () {
      final now = DateTime(2026, 6, 4, 12);
      final aluno = _aluno(proximoContato: '2026-06-04');
      expect(isAlunoFollowUpDue(aluno, now: now), isTrue);
    });
  });

  group('shouldShowCopilotProfileGapsButton', () {
    test('hides when only objective gap and hero covers it', () {
      expect(
        shouldShowCopilotProfileGapsButton(
          Aluno(
            id: 1,
            nome: 'Beatriz',
            email: 'b@test.com',
            status: 'ATIVO',
            telefone: '11999999999',
            genero: 'F',
            tipoConsultoria: 'PRESENCIAL',
          ),
          70,
        ),
        isFalse,
      );
    });

    test('shows when multiple profile gaps exist', () {
      expect(
        shouldShowCopilotProfileGapsButton(
          Aluno(
            id: 1,
            nome: 'Teste',
            email: 't@test.com',
            status: 'ATIVO',
          ),
          50,
        ),
        isTrue,
      );
    });
  });

  group('operacaoHeroShowsRisco', () {
    test('true for em risco with zero adherence', () {
      expect(
        operacaoHeroShowsRisco(
          _aluno(emRisco: true, riscoNivel: 'ALTO', aderenciaPercent: 0),
        ),
        isTrue,
      );
    });
  });

  group('parseAlunoDetailTabIndex', () {
    test('maps tab query aliases', () {
      expect(parseAlunoDetailTabIndex('operacao'), 0);
      expect(parseAlunoDetailTabIndex('evolucao'), 1);
      expect(parseAlunoDetailTabIndex('ferramentas'), 2);
      expect(parseAlunoDetailTabIndex(null), 0);
    });
  });

  group('weekdayLetterFromIso', () {
    test('returns D for Sunday', () {
      expect(weekdayLetterFromIso('2026-06-07'), 'D');
    });
  });
}

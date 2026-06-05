import 'package:flutter/material.dart';
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
    test('open task with contact acao opens chat destination', () {
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Retomar contato e ajustar plano',
          motivo: 'Radar',
          fonte: 'RADAR',
          prioridade: 'P1',
        ),
        hasOpenTask: true,
        followUpDue: false,
      );
      expect(action.label, 'Retomar contato');
      expect(action.destination, OperacaoStickyDestination.chat);
    });

    test('open task without proxima acao falls back to Ver tarefa', () {
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
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
      expect(action.destination, OperacaoStickyDestination.commandCenter);
    });

    test('uses chat destination for follow-up message', () {
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Enviar mensagem de follow-up',
          motivo: 'Contato pendente',
          fonte: 'PADRAO',
          prioridade: 'P2',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(action.label, 'Enviar mensagem');
      expect(action.destination, OperacaoStickyDestination.chat);
    });

    test('routes mapa corporal to evolucao with aligned label', () {
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Completar mapa corporal',
          motivo: 'Radar',
          fonte: 'RADAR',
          prioridade: 'P1',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(action.label, 'Completar mapa corporal');
      expect(action.destination, OperacaoStickyDestination.evolucao);
    });

    test('maps IA contate phrasing to chat sticky', () {
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
        proximaAcao: const ProximaAcaoResumo(
          acao:
              'Contate Beatriz para entender os motivos de sua inatividade e incentivá-la a sincronizar s',
          motivo: 'Radar',
          fonte: 'IA',
          prioridade: 'P1',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(action.label, 'Retomar contato · wearable');
      expect(action.destination, OperacaoStickyDestination.chat);
    });

    test('truncates long labels', () {
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
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

  group('operacaoStatusSubtitle', () {
    test('omits duplicate risk copy when hero already shows risk', () {
      final subtitle = operacaoStatusSubtitle(
        _aluno(emRisco: true),
        heroShowsRisco: true,
      );
      expect(subtitle, contains('Próximo contato'));
      expect(subtitle, isNot(contains('priorize contato')));
      expect(subtitle, isNot(contains('risco alto')));
    });
  });

  group('formatDiasSemTreinoDisplay', () {
    test('null shows sem registro', () {
      expect(formatDiasSemTreinoDisplay(null), 'Sem registro');
    });

    test('zero shows 0d', () {
      expect(formatDiasSemTreinoDisplay(0), '0d');
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
      expect(summary.caption, 'Sem dados');
    });

    test('summarize checkins total', () {
      final summary = summarizeAderenciaWeek(
        parseAderenciaSemanal(const [
          {'data': '2026-06-01', 'checkins': 2},
          {'data': '2026-06-02', 'checkins': 0},
        ]),
      );
      expect(summary.totalCheckins, 2);
      expect(summary.caption, '2 check-ins · 1 de 2 dias');
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

    test('shows when contact gap remains after hero objective cta', () {
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

    test('hides when sticky already routes to evolucao (mapa corporal)', () {
      expect(
        shouldShowCopilotProfileGapsButton(
          Aluno(
            id: 1,
            nome: 'Beatriz',
            email: 'b@test.com',
            status: 'ATIVO',
          ),
          50,
          sticky: const OperacaoStickyAction(
            label: 'Completar mapa corporal',
            icon: Icons.accessibility_new_rounded,
            destination: OperacaoStickyDestination.evolucao,
          ),
        ),
        isFalse,
      );
    });

    test('hides when sticky routes to edit for perfil gaps', () {
      expect(
        shouldShowCopilotProfileGapsButton(
          Aluno(
            id: 1,
            nome: 'Teste',
            email: 't@test.com',
            status: 'ATIVO',
          ),
          50,
          sticky: const OperacaoStickyAction(
            label: 'Definir objetivo',
            icon: Icons.edit_outlined,
            destination: OperacaoStickyDestination.editAluno,
          ),
        ),
        isFalse,
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

  group('operacao sticky secondary CTAs', () {
    test('hides copilot chat when sticky is chat action', () {
      const sticky = OperacaoStickyAction(
        label: 'Abrir chat',
        icon: Icons.chat_bubble_outline_rounded,
        destination: OperacaoStickyDestination.chat,
      );
      expect(
        shouldHideCopilotChatCta(sticky: sticky, hasOpenTask: false),
        isTrue,
      );
    });

    test('shows secondary command center when task open and chat primary', () {
      const sticky = OperacaoStickyAction(
        label: 'Retomar contato',
        icon: Icons.chat_bubble_outline_rounded,
        destination: OperacaoStickyDestination.chat,
      );
      expect(
        shouldShowStickySecondaryCommandCenter(
          sticky: sticky,
          hasOpenTask: true,
        ),
        isTrue,
      );
    });

    test('shows secondary chat on open task when follow-up due and CC primary', () {
      const sticky = OperacaoStickyAction(
        label: 'Ver tarefa',
        icon: Icons.open_in_new_rounded,
        destination: OperacaoStickyDestination.commandCenter,
      );
      expect(
        shouldShowStickySecondaryChat(
          sticky: sticky,
          hasOpenTask: true,
          followUpDue: true,
          proximaAcaoText: null,
        ),
        isTrue,
      );
    });
  });

  group('shouldShowCopilotPrescriptionBlock', () {
    test('shows prescription during IA refresh even when sticky matches 360', () {
      final aluno = _aluno();
      const sticky = OperacaoStickyAction(
        label: 'Completar mapa corporal',
        icon: Icons.accessibility_new_rounded,
        destination: OperacaoStickyDestination.evolucao,
      );
      expect(
        shouldShowCopilotPrescriptionBlock(
          forceIa: true,
          sticky: sticky,
          aluno: aluno,
          proximaAcaoRaw: 'Completar mapa corporal no radar',
        ),
        isTrue,
      );
    });

    test('hides duplicate when not forcing IA', () {
      final aluno = _aluno();
      const sticky = OperacaoStickyAction(
        label: 'Completar mapa corporal',
        icon: Icons.accessibility_new_rounded,
        destination: OperacaoStickyDestination.evolucao,
      );
      expect(
        shouldShowCopilotPrescriptionBlock(
          forceIa: false,
          sticky: sticky,
          aluno: aluno,
          proximaAcaoRaw: 'Completar mapa corporal no radar',
        ),
        isFalse,
      );
    });
  });

  group('shouldHideCopilotPrescriptionWhenMatchesSticky', () {
    test('hides when sticky label matches proxima acao', () {
      final aluno = _aluno();
      const sticky = OperacaoStickyAction(
        label: 'Completar mapa corporal',
        icon: Icons.accessibility_new_rounded,
        destination: OperacaoStickyDestination.evolucao,
      );
      expect(
        shouldHideCopilotPrescriptionWhenMatchesSticky(
          sticky: sticky,
          aluno: aluno,
          proximaAcaoRaw: 'Completar mapa corporal no radar',
        ),
        isTrue,
      );
    });

    test('shows when sticky differs from proxima acao', () {
      final aluno = _aluno();
      const sticky = OperacaoStickyAction(
        label: 'Abrir chat',
        icon: Icons.chat_bubble_outline_rounded,
        destination: OperacaoStickyDestination.chat,
      );
      expect(
        shouldHideCopilotPrescriptionWhenMatchesSticky(
          sticky: sticky,
          aluno: aluno,
          proximaAcaoRaw: 'Completar mapa corporal no radar',
        ),
        isFalse,
      );
    });
  });

  group('shouldHideCopilotPrimaryCtaWhenMatchesSticky', () {
    test('hides when sticky command center matches proxima acao', () {
      final aluno = _aluno();
      const acao = 'Reforçar aderência semanal do aluno';
      final sticky = resolveOperacaoStickyAction(
        aluno: aluno,
        proximaAcao: ProximaAcaoResumo(
          acao: acao,
          motivo: 'teste',
          fonte: 'PADRAO',
          prioridade: 'MEDIA',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(sticky.destination, OperacaoStickyDestination.commandCenter);
      expect(
        shouldHideCopilotPrimaryCtaWhenMatchesSticky(
          sticky: sticky,
          aluno: aluno,
          proximaAcaoRaw: acao,
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

  group('checkinMensagemPronta', () {
    test('uses first name in outreach copy', () {
      expect(
        checkinMensagemPronta('Beatriz Carvalho'),
        contains('Oi, Beatriz.'),
      );
    });

    test('falls back when name is empty', () {
      expect(checkinMensagemPronta(''), contains('Oi, aluno.'));
    });
  });

  group('alunoChatRouteExtra', () {
    test('includes draft for chat route', () {
      expect(
        alunoChatRouteExtra(nome: 'Ana', draft: 'Oi, Ana.'),
        {'nome': 'Ana', 'draft': 'Oi, Ana.'},
      );
    });

    test('omits empty draft', () {
      expect(
        alunoChatRouteExtra(nome: 'Ana', draft: '  '),
        {'nome': 'Ana'},
      );
    });
  });

  group('resolveStickyDisplayLabel', () {
    test('uses compact backend label when secondary visible', () {
      final label = resolveStickyDisplayLabel(
        sticky: const OperacaoStickyAction(
          label: 'Retomar contato · wearable',
          icon: Icons.chat,
          destination: OperacaoStickyDestination.chat,
        ),
        compact: true,
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Contate aluno',
          motivo: 'x',
          fonte: 'IA',
          prioridade: 'P1',
          stickyLabelCompact: 'Contato',
        ),
      );
      expect(label, 'Contato');
    });

    test('falls back to compact map for contact labels', () {
      expect(
        stickyLabelCompactFallback('Retomar contato · wearable'),
        'Contato',
      );
    });
  });

  group('isOperacaoContatoPrioritario', () {
    test('true when em risco', () {
      expect(
        isOperacaoContatoPrioritario(
          aluno: _aluno(emRisco: true),
          proximaAcao: null,
        ),
        isTrue,
      );
    });

    test('true for wearable tipo from backend', () {
      expect(
        isOperacaoContatoPrioritario(
          aluno: _aluno(),
          proximaAcao: const ProximaAcaoResumo(
            acao: 'Sync wearable',
            motivo: 'x',
            fonte: 'IA',
            prioridade: 'P1',
            tipoAcao: 'WEARABLE',
          ),
        ),
        isTrue,
      );
    });
  });

  group('resolveAluno360OperacaoSnapshot', () {
    test('hides task row when contact is priority without open task', () {
      final snapshot = resolveAluno360OperacaoSnapshot(
        aluno: _aluno(emRisco: true),
        proximaAcao360: const ProximaAcaoResumo(
          acao: 'Contate Beatriz para sync wearable',
          motivo: 'Sem treinos',
          fonte: 'IA',
          prioridade: 'P1',
          mensagemSugerida: 'Oi, Beatriz. Mensagem backend.',
        ),
        forceIa: false,
        iaAsync: null,
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(snapshot.contactPriority, isTrue);
      expect(snapshot.hideCopilotTaskRow, isTrue);
      expect(snapshot.showPrepareMessage, isTrue);
      expect(snapshot.outreachMessage, 'Oi, Beatriz. Mensagem backend.');
    });

    test('overrides mapa corporal sticky when em risco', () {
      final snapshot = resolveAluno360OperacaoSnapshot(
        aluno: _aluno(emRisco: true),
        proximaAcao360: const ProximaAcaoResumo(
          acao: 'Completar mapa corporal',
          motivo: 'Sem medidas',
          fonte: 'RADAR',
          prioridade: 'P2',
        ),
        forceIa: false,
        iaAsync: null,
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(snapshot.stickyAction.isChatAction, isTrue);
      expect(snapshot.stickyAction.label, 'Retomar contato');
      expect(snapshot.showPrepareMessage, isTrue);
      expect(snapshot.outreachMessage, contains('Teste'));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_logic.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';

String _isoDay(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

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

    test('routes planejar proxima evolucao to evolucao tab', () {
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Planejar próxima evolução',
          motivo: 'Radar',
          fonte: 'RADAR',
          prioridade: 'P2',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(action.destination, OperacaoStickyDestination.evolucao);
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

    test('routes alinhar financeiro to cobrar', () {
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Alinhar financeiro com o aluno',
          motivo: 'Radar',
          fonte: 'RADAR',
          prioridade: 'P1',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(action.label, 'Alinhar financeiro');
      expect(action.destination, OperacaoStickyDestination.financeiro);
    });

    test('empty next action on inadimplente cobras', () {
      final action = resolveOperacaoStickyAction(
        aluno: Aluno(
          id: 1,
          nome: 'Teste',
          email: 't@test.com',
          status: 'ATIVO',
          statusFinanceiro: 'INADIMPLENTE',
          inadimplente: true,
        ),
        proximaAcao: const ProximaAcaoResumo(
          acao: '',
          motivo: 'x',
          fonte: 'PADRAO',
          prioridade: 'P2',
        ),
        hasOpenTask: false,
        followUpDue: true,
      );
      expect(action.label, 'Cobrar mensalidade');
      expect(action.destination, OperacaoStickyDestination.financeiro);
    });

    test('routes atribuir treino to treinos list', () {
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Atribuir treino da semana',
          motivo: 'Radar',
          fonte: 'RADAR',
          prioridade: 'P1',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(action.destination, OperacaoStickyDestination.treino);
    });

    test('routes cadastro to editar aluno with aligned label', () {
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Completar cadastro',
          motivo: 'Radar',
          fonte: 'RADAR',
          prioridade: 'P1',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(action.label, 'Completar cadastro');
      expect(action.destination, OperacaoStickyDestination.editAluno);
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
  group('shouldShowCopilotContactBadge', () {
    test('shows when contact priority and sticky is not chat', () {
      expect(
        shouldShowCopilotContactBadge(
          contactPriority: true,
          sticky: const OperacaoStickyAction(
            label: 'Completar mapa',
            icon: Icons.person_outline,
            destination: OperacaoStickyDestination.editAluno,
          ),
        ),
        isTrue,
      );
    });

    test('hides when sticky already opens chat', () {
      expect(
        shouldShowCopilotContactBadge(
          contactPriority: true,
          sticky: const OperacaoStickyAction(
            label: 'Contato',
            icon: Icons.chat_rounded,
            destination: OperacaoStickyDestination.chat,
          ),
        ),
        isFalse,
      );
    });
  });
  group('aderencia week parsing', () {
    test('summarize empty week', () {
      final summary = summarizeAderenciaWeek(const []);
      expect(summary.hasAnyCheckin, isFalse);
      expect(summary.caption, 'Sem dados');
    });

    test('summarize checkins total', () {
      final today = DateTime.now();
      final anchor = DateTime(today.year, today.month, today.day);
      final day0 = anchor.subtract(const Duration(days: 1));
      final day1 = anchor;

      final summary = summarizeAderenciaWeek(
        parseAderenciaSemanal([
          {'data': _isoDay(day0), 'checkins': 2},
          {'data': _isoDay(day1), 'checkins': 0},
        ]),
      );
      expect(summary.totalCheckins, 2);
      expect(summary.caption, '2 check-ins · 1 de 7 dias');
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
          Aluno(id: 1, nome: 'Teste', email: 't@test.com', status: 'ATIVO'),
          50,
        ),
        isTrue,
      );
    });

    test('hides when sticky already routes to evolucao (mapa corporal)', () {
      expect(
        shouldShowCopilotProfileGapsButton(
          Aluno(id: 1, nome: 'Beatriz', email: 'b@test.com', status: 'ATIVO'),
          50,
          sticky: const OperacaoStickyAction(
            label: 'Completar cadastro',
            icon: Icons.monitor_weight_outlined,
            destination: OperacaoStickyDestination.editAluno,
          ),
        ),
        isFalse,
      );
    });

    test('hides when sticky routes to edit for perfil gaps', () {
      expect(
        shouldShowCopilotProfileGapsButton(
          Aluno(id: 1, nome: 'Teste', email: 't@test.com', status: 'ATIVO'),
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

    test(
      'shows secondary chat on open task when follow-up due and CC primary',
      () {
        const sticky = OperacaoStickyAction(
          label: 'Ver tarefa',
          icon: Icons.dashboard_outlined,
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
      },
    );
  });

  group('shouldShowCopilotPrescriptionBlock', () {
    test(
      'hides clone even after IA refresh when sticky already owns the action',
      () {
        final aluno = _aluno();
        const sticky = OperacaoStickyAction(
          label: 'Completar cadastro',
          icon: Icons.monitor_weight_outlined,
          destination: OperacaoStickyDestination.editAluno,
        );
        expect(
          shouldShowCopilotPrescriptionBlock(
            sticky: sticky,
            aluno: aluno,
            proximaAcaoRaw: 'Completar cadastro no radar',
          ),
          isFalse,
        );
      },
    );

    test('hides duplicate when sticky matches 360', () {
      final aluno = _aluno();
      const sticky = OperacaoStickyAction(
        label: 'Completar cadastro',
        icon: Icons.monitor_weight_outlined,
        destination: OperacaoStickyDestination.editAluno,
      );
      expect(
        shouldShowCopilotPrescriptionBlock(
          sticky: sticky,
          aluno: aluno,
          proximaAcaoRaw: 'Completar cadastro no radar',
        ),
        isFalse,
      );
    });

    test('keeps prescription for contact priority even with chat sticky', () {
      final aluno = _aluno(emRisco: true);
      const sticky = OperacaoStickyAction(
        label: 'Retomar contato',
        icon: Icons.chat_rounded,
        destination: OperacaoStickyDestination.chat,
      );
      expect(
        shouldShowCopilotPrescriptionBlock(
          sticky: sticky,
          aluno: aluno,
          proximaAcaoRaw: 'Retomar contato com Thales e checar o treino.',
          contactPriority: true,
        ),
        isTrue,
      );
    });
  });

  group('shouldHideCopilotPrescriptionWhenMatchesSticky', () {
    test('hides when sticky label matches proxima acao', () {
      final aluno = _aluno();
      const sticky = OperacaoStickyAction(
        label: 'Completar cadastro',
        icon: Icons.monitor_weight_outlined,
        destination: OperacaoStickyDestination.editAluno,
      );
      expect(
        shouldHideCopilotPrescriptionWhenMatchesSticky(
          sticky: sticky,
          aluno: aluno,
          proximaAcaoRaw: 'Completar cadastro no radar',
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
          proximaAcaoRaw: 'Completar cadastro no radar',
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

    test('hides when sticky commitment matches sono acao', () {
      final aluno = _aluno();
      const acao = 'Combinar sono desta semana';
      final sticky = resolveOperacaoStickyAction(
        aluno: aluno,
        proximaAcao: const ProximaAcaoResumo(
          acao: acao,
          motivo: 'teste',
          fonte: 'PADRAO',
          prioridade: 'MEDIA',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(sticky.destination, OperacaoStickyDestination.commitment);
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
    test('returns Do for Sunday', () {
      expect(weekdayLetterFromIso('2026-06-07'), 'Do');
    });

    test('returns distinct Qa and Qi for Wednesday and Thursday', () {
      expect(weekdayLetterFromIso('2026-06-03'), 'Qa');
      expect(weekdayLetterFromIso('2026-06-04'), 'Qi');
    });

    test('parseIsoDateLocal ignores UTC midnight drift', () {
      final parsed = parseIsoDateLocal('2026-06-04');
      expect(parsed?.weekday, DateTime.thursday);
      expect(weekdayNameFromIso('2026-06-04'), 'Qui');
    });
  });

  group('adherenceDayLetter', () {
    test('derives from local ISO even when API sends legacy label', () {
      expect(
        adherenceDayLetter(
          const AderenciaWeekPoint(
            checkins: 0,
            date: '2026-06-04',
            dayLetter: 'I',
          ),
        ),
        'Qi',
      );
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
      expect(alunoChatRouteExtra(nome: 'Ana', draft: 'Oi, Ana.'), {
        'nome': 'Ana',
        'draft': 'Oi, Ana.',
      });
    });

    test('omits empty draft', () {
      expect(alunoChatRouteExtra(nome: 'Ana', draft: '  '), {'nome': 'Ana'});
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

    test('compact map label when secondary visible with long mapa label', () {
      expect(
        resolveStickyDisplayLabel(
          sticky: const OperacaoStickyAction(
            label: 'Completar cadastro',
            icon: Icons.chat_bubble_outline_rounded,
            destination: OperacaoStickyDestination.chat,
          ),
          compact: true,
          proximaAcao: const ProximaAcaoResumo(
            acao: 'Completar cadastro',
            motivo: 'Sem medidas',
            fonte: 'RADAR',
            prioridade: 'P2',
            stickyLabel: 'Completar cadastro',
          ),
        ),
        'Cadastro',
      );
    });

    test('ignores backend compact label when too long', () {
      expect(
        resolveStickyDisplayLabel(
          sticky: const OperacaoStickyAction(
            label: 'Completar cadastro',
            icon: Icons.chat_bubble_outline_rounded,
            destination: OperacaoStickyDestination.chat,
          ),
          compact: true,
          proximaAcao: const ProximaAcaoResumo(
            acao: 'Completar cadastro',
            motivo: 'Sem medidas',
            fonte: 'RADAR',
            prioridade: 'P2',
            stickyLabelCompact: 'Completar cadastro',
          ),
        ),
        'Cadastro',
      );
    });

    test('ignores backend Mapa when sticky overridden to contact', () {
      expect(
        resolveStickyDisplayLabel(
          sticky: const OperacaoStickyAction(
            label: 'Retomar contato',
            icon: Icons.chat_bubble_outline_rounded,
            destination: OperacaoStickyDestination.chat,
          ),
          compact: true,
          proximaAcao: const ProximaAcaoResumo(
            acao: 'Completar cadastro',
            motivo: 'Sem medidas',
            fonte: 'RADAR',
            prioridade: 'P2',
            stickyLabelCompact: 'Cadastro',
          ),
        ),
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
  group('resolveOperacaoContactPriority', () {
    test('prefers BE uiHints over local heuristics', () {
      expect(
        resolveOperacaoContactPriority(
          aluno: _aluno(emRisco: false, aderenciaPercent: 80),
          proximaAcao: null,
          uiHints: const OperacaoUiHints(
            contactPriority: true,
            defaultFocusMode: true,
            compactFollowUp: true,
          ),
        ),
        isTrue,
      );
    });
  });

  group('padAderenciaWeekToSevenDays', () {
    test('pads empty input to seven distinct days', () {
      final points = padAderenciaWeekToSevenDays(const []);
      expect(points.length, 7);
      expect(points.map((p) => p.date).toSet().length, 7);
      expect(points.every((p) => p.checkins == 0), isTrue);
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
      expect(snapshot.stickyAction.isChatAction, isTrue);
      expect(snapshot.showPrepareMessage, isFalse);
      expect(snapshot.outreachMessage, 'Oi, Beatriz. Mensagem backend.');
    });

    test('overrides mapa corporal sticky when em risco', () {
      final snapshot = resolveAluno360OperacaoSnapshot(
        aluno: _aluno(emRisco: true),
        proximaAcao360: const ProximaAcaoResumo(
          acao: 'Completar cadastro',
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
      expect(snapshot.showPrepareMessage, isFalse);
      expect(snapshot.outreachMessage, contains('Teste'));
    });

    test('uses compact map label when chat primary and task open', () {
      final snapshot = resolveAluno360OperacaoSnapshot(
        aluno: _aluno(),
        proximaAcao360: const ProximaAcaoResumo(
          acao: 'Contate aluno sobre check-in',
          motivo: 'Sem resposta',
          fonte: 'IA',
          prioridade: 'P1',
          stickyLabel: 'Completar cadastro',
          stickyLabelCompact: 'Cadastro',
        ),
        forceIa: false,
        iaAsync: null,
        hasOpenTask: true,
        followUpDue: false,
      );
      expect(snapshot.stickyAction.isChatAction, isTrue);
      expect(
        hasOperacaoStickySecondary(
          sticky: snapshot.stickyAction,
          hasOpenTask: true,
          followUpDue: false,
          proximaAcaoText: snapshot.effectiveProxima?.acao,
        ),
        isTrue,
      );
      expect(snapshot.stickyDisplayLabel, 'Cadastro');
    });
  });
  group('AderenciaDiaStatus', () {
    test('parses backend values case-insensitively', () {
      expect(parseAderenciaDiaStatus('TREINOU'), AderenciaDiaStatus.treinou);
      expect(parseAderenciaDiaStatus('faltou'), AderenciaDiaStatus.faltou);
      expect(parseAderenciaDiaStatus('SEM_PLANO'), AderenciaDiaStatus.semPlano);
      expect(parseAderenciaDiaStatus(' HOJE '), AderenciaDiaStatus.hoje);
      expect(parseAderenciaDiaStatus(null), isNull);
      expect(parseAderenciaDiaStatus('OUTRO'), isNull);
    });

    test('AderenciaDia round-trips status and omits when absent', () {
      final dia = AderenciaDia.fromJson({
        'data': '2026-06-01',
        'labelDia': 'S',
        'checkins': 0,
        'status': 'FALTOU',
      });
      expect(dia.status, 'FALTOU');
      expect(dia.toMap()['status'], 'FALTOU');

      final legado = AderenciaDia.fromJson({'data': '2026-06-01'});
      expect(legado.status, isNull);
      expect(legado.toMap().containsKey('status'), isFalse);
    });

    test('parseAderenciaSemanal carries status through padding', () {
      final today = DateTime.now();
      final anchor = DateTime(today.year, today.month, today.day);
      final ontem = anchor.subtract(const Duration(days: 1));
      final points = parseAderenciaSemanal([
        {'data': _isoDay(ontem), 'checkins': 0, 'status': 'FALTOU'},
        {'data': _isoDay(anchor), 'checkins': 0, 'status': 'HOJE'},
      ]);
      expect(points.length, 7);
      expect(points[5].status, AderenciaDiaStatus.faltou);
      expect(points[6].status, AderenciaDiaStatus.hoje);
      expect(points.first.status, isNull);
    });
  });

  group('aluno360CopilotHasPriorityCardContent', () {
    test('true for deterministic proximaAcao from /360', () {
      expect(
        aluno360CopilotHasPriorityCardContent(
          proximaAcao360: ProximaAcaoResumo(
            acao: 'Retomar contato',
            motivo: 'teste',
            fonte: 'RADAR',
            prioridade: 'P1',
          ),
          forceIa: false,
          iaHasValue: false,
          hasOpenTask: false,
        ),
        isTrue,
      );
    });

    test('false when there is no action yet', () {
      expect(
        aluno360CopilotHasPriorityCardContent(
          proximaAcao360: null,
          forceIa: false,
          iaHasValue: false,
          hasOpenTask: false,
        ),
        isFalse,
      );
    });
  });
  group('weekdayNameFromIso', () {
    test('returns weekday name for valid iso', () {
      expect(weekdayNameFromIso('2026-06-04'), isNotEmpty);
    });
  });
  group('acaoSugereCommitment', () {
    test('maps sleep wording to commitment destination', () {
      expect(acaoSugereCommitment('Combinar sono com o aluno'), isTrue);
      expect(acaoSugereCommitment('Ajustar horário da noite'), isTrue);
      expect(acaoSugereCommitment('Retomar contato'), isFalse);
      final action = resolveOperacaoStickyAction(
        aluno: _aluno(),
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Combinar sono desta semana',
          motivo: 'Wearable',
          fonte: 'IA',
          prioridade: 'P2',
        ),
        hasOpenTask: false,
        followUpDue: false,
      );
      expect(action.label, 'Combinar sono');
      expect(action.destination, OperacaoStickyDestination.commitment);
    });
  });
}

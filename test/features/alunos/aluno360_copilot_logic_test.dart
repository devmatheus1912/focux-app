import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_logic.dart';
import 'package:focux_app/features/dashboard/data/command_center_data.dart';

Aluno _aluno({
  String? telefone,
  String? whatsapp,
  String? objetivo,
  String? genero,
  String? tipoConsultoria,
  String statusFinanceiro = 'ATIVO',
  bool emRisco = false,
  int? aderenciaPercent,
}) {
  return Aluno(
    id: 1,
    nome: 'Beatriz',
    email: 'b@test.com',
    status: 'ATIVO',
    telefone: telefone,
    whatsapp: whatsapp,
    objetivo: objetivo,
    genero: genero,
    tipoConsultoria: tipoConsultoria,
    statusFinanceiro: statusFinanceiro,
    emRisco: emRisco,
    aderenciaPercent: aderenciaPercent,
  );
}

void main() {
  group('copilotActionFromIa', () {
    test('maps IA payload to display action', () {
      final action = copilotActionFromIa(const {
        'acao': 'Enviar mensagem curta pedindo retorno ao treino',
        'motivo': '14 dias sem atividade',
      });
      expect(action['titulo'], 'Sugestão IA');
      expect(action['fonte'], 'IA');
      expect(action['acao'], contains('mensagem'));
    });
  });

  group('resolveCopilotProximaAcaoResumo', () {
    test('prefers IA action when forceIa succeeds', () {
      const seed = ProximaAcaoResumo(
        acao: 'Completar mapa corporal no radar',
        motivo: '360',
        fonte: 'RADAR',
        prioridade: 'P1',
      );
      final merged = resolveCopilotProximaAcaoResumo(
        proximaAcao360: seed,
        forceIa: true,
        iaAsync: const AsyncValue.data({
          'acao': 'Retomar contato com mensagem objetiva sobre aderência',
          'motivo': 'Baixa frequência nos últimos 14 dias',
        }),
      );
      expect(merged?.fonte, 'IA');
      expect(merged?.acao, contains('Retomar contato'));
    });

    test('falls back to 360 when forceIa is false', () {
      const seed = ProximaAcaoResumo(
        acao: 'Completar mapa corporal no radar',
        motivo: '360',
        fonte: 'RADAR',
        prioridade: 'P1',
      );
      final merged = resolveCopilotProximaAcaoResumo(
        proximaAcao360: seed,
        forceIa: false,
        iaAsync: null,
      );
      expect(merged, seed);
    });
  });

  group('copilotProfileCompletion', () {
    test('returns 100 when all profile fields filled', () {
      expect(
        copilotProfileCompletion(
          _aluno(
            telefone: '11999999999',
            whatsapp: '11999999999',
            objetivo: 'Hipertrofia',
            genero: 'F',
            tipoConsultoria: 'ONLINE',
          ),
        ),
        100,
      );
    });

    test('returns partial score for sparse profile', () {
      final score = copilotProfileCompletion(
        _aluno(telefone: '11999999999'),
      );
      expect(score, greaterThan(0));
      expect(score, lessThan(100));
    });
  });

  group('copilotActionFrom360', () {
    test('maps radar fonte to titulo', () {
      final action = copilotActionFrom360(
        const ProximaAcaoResumo(
          acao: 'Retomar contato',
          motivo: 'Risco',
          fonte: 'RADAR',
          prioridade: 'P1',
        ),
      );
      expect(action['titulo'], 'Radar Focux');
      expect(action['acao'], 'Retomar contato');
    });
  });

  group('cleanCopilotText', () {
    test('strips markdown and bullets', () {
      expect(
        cleanCopilotText('**Retomar** contato\n- ajustar plano'),
        'Retomar contato ajustar plano',
      );
    });
  });

  group('copilotMensagemPronta', () {
    test('uses finance template', () {
      final msg = copilotMensagemPronta(
        _aluno(),
        'Regularizar pendência financeira',
      );
      expect(msg, contains('pendência'));
      expect(msg, contains('Beatriz'));
    });
  });

  group('copilotFallbackAction', () {
    test('prioritizes finance when inadimplente', () {
      final action = copilotFallbackAction(
        _aluno(statusFinanceiro: 'INADIMPLENTE'),
        null,
      );
      expect(action, contains('financeiro'));
    });

    test('suggests profile completion when sparse', () {
      final action = copilotFallbackAction(_aluno(), null);
      expect(action, contains('perfil'));
    });
  });

  group('resolveCopilotProfileGaps', () {
    test('returns contact and profile gaps for empty aluno', () {
      final gaps = resolveCopilotProfileGaps(_aluno());
      expect(gaps.length, greaterThanOrEqualTo(2));
      expect(gaps.any((g) => g.title == 'Contato'), isTrue);
    });
  });

  group('resolveCopilotSignals', () {
    test('builds four signal chips', () {
      final signals = resolveCopilotSignals(
        aluno: _aluno(telefone: '11999999999', objetivo: 'Força'),
        resumo: null,
        primary: Colors.teal,
      );
      expect(signals, hasLength(4));
      expect(signals.first.label, 'Perfil');
    });
  });

  group('resolveCopilotPrescriptionFromAction', () {
    test('maps action fields to display copy', () {
      final content = resolveCopilotPrescriptionFromAction(
        _aluno(),
        const {
          'titulo': 'Radar Focux',
          'acao': 'Retomar contato e ajustar plano',
          'motivo': 'Aluno em risco',
        },
        'fallback',
      );
      expect(content.title, 'Radar Focux');
      expect(content.action, contains('Retomar contato'));
      expect(content.reason, 'Aluno em risco');
    });

    test('maps mapa corporal to specific copy', () {
      final content = resolveCopilotPrescriptionFromAction(
        _aluno(),
        const {
          'titulo': 'Radar Focux',
          'acao': 'Completar mapa corporal',
          'motivo': 'Ação humana hoje',
        },
        'fallback',
      );
      expect(content.action, contains('mapa corporal'));
    });
  });

  group('copilotCardSubtitle', () {
    test('shows IA loading copy', () {
      expect(
        copilotCardSubtitle(
          forceIa: true,
          iaAsync: const AsyncValue.loading(),
          resumoLoading: false,
        ),
        'Gerando sugestão com IA…',
      );
    });

    test('shows IA success copy', () {
      expect(
        copilotCardSubtitle(
          forceIa: true,
          iaAsync: const AsyncValue.data({'acao': 'Teste'}),
          resumoLoading: false,
        ),
        'Atualizado com IA · toque em atualizar para regenerar',
      );
    });

    test('falls back to profile copy', () {
      expect(
        copilotCardSubtitle(
          forceIa: false,
          iaAsync: null,
          resumoLoading: false,
        ),
        'Sugestão com base no perfil de hoje.',
      );
    });
  });

  group('copilotPrescriptionDisplayAction', () {
    test('shortens contact plus wearable IA paragraph', () {
      final aluno = _aluno();
      const raw =
          'Entre em contato com Beatriz Carvalho para reavivar o interesse no treinamento e solicitar a sincronização dos dados do wearable.';
      expect(
        copilotPrescriptionDisplayAction(aluno, raw),
        'Retomar contato e pedir sync do wearable.',
      );
      expect(
        copilotPrescriptionFullAction(aluno, raw),
        contains('Beatriz Carvalho'),
      );
    });

    test('resolveCopilotPrescriptionFromAction keeps full IA text for expand', () {
      final aluno = _aluno();
      const raw =
          'Entre em contato com Beatriz Carvalho para reavivar o interesse no treinamento e solicitar a sincronização dos dados do wearable.';
      final content = resolveCopilotPrescriptionFromAction(
        aluno,
        copilotActionFromIa(const {
          'acao': raw,
          'motivo': 'Última atividade há 999 dia(s), aderência de 0%',
        }),
        'fallback',
      );
      expect(content.action, 'Retomar contato e pedir sync do wearable.');
      expect(content.fullAction, contains('sincronização'));
    });

    test('drops fullAction when only name or punctuation differs', () {
      expect(
        copilotPrescriptionActionsEquivalent(
          'Retomar contato e checar como está o treino.',
          'Retomar contato com Beatriz e checar como está o treino.',
        ),
        isTrue,
      );
      final content = resolveCopilotPrescriptionFromAction(
        _aluno(),
        copilotActionFromIa(const {
          'acao': 'Retomar contato e checar como está o treino.',
          'motivo': 'Priorize contato · sem registro recente · aderência 0%',
        }),
        'fallback',
      );
      expect(content.fullAction, isNull);
    });
  });

  group('copilotPrescriptionActionsEquivalent', () {
    test('treats embedded first name as equivalent', () {
      expect(
        copilotPrescriptionActionsEquivalent(
          'Retomar contato com Beatriz e checar como está o treino.',
          'Retomar contato e checar como está o treino',
        ),
        isTrue,
      );
    });

    test('keeps meaningfully different IA paragraphs distinct', () {
      expect(
        copilotPrescriptionActionsEquivalent(
          'Retomar contato e pedir sync do wearable.',
          'Entre em contato com Beatriz para reavivar e solicitar sincronização do wearable.',
        ),
        isFalse,
      );
    });
  });

  group('copilotPrescriptionReasonSegments', () {
    test('splits footer motivo on middle dots', () {
      expect(
        copilotPrescriptionReasonSegments(
          'Priorize contato · sem registro recente · aderência 0%',
        ),
        [
          'Priorize contato',
          'sem registro recente',
          'aderência 0%',
        ],
      );
    });
  });

  group('normalizeIaCopilotAcao', () {
    test('strips LLM preamble and capitalizes action', () {
      expect(
        normalizeIaCopilotAcao(
          'A próxima ação mais importante é enviar uma mensagem de contato.',
        ),
        'Enviar uma mensagem de contato.',
      );
    });

    test('fixes english leak in expanded IA action', () {
      final text = normalizeIaCopilotAcao(
        'Contate Beatriz para understanding os motivos da interrupção nos treinos '
        'e discutir um plano de retomada personalizado.',
      );
      expect(text.toLowerCase(), isNot(contains('understanding')));
      expect(text.toLowerCase(), contains('entender'));
      expect(text.toLowerCase(), contains('personalizado'));
    });
  });

  group('copilotCardTitle', () {
    test('uses Prioridade do dia when contact priority', () {
      expect(copilotCardTitle(contactPriority: true), 'Prioridade do dia');
    });

    test('uses Próxima melhor ação otherwise', () {
      expect(copilotCardTitle(contactPriority: false), 'Próxima melhor ação');
    });
  });

  group('formatCopilotIaMotivo', () {
    test('humanizes 999 days without treino', () {
      expect(
        formatCopilotIaMotivo('Última atividade há 999 dia(s), aderência de 0%'),
        contains('Sem treinos recentes'),
      );
    });

    test('humanizes recent inactivity', () {
      expect(
        formatCopilotIaMotivo('Última atividade há 14 dia(s), aderência de 0%'),
        'Sem treino há 14 dias · aderência de 0%.',
      );
    });

    test('humanizes enrichment contato motivo with 999 days', () {
      expect(
        formatCopilotIaMotivo(
          'Priorize contato · 999 dia(s) sem atividade · aderência 0%',
        ),
        'Priorize contato · sem registro recente · aderência 0%.',
      );
    });
  });

  group('copilotChatActionLabel', () {
    test('returns short sticky label for chat actions', () {
      expect(
        copilotChatActionLabel(
          'A próxima ação mais importante é enviar mensagem de contato',
        ),
        'Enviar mensagem',
      );
    });
  });

  group('copilotStickyLabel', () {
    test('uses short label instead of truncated IA preamble', () {
      expect(
        copilotStickyLabel(
          _aluno(),
          'A próxima ação mais importante é enviar mensagem de contato',
        ),
        'Enviar mensagem',
      );
    });

    test('aligns sticky and prescription for mapa corporal', () {
      expect(
        copilotStickyLabel(_aluno(), 'Completar mapa corporal'),
        'Completar mapa corporal',
      );
    });

    test('maps IA contate phrasing to Retomar contato', () {
      expect(
        copilotStickyLabel(
          _aluno(),
          'Contate Beatriz para entender os motivos de sua inatividade e incentivá-la a sincronizar s',
        ),
        'Retomar contato · wearable',
      );
    });

    test('drops wearable label when aluno never connected', () {
      expect(
        copilotStickyLabel(
          _aluno(),
          'Pedir sync do wearable ao aluno',
          wearableRelevant: false,
        ),
        'Retomar contato',
      );
    });
  });

  group('sanitizeProximaAcaoWearable', () {
    test('rewrites wearable IA payload when no history', () {
      final sanitized = sanitizeProximaAcaoWearable(
        _aluno(),
        const ProximaAcaoResumo(
          acao: 'Pedir sync do wearable',
          motivo: 'Sem treinos',
          fonte: 'IA',
          prioridade: 'P1',
          tipoAcao: 'WEARABLE',
          mensagemSugerida: 'Oi, Beatriz. Vi que seu wearable não sincronizou.',
          stickyLabel: 'Retomar contato · wearable',
          stickyLabelCompact: 'Contato',
        ),
        wearableRelevant: false,
      );
      expect(sanitized.tipoAcao, 'CONTATO');
      expect(sanitized.stickyLabel, 'Retomar contato');
      expect(sanitized.mensagemSugerida, isNot(contains('wearable')));
    });
  });

  group('copilotPrescriptionDisplayAction', () {
    test('uses contact copy instead of wearable when no history', () {
      expect(
        copilotPrescriptionDisplayAction(
          _aluno(),
          'Pedir sync do wearable',
          wearableRelevant: false,
        ),
        'Retomar contato e checar como está o treino.',
      );
    });
  });

  group('resolveOutreachMessage', () {
    test('prefers backend mensagem sugerida', () {
      expect(
        resolveOutreachMessage(
          _aluno(),
          acao: 'Contate Beatriz',
          backendMessage: 'Oi, Beatriz. Mensagem do servidor.',
        ),
        'Oi, Beatriz. Mensagem do servidor.',
      );
    });

    test('sanitizes backend juntos for feminine profile', () {
      expect(
        resolveOutreachMessage(
          _aluno(genero: 'Feminino'),
          acao: 'Contate Beatriz',
          backendMessage:
              'Oi, Beatriz. Quer retomar juntos? Me responde por aqui.',
        ),
        contains('juntas'),
      );
    });

    test('neutralizes backend juntos when gender unknown', () {
      expect(
        resolveOutreachMessage(
          _aluno(),
          acao: 'Contate Beatriz',
          backendMessage: 'Quer retomar juntos?',
        ),
        'Quer retomar juntos(as)?',
      );
    });
  });

  group('copilotMensagemPronta gender agreement', () {
    test('uses juntas for feminine profile', () {
      final msg = copilotMensagemPronta(
        _aluno(genero: 'Feminino'),
        'Contate o aluno por inatividade',
      );
      expect(msg, contains('juntas'));
      expect(msg, isNot(contains('juntos?')));
    });

    test('uses juntos for masculine profile', () {
      final msg = copilotMensagemPronta(
        _aluno(genero: 'Masculino'),
        'Contate o aluno por inatividade',
      );
      expect(msg, contains('juntos?'));
      expect(msg, isNot(contains('juntas')));
    });

    test('uses neutral fallback when gender unknown', () {
      final msg = copilotMensagemPronta(
        _aluno(),
        'Contate o aluno por inatividade',
      );
      expect(msg, contains('juntos(as)'));
    });
  });

  group('contactPriorityPrescriptionContent', () {
    test('surfaces risk and adherence in reason', () {
      final content = contactPriorityPrescriptionContent(
        _aluno(emRisco: true, aderenciaPercent: 0),
      );
      expect(content.title, 'Prioridade do dia');
      expect(content.action, contains('Retomar contato'));
      expect(content.reason, contains('Risco operacional'));
    });
  });

  group('proximaAcaoResumoFromIaPayload', () {
    test('parses enrichment fields from IA API', () {
      final resumo = proximaAcaoResumoFromIaPayload({
        'acao': 'Contate Beatriz para sync wearable',
        'motivo': 'Sem treinos recentes',
        'tipoAcao': 'WEARABLE',
        'mensagemSugerida': 'Oi, Beatriz. Sync.',
        'stickyLabel': 'Retomar contato · wearable',
        'stickyLabelCompact': 'Contato',
      });
      expect(resumo?.tipoAcao, 'WEARABLE');
      expect(resumo?.mensagemSugerida, 'Oi, Beatriz. Sync.');
      expect(resumo?.stickyLabelCompact, 'Contato');
    });
  });

  group('copilotProfileGapsForCard', () {
    test('drops objective gap when hero already prompts it', () {
      final gaps = copilotProfileGapsForCard(
        Aluno(
          id: 1,
          nome: 'Beatriz',
          email: 'b@test.com',
          status: 'ATIVO',
        ),
      );
      expect(gaps.any((g) => g.title == 'Objetivo'), isFalse);
      expect(gaps.any((g) => g.title == 'Contato'), isTrue);
    });
  });
}

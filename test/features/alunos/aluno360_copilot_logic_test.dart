import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_logic.dart';
import 'package:focux_app/features/ia/models/ia_copilot_proxima_acao.dart';

IaCopilotProximaAcao _iaPayload(Map<String, dynamic> json) =>
    IaCopilotProximaAcao.fromJson(json);

Aluno _aluno({
  String nome = 'Beatriz',
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
    nome: nome,
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
  });

  group('resolveCopilotProximaAcaoResumo', () {
    test('prefers IA action when forceIa succeeds', () {
      const seed = ProximaAcaoResumo(
        acao: 'Completar cadastro no radar',
        motivo: '360',
        fonte: 'RADAR',
        prioridade: 'P1',
      );
      final merged = resolveCopilotProximaAcaoResumo(
        proximaAcao360: seed,
        forceIa: true,
        iaAsync: AsyncValue.data(_iaPayload({
          'acao': 'Retomar contato com mensagem objetiva sobre aderência',
          'motivo': 'Baixa frequência nos últimos 14 dias',
        })),
      );
      expect(merged?.fonte, 'IA');
      expect(merged?.acao, contains('Retomar contato'));
    });

    test('falls back to 360 when forceIa is false', () {
      const seed = ProximaAcaoResumo(
        acao: 'Completar cadastro no radar',
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
    test('conta os 8 campos do backend: faltam peso, altura, nascimento e foto', () {
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
        50,
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
  group('resolveCopilotPrescriptionFromAction', () {

  });

  group('copilotCardSubtitle', () {





  });

  group('resolveCopilotPriorityCardState', () {




  });

  group('copilotPrescriptionDisplayAction', () {

  });
  group('copilotPrescriptionReasonSegments', () {
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
        copilotStickyLabel(_aluno(), 'Completar cadastro'),
        'Completar cadastro',
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

    test('maps sleep habit to Combinar sono', () {
      expect(
        copilotStickyLabel(
          _aluno(),
          'Durma pelo menos 8 horas na noite de hoje.',
        ),
        'Combinar sono',
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

  });

  group('resolveCopilotPrescriptionFromAction', () {
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

  });

  group('sanitizeCopilotPrescriptionReason', () {


  });

  group('copilotExecutarConfirmBody', () {
    test('returns distinct copy per backend tipo', () {
      expect(
        copilotExecutarConfirmBody('REDUZIR_CARGA'),
        contains('15%'),
      );
      expect(
        copilotExecutarConfirmBody('ENVIAR_PUSH'),
        contains('notificação'),
      );
      expect(
        copilotExecutarConfirmBody('MARCAR_RISCO'),
        contains('contato prioritário'),
      );
      expect(
        copilotExecutarConfirmBody('UNKNOWN'),
        contains('Confirme'),
      );
    });
  });

  group('proximaAcaoResumoFromIaPayload', () {
    test('parses enrichment fields from IA API', () {
      final resumo = proximaAcaoResumoFromIaPayload(_iaPayload({
        'acao': 'Contate Beatriz para sync wearable',
        'motivo': 'Sem treinos recentes',
        'tipoAcao': 'WEARABLE',
        'mensagemSugerida': 'Oi, Beatriz. Sync.',
        'stickyLabel': 'Retomar contato · wearable',
        'stickyLabelCompact': 'Contato',
      }));
      expect(resumo?.tipoAcao, 'WEARABLE');
      expect(resumo?.mensagemSugerida, 'Oi, Beatriz. Sync.');
      expect(resumo?.stickyLabelCompact, 'Contato');
    });
  });

  group('copilotProfileGapsForCard', () {
  });

  group('resolveCopilotExecutarAcao', () {
  });
}

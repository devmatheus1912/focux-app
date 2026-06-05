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

  group('copilotStickyLabel', () {
    test('aligns sticky and prescription for mapa corporal', () {
      expect(
        copilotStickyLabel(_aluno(), 'Completar mapa corporal'),
        'Completar mapa corporal',
      );
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

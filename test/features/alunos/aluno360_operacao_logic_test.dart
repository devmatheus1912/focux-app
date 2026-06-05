import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';

void main() {
  group('resolveOperacaoStickyAction', () {
    test('open task wins over proxima acao', () {
      final action = resolveOperacaoStickyAction(
        proximaAcao: const ProximaAcaoResumo(
          acao: 'Enviar mensagem',
          motivo: 'x',
          fonte: 'PADRAO',
          prioridade: 'P2',
        ),
        hasOpenTask: true,
        followUpDue: false,
      );
      expect(action.label, 'Ver tarefa');
      expect(action.isChatAction, isFalse);
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

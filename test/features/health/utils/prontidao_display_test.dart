import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/health/data/health_repository.dart';
import 'package:focux_app/features/health/utils/prontidao_display.dart';
import 'package:focux_app/l10n/app_localizations.dart';

RecoverySnapshot _snap({
  int? score = 77,
  String label = 'Pronto para treinar',
  String hint = 'Boa noite de sono.',
  DateTime? dataReferencia,
}) => RecoverySnapshot(
  dataReferencia: dataReferencia,
  steps: 0,
  caloriesBurned: 0,
  avgHeartRate: 0,
  sleepHours: 0,
  recoveryScore: score,
  recoveryLabel: label,
  recoveryHint: hint,
);

void main() {
  final s = lookupS(const Locale('pt'));
  final agora = DateTime(2026, 9, 28, 21, 30);

  group('prontidaoNota', () {
    test('índice de 0 a 100, sem porcentagem', () {
      expect(prontidaoNota(77), '77/100');
      expect(prontidaoNota(0), '0/100');
      expect(prontidaoNota(77), isNot(contains('%')));
    });

    test('ausente fica indisponível, não zero', () {
      expect(prontidaoNota(null), '--');
    });
  });

  group('prontidaoFrescor', () {
    test('snapshot de hoje não mostra nada', () {
      expect(prontidaoFrescor(s, DateTime(2026, 9, 28), agora), isNull);
    });

    test('sem data de referência não mostra nada', () {
      expect(prontidaoFrescor(s, null, agora), isNull);
    });

    test('data no futuro (fuso) conta como hoje', () {
      expect(prontidaoFrescor(s, DateTime(2026, 9, 29), agora), isNull);
    });

    test('ontem', () {
      expect(
        prontidaoFrescor(s, DateTime(2026, 9, 27), agora),
        'Atualizado ontem',
      );
    });

    test('data antiga em dd/MM', () {
      expect(
        prontidaoFrescor(s, DateTime(2026, 9, 5), agora),
        'Atualizado em 05/09',
      );
    });
  });

  group('alunoProntidaoSemantica', () {
    test('nota em escala de 100, nível e dica', () {
      expect(
        alunoProntidaoSemantica(s, _snap(), mostrarDica: true),
        'Prontidão 77 de 100. Pronto para treinar. Boa noite de sono.',
      );
    });

    test('sem a dica quando o foco já falou', () {
      expect(
        alunoProntidaoSemantica(s, _snap(), mostrarDica: false),
        'Prontidão 77 de 100. Pronto para treinar.',
      );
    });

    test('inclui o frescor quando não é de hoje', () {
      expect(
        alunoProntidaoSemantica(
          s,
          _snap(),
          mostrarDica: false,
          frescor: 'Atualizado ontem',
        ),
        'Prontidão 77 de 100. Pronto para treinar. Atualizado ontem.',
      );
    });

    test('sem nota do servidor fala indisponível e não aconselha', () {
      final label = alunoProntidaoSemantica(
        s,
        _snap(score: null),
        mostrarDica: true,
      );
      expect(label, startsWith('Prontidão indisponível.'));
      expect(label, isNot(contains('Boa noite de sono')));
      expect(label, isNot(contains('por cento')));
    });
  });
}

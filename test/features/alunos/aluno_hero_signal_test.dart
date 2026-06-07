import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno_hero_signal.dart';

void main() {
  group('alunoHeroContextLine', () {
    test('drops redundant risk label when metric panel shows it', () {
      expect(
        alunoHeroContextLine(
          const AlunoHeroPrimarySignal(
            label: 'Risco operacional',
            value: 'Alto',
          ),
          'Priorize contato hoje',
        ),
        'Priorize contato hoje',
      );
    });

    test('keeps metric label for non-risk signals', () {
      expect(
        alunoHeroContextLine(
          const AlunoHeroPrimarySignal(
            label: 'Aderência semanal',
            value: '74',
            suffix: '%',
          ),
          'Aderência baixa — reforce hábito',
        ),
        'Aderência semanal · Aderência baixa — reforce hábito',
      );
    });
  });

  group('alunoHeroMetricEyebrow', () {
    test('maps risk metric eyebrow', () {
      expect(
        alunoHeroMetricEyebrow(
          const AlunoHeroPrimarySignal(
            label: 'Risco operacional',
            value: 'Alto',
          ),
        ),
        'Risco',
      );
    });
  });
}

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

  group('alunoHeroIdentitySubtitle', () {
    test('contact priority shows objective only', () {
      expect(
        alunoHeroIdentitySubtitle(
          compactContactPriority: true,
          objectiveDefined: true,
          objective: 'Hipertrofia',
          contextLine: 'Priorize contato hoje',
        ),
        'Hipertrofia',
      );
    });

    test('normal mode keeps objective and context', () {
      expect(
        alunoHeroIdentitySubtitle(
          compactContactPriority: false,
          objectiveDefined: true,
          objective: 'Hipertrofia',
          contextLine: 'Priorize contato hoje',
        ),
        'Hipertrofia · Priorize contato hoje',
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

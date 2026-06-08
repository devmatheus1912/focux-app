import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_ferramentas_logic.dart';

void main() {
  group('Aluno360FerramentasLogic', () {
    test('measurementCrossAxisCount switches at 360px', () {
      expect(Aluno360FerramentasLogic.measurementCrossAxisCount(359), 2);
      expect(Aluno360FerramentasLogic.measurementCrossAxisCount(360), 4);
    });

    test('spacing tokens keep sections visually grouped', () {
      expect(Aluno360FerramentasLogic.sectionHeaderGap, lessThan(12));
      expect(Aluno360FerramentasLogic.sectionDividerGap, lessThan(16));
    });

    test('aderenciaSparklineValues maps weekly checkins', () {
      final values = Aluno360FerramentasLogic.aderenciaSparklineValues(const [
        {'data': '2026-06-01', 'checkins': 1},
        {'data': '2026-06-02', 'checkins': 0},
        {'data': '2026-06-03', 'checkins': 2},
      ]);
      expect(values, [1.0, 0.0, 2.0]);
    });

    test('aderenciaModuleSub prefers percent then checkins', () {
      final aluno = Aluno(
        id: 1,
        nome: 'Ana',
        email: 'a@test.com',
        status: 'ATIVO',
        aderenciaPercent: 42,
      );
      expect(
        Aluno360FerramentasLogic.aderenciaModuleSub(aluno: aluno),
        '42% na semana',
      );

      final semDados = Aluno(
        id: 2,
        nome: 'B',
        email: 'b@test.com',
        status: 'ATIVO',
      );
      expect(
        Aluno360FerramentasLogic.aderenciaModuleSub(
          aluno: semDados,
          aderenciaSemanal: const [
            {'data': '2026-06-01', 'checkins': 2},
          ],
        ),
        '2 check-ins na semana',
      );
    });
  });
}

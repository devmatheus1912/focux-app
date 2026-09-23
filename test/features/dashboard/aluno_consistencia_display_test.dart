import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/aluno_consistencia_display.dart';

void main() {
  test('não inventa meta de 3 dias sem frequência do plano', () {
    expect(alunoWeeklyDayGoal(), isNull);
    expect(alunoWeeklyDayGoal(frequenciaDias: 0), isNull);
    expect(alunoWeeklyDayGoal(frequenciaDias: 4), 4);
    expect(alunoWeeklyDayGoal(frequenciaDias: 9), 7);
  });

  test('caption de consistência é quieto e pluraliza', () {
    expect(alunoConsistenciaCaption(0), 'Nenhum treino esta semana');
    expect(alunoConsistenciaCaption(1), 'Você treinou 1 dia esta semana');
    expect(
      alunoConsistenciaCaption(3),
      'Você treinou 3 dias esta semana',
    );
    expect(
      alunoConsistenciaCaption(2, weeklyGoal: 4),
      'Você treinou 2 dias esta semana · meta 4',
    );
  });
}

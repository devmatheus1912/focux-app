import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/models/exercicios_ui_filter.dart';
import 'package:focux_app/features/exercicios/utils/exercicios_filter_display.dart';

void main() {
  test('exerciciosCountLabel', () {
    expect(exerciciosCountLabel(0), 'Nenhum exercício');
    expect(exerciciosCountLabel(1), '1 exercício');
    expect(exerciciosCountLabel(8), '8 exercícios');
  });

  test('exerciciosFilterSummary', () {
    expect(exerciciosFilterSummary(const ExerciciosUiFilter()), 'Nenhum');
    expect(
      exerciciosFilterSummary(
        const ExerciciosUiFilter(favoritos: true, comVideo: true),
      ),
      'Favoritos +1',
    );
    expect(
      exerciciosFilterSummary(
        const ExerciciosUiFilter(modalidade: Modalidade.cardio),
      ),
      isNot(equals('Nenhum')),
    );
  });

  test('hasFacet ignora só a busca', () {
    const onlyQuery = ExerciciosUiFilter(query: 'supino');
    expect(onlyQuery.hasActive, isTrue);
    expect(onlyQuery.hasFacet, isFalse);
  });
}

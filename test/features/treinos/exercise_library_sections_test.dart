import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/utils/exercise_library_sections.dart';

Exercicio _ex(String name, {int id = 1}) => Exercicio(id: id, nome: name);

void main() {
  test('agrupa exercícios por letra inicial', () {
    final sections = buildExerciseLibrarySections([
      _ex('Ab wheel', id: 1),
      _ex('Agachamento', id: 2),
      _ex('90 90 quadril', id: 3),
    ]);

    expect(sections.length, 2);
    expect(sections.first.letter, '#');
    expect(sections.first.items.single.nomeDisplay, '90 90 quadril');
    expect(sections.last.letter, 'A');
    expect(sections.last.items.map((e) => e.nomeDisplay), ['Ab wheel', 'Agachamento']);
  });
}

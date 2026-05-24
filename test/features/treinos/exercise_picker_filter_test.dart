import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_filter.dart';

void main() {
  group('applyExercisePickerFilter', () {
    final base = Exercicio(
      id: 1,
      nome: 'Supino reto barra',
      equipamentos: const [Equipamento.barra, Equipamento.banco],
      espacosCompativeis: const [
        Espaco.academiaCompleta,
        Espaco.academiaBasica,
      ],
      favoritado: true,
    );

    final casa = Exercicio(
      id: 2,
      nome: 'Flexao de bracos',
      equipamentos: const [Equipamento.pesoCorporal],
      espacosCompativeis: const [Espaco.casaSemEquipo],
    );

    test('filtra por espaco e equipamento', () {
      final filtered = applyExercisePickerFilter(
        [base, casa],
        const ExercisePickerFilter(
          espaco: Espaco.casaSemEquipo,
          equipamento: Equipamento.pesoCorporal,
        ),
      );
      expect(filtered.map((e) => e.id), [2]);
    });

    test('filtra favoritos', () {
      final filtered = applyExercisePickerFilter(
        [base, casa],
        const ExercisePickerFilter(somenteFavoritos: true),
      );
      expect(filtered.map((e) => e.id), [1]);
    });

    test('filtra equipamentos do aluno', () {
      final filtered = applyExercisePickerFilter(
        [base, casa],
        ExercisePickerFilter.fromAlunoEquipamentos(const {Equipamento.pesoCorporal}),
      );
      expect(filtered.map((e) => e.id), [2]);
    });
  });
}

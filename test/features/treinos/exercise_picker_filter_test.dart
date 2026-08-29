import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercise_enum_api.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/utils/exercise_picker_filter.dart';

void main() {
  group('enumSetQueryParam', () {
    test('gera csv ordenado para backend', () {
      expect(
        enumSetQueryParam({Equipamento.halter, Equipamento.barra}),
        'BARRA,HALTER',
      );
    });
  });

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

    test('filtra somente com video', () {
      final comVideo = Exercicio(
        id: 3,
        nome: 'Supino com demo',
        gifUrl: 'https://res.cloudinary.com/demo/video/upload/v1/x.mp4',
      );
      final filtered = applyExercisePickerFilter(
        [base, comVideo],
        const ExercisePickerFilter(somenteComVideo: true),
      );
      expect(filtered.map((e) => e.id), [3]);
    });

    test('serverFiltered pula filtro do aluno', () {
      final filtered = applyExercisePickerFilter(
        [base],
        ExercisePickerFilter.fromAlunoEquipamentos(const {Equipamento.halter}),
        serverFiltered: true,
      );
      expect(filtered.map((e) => e.id), [1]);
    });

    test('serverFiltered pula filtros ja aplicados na API', () {
      final semGif = Exercicio(
        id: 4,
        nome: 'Leg press',
        videoUrl: 'https://cdn.example.com/demo.mp4',
      );
      final filtered = applyExercisePickerFilter(
        [semGif],
        const ExercisePickerFilter(somenteComVideo: true),
        serverFiltered: true,
      );
      expect(filtered.map((e) => e.id), [4]);
    });
  });
}

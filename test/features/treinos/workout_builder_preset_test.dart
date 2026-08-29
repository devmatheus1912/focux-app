import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/data/workout_builder_preset.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('workout builder presets cover common prescription goals', () {
    final ids = workoutBuilderPresets.map((preset) => preset.id).toSet();

    expect(
      ids,
      containsAll(['hypertrophy', 'strength', 'endurance']),
    );
    expect(ids.length, 3);
    expect(
      workoutBuilderPresetById('strength').descansoSegundos,
      greaterThan(90),
    );
    expect(workoutBuilderPresetById('hypertrophy').tipoSerie, 'NORMAL');
  });

  test('workout builder sends premium prescription fields to backend', () {
    final repository =
        File(
          'lib/features/treinos/data/treino_repository.dart',
        ).readAsStringSync();
    final screen = readScreenSourceBundle(
      'lib/features/treinos/screens/add_exercicio_to_treino_screen.dart',
    );

    expect(repository, contains('cargaKg'));
    expect(repository, contains('observacoes'));
    expect(screen, contains('_PresetSelector'));
    expect(screen, contains('Carga (kg)'));
    expect(screen, contains('Observações de execução'));
  });

  test('workout detail exposes persisted reorder and duplicate actions', () {
    final repository =
        File(
          'lib/features/treinos/data/treino_repository.dart',
        ).readAsStringSync();
    final detail = readScreenSourceBundle(
      'lib/features/treinos/screens/treino_detail_screen.dart',
    );

    expect(repository, contains('reordenarExercicios'));
    expect(repository, contains('/exercicios/ordem'));
    expect(repository, contains('duplicarExercicio'));
    expect(repository, contains('/duplicar'));
    expect(detail, contains('SliverReorderableList'));
    expect(detail, contains('ReorderableDelayedDragStartListener'));
    expect(detail, contains('Duplicar item'));
  });

  test('workout detail persists order through drag reorder', () {
    final detail = readScreenSourceBundle(
      'lib/features/treinos/screens/treino_detail_screen.dart',
    );

    expect(detail, contains('_TreinoExerciseReorderList'));
    expect(detail, contains('removeAt'));
    expect(detail, contains('insert'));
    expect(detail, contains('reordenarExercicios(widget.treinoId, ids)'));
  });
}

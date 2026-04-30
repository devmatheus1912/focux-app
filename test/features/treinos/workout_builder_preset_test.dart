import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/data/workout_builder_preset.dart';

void main() {
  test('workout builder presets cover common prescription goals', () {
    final ids = workoutBuilderPresets.map((preset) => preset.id).toSet();

    expect(ids, containsAll(['hypertrophy', 'strength', 'endurance', 'superset', 'dropset']));
    expect(workoutBuilderPresetById('strength').descansoSegundos, greaterThan(90));
    expect(workoutBuilderPresetById('superset').tipoSerie, 'SUPERSET');
    expect(workoutBuilderPresetById('dropset').observacoes, contains('reduzir'));
  });

  test('workout builder sends premium prescription fields to backend', () {
    final repository = File(
      'lib/features/treinos/data/treino_repository.dart',
    ).readAsStringSync();
    final screen = File(
      'lib/features/treinos/screens/add_exercicio_to_treino_screen.dart',
    ).readAsStringSync();

    expect(repository, contains('cargaKg'));
    expect(repository, contains('observacoes'));
    expect(screen, contains('_PresetSelector'));
    expect(screen, contains('Carga alvo'));
    expect(screen, contains('Observacoes de execucao'));
  });

  test('workout detail exposes persisted reorder and duplicate actions', () {
    final repository = File(
      'lib/features/treinos/data/treino_repository.dart',
    ).readAsStringSync();
    final detail = File(
      'lib/features/treinos/screens/treino_detail_screen.dart',
    ).readAsStringSync();

    expect(repository, contains('reordenarExercicios'));
    expect(repository, contains('/exercicios/ordem'));
    expect(repository, contains('duplicarExercicio'));
    expect(repository, contains('/duplicar'));
    expect(detail, contains('Mover para cima'));
    expect(detail, contains('Mover para baixo'));
    expect(detail, contains('Duplicar item'));
  });
}

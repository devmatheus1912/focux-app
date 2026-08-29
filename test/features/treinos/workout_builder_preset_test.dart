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
    expect(workoutBuilderRepShortcuts('hypertrophy'), contains('8-12'));
    expect(
      matchWorkoutBuilderPresetId(
        series: 4,
        repeticoes: '8-12',
        descansoSegundos: 75,
      ),
      'hypertrophy',
    );
    expect(
      matchWorkoutBuilderPresetId(
        series: 5,
        repeticoes: '3-6',
        descansoSegundos: 150,
      ),
      'strength',
    );
  });

  test('workout builder sends premium prescription fields to backend', () {
    final repository =
        File(
          'lib/features/treinos/data/treino_repository.dart',
        ).readAsStringSync();
    final screen = readScreenSourceBundle(
      'lib/features/treinos/screens/add_exercicio_to_treino_screen.dart',
    );
    final prescription =
        File(
          'lib/features/treinos/widgets/prescription_editor_sheet.dart',
        ).readAsStringSync();

    expect(repository, contains('cargaKg'));
    expect(repository, contains('observacoes'));
    expect(prescription, contains('PrescriptionEditorSheet'));
    expect(prescription, contains('Carga (kg)'));
    expect(prescription, contains('Adicionar observações'));
    expect(screen, contains('showPrescriptionEditorSheet'));
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
    expect(detail, contains("label: 'Duplicar'"));
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

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/data/workout_builder_preset.dart';

void main() {
  group('displayExerciseName', () {
    test('corrige acentos comuns da biblioteca', () {
      expect(
        displayExerciseName('Abducao maquina'),
        'Abdução máquina',
      );
      expect(
        displayExerciseName('Abducao banda lateral'),
        'Abdução banda lateral',
      );
      expect(displayExerciseName('Elevacao pelvica'), 'Elevação pelvica');
    });

    test('aplica regras de sufixo cao/sao/icio', () {
      expect(displayExerciseName('Extensao lumbar'), 'Extensão lumbar');
      expect(displayExerciseName('Flexao de cotovelo'), 'Flexão de cotovelo');
    });
  });

  group('Exercicio.nomeDisplay', () {
    test('expõe nome formatado no model', () {
      final exercicio = Exercicio(id: 1, nome: 'Abducao maquina');
      expect(exercicio.nomeDisplay, 'Abdução máquina');
    });
  });

  group('workoutBuilderPresets', () {
    test('labels e observações em PT-BR correto', () {
      final strength = workoutBuilderPresetById('strength');
      final endurance = workoutBuilderPresetById('endurance');

      expect(strength.label, 'Força');
      expect(endurance.label, 'Resistência');
      expect(strength.observacoes, contains('técnica'));
    });

    test('preset hipertrofia é o default esperado', () {
      final preset = workoutBuilderPresetById('hypertrophy');
      expect(preset.series, 4);
      expect(preset.repeticoes, '8-12');
      expect(preset.descansoSegundos, 75);
    });

    test('apenas presets de volume (sem superset/drop duplicados)', () {
      expect(workoutBuilderPresets.length, 3);
      expect(workoutBuilderPresets.map((p) => p.id), [
        'hypertrophy',
        'strength',
        'endurance',
      ]);
    });
  });
}

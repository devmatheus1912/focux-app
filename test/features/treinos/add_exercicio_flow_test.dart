import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/screens/widgets/exercise_media_thumb.dart';
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

  group('Exercicio media trust', () {
    test('biblioteca curada com mídia não exibe badge no treino', () {
      final exercicio = Exercicio(
        id: 1,
        nome: 'Supino reto barra',
        curado: true,
        curatedId: 42,
        videoSource: 'FOCUX_LIBRARY',
        gifUrl: 'https://cdn.example/gif.gif',
        licenseStatus: 'PENDING',
        editorialStatus: 'PENDING_REVIEW',
      );
      expect(exercicio.hasPlayableMedia, isTrue);
      expect(exercicio.showMediaBadgeInWorkoutList, isFalse);
      expect(exercicio.mediaTrustLevel, 'READY');
    });

    test('exercício sem mídia exibe alerta no treino', () {
      final exercicio = Exercicio(id: 2, nome: 'Custom');
      expect(exercicio.showMediaBadgeInWorkoutList, isTrue);
      expect(exercicio.mediaTrustLabel, 'Sem demonstração');
    });

    test('preview usa poster Cloudinary em vez de MP4', () {
      const video =
          'https://res.cloudinary.com/demo/video/upload/v123/sample.mp4';
      final preview = exercisePreviewMediaUrl(videoUrl: video);
      expect(preview, contains('f_jpg'));
      expect(preview, isNot(contains('.mp4')));
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

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/pt_br_display.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/screens/widgets/exercise_media_thumb.dart';
import 'package:focux_app/features/treinos/data/workout_builder_preset.dart';

void main() {
  group('displayWorkoutName', () {
    test('corrige Forca para Força', () {
      expect(displayWorkoutName('Treino Forca'), 'Treino Força');
    });
  });

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

    test('preview com transformação Cloudinary existente', () {
      const video =
          'https://res.cloudinary.com/demo/video/upload/f_mp4,vc_h264/v123/sample.mp4';
      final preview = exercisePreviewMediaUrl(gifUrl: video);
      expect(preview, contains('f_jpg'));
      expect(preview, isNot(contains('.mp4')));
    });

    test('exercicioMissingPreviewPoster detecta mídia sem poster', () {
      final ok = Exercicio(
        id: 1,
        nome: 'Supino',
        gifUrl:
            'https://res.cloudinary.com/demo/video/upload/v123/sample.mp4',
      );
      expect(exercicioMissingPreviewPoster(ok), isFalse);

      final template = Exercicio(
        id: 3,
        nome: 'Agachamento',
        curatedId: 10,
        gifUrl:
            'https://res.cloudinary.com/focux/image/upload/focux/exercicios/curated/gifs/10.gif',
        thumbnailUrl:
            'https://res.cloudinary.com/focux/image/upload/focux/exercicios/curated/thumbs/10.webp',
      );
      expect(exercicioMissingPreviewPoster(template), isTrue);

      final missing = Exercicio(
        id: 2,
        nome: 'Custom',
        videoUrl: 'https://cdn.example/video.mp4',
      );
      expect(exercicioMissingPreviewPoster(missing), isTrue);
    });

    test('preview usa GIF Cloudinary da biblioteca', () {
      const gif =
          'https://res.cloudinary.com/demo/image/upload/v123/demo.gif';
      final preview = exercisePreviewMediaUrl(gifUrl: gif);
      expect(preview, contains('w_160'));
      expect(preview, contains('.jpg'));
    });

    test('exercicioHasPersonalVideo só com upload do personal', () {
      final library = Exercicio(
        id: 1,
        nome: 'Supino',
        gifUrl: 'https://res.cloudinary.com/demo/image/upload/v1/a.gif',
        videoSource: 'FOCUX_LIBRARY',
      );
      expect(exercicioHasPersonalVideo(library), isFalse);

      final personal = Exercicio(
        id: 2,
        nome: 'Custom',
        videoUrl:
            'https://res.cloudinary.com/demo/video/upload/v123/sample.mp4',
        videoSource: 'PERSONAL_UPLOAD',
        licenseStatus: 'PERSONAL_OWNED',
      );
      expect(exercicioHasPersonalVideo(personal), isTrue);
    });

    test('preview personal prioriza thumbnailUrl do backend', () {
      final personal = Exercicio(
        id: 3,
        nome: 'Ab wheel',
        videoUrl:
            'https://res.cloudinary.com/demo/video/upload/v456/ab.mp4',
        thumbnailUrl:
            'https://res.cloudinary.com/demo/image/upload/v456/poster.jpg',
        videoSource: 'PERSONAL_UPLOAD',
      );
      final preview = exercisePreviewMediaUrlFor(personal);
      expect(preview, contains('poster.jpg'));
      expect(preview, contains('_v=456'));
    });

    test('canPreviewExerciseMedia esconde curado sem mídia (§38)', () {
      final curado = Exercicio(
        id: 4,
        nome: 'Agachamento',
        curado: true,
        curatedId: 10,
      );
      expect(canPreviewExerciseMedia(curado), isFalse);
    });

    test('canPreviewExerciseMedia permite vídeo do personal em standby', () {
      final personal = Exercicio(
        id: 5,
        nome: 'Agachamento',
        videoUrl: 'https://cdn.focux.app/a.mp4',
        videoSource: 'PERSONAL_UPLOAD',
        licenseStatus: 'PERSONAL_OWNED',
      );
      expect(canPreviewExerciseMedia(personal), isTrue);
    });

    test('canPreviewExerciseMedia permite MoveKit publicado', () {
      final movekit = Exercicio(
        id: 6,
        nome: 'Arnold press',
        videoUrl:
            'https://res.cloudinary.com/doai3xaaz/video/upload/f_mp4,vc_h264/v1789083982/focux/exercicios/movekit/videos/arnold-press.mp4',
        thumbnailUrl:
            'https://res.cloudinary.com/doai3xaaz/image/upload/v1789083983/focux/exercicios/movekit/thumbs/arnold-press.webp',
        videoSource: 'MOVEKIT',
        licenseStatus: 'LICENSED',
        curado: true,
        curatedId: 42,
      );
      expect(exercicioHasPublishedLibraryMedia(movekit), isTrue);
      expect(canPreviewExerciseMedia(movekit), isTrue);
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

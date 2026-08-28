import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('personal uploaded approved video is ready for students', () {
    final exercicio = Exercicio(
      id: 1,
      nome: 'Agachamento',
      videoUrl: 'https://cdn.focux.app/agachamento.mp4',
      videoSource: 'PERSONAL_UPLOAD',
      licenseStatus: 'PERSONAL_OWNED',
      editorialStatus: 'APPROVED',
    );

    expect(exercicio.isReadyForStudent, isTrue);
    expect(exercicio.mediaTrustLevel, 'READY');
    expect(exercicio.mediaTrustLabel, 'Vídeo do personal');
  });

  test('licensed approved library video is ready for students', () {
    final exercicio = Exercicio(
      id: 2,
      nome: 'Supino',
      videoUrl: 'https://cdn.focux.app/supino.mp4',
      videoSource: 'FOCUX_LIBRARY',
      licenseStatus: 'LICENSED',
      editorialStatus: 'APPROVED',
    );

    expect(exercicio.isReadyForStudent, isTrue);
    expect(exercicio.mediaTrustLabel, 'Demonstração Focux');
  });

  test('exercise without video asks for media before premium prescription', () {
    final exercicio = Exercicio(
      id: 3,
      nome: 'Prancha',
      editorialStatus: 'APPROVED',
      licenseStatus: 'LICENSED',
    );

    expect(exercicio.isReadyForStudent, isFalse);
    expect(exercicio.mediaTrustLevel, 'NO_VIDEO');
    expect(exercicio.mediaTrustDescription, contains('Adicione vídeo'));
  });

  test('workout builder and detail expose prescription trust UI', () {
    final builder = readScreenSourceBundle(
      'lib/features/treinos/screens/add_exercicio_to_treino_screen.dart',
    );
    final detail = readScreenSourceBundle(
      'lib/features/exercicios/screens/exercicio_detail_screen.dart',
    );
    final treinoDetail = readScreenSourceBundle(
      'lib/features/treinos/screens/treino_detail_screen.dart',
    );

    expect(builder, contains('_BrowseLibraryCta'));
    expect(builder, contains('onUploadVideo'));
    expect(builder, contains('canPreviewExerciseMedia'));
    expect(detail, contains('_PrescriptionReadinessPanel'));
    expect(detail, contains('mediaTrustLabel'));
    expect(treinoDetail, contains('TreinoPrescriptionVideoBlock'));
  });

  test('exercise media import surface exposes editorial approval controls', () {
    final list =
        File(
          'lib/features/exercicios/screens/exercicios_list_screen.dart',
        ).readAsStringSync();

    expect(list, contains('Aprovar editorialmente'));
    expect(list, contains('Notas editoriais padrao'));
    expect(list, contains('previewMidias(midias)'));
    expect(list, contains('importarMidias(midias)'));
  });

  test('prévia de vídeo cabe na sheet da Home', () {
    final preview =
        File(
          'lib/features/exercicios/screens/widgets/exercise_video_preview_sheet.dart',
        ).readAsStringSync();
    expect(preview, contains('expand: true'));
    expect(preview, contains('FittedBox'));
    expect(preview, contains('BoxFit.contain'));
    expect(preview, contains('height * 0.82'));
    expect(preview, contains('VideoPlayer(_controller!)'));
  });
}

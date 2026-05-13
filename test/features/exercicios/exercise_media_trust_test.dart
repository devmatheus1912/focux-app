import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';

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
    expect(exercicio.mediaTrustLabel, 'video do personal');
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
    expect(exercicio.mediaTrustLabel, 'licenciado');
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
    expect(exercicio.mediaTrustDescription, contains('Adicione video'));
  });

  test('workout builder and detail expose prescription trust UI', () {
    final builder =
        File(
          'lib/features/treinos/screens/add_exercicio_to_treino_screen.dart',
        ).readAsStringSync();
    final detail =
        File(
          'lib/features/exercicios/screens/exercicio_detail_screen.dart',
        ).readAsStringSync();
    final treinoDetail =
        File(
          'lib/features/treinos/screens/treino_detail_screen.dart',
        ).readAsStringSync();

    expect(builder, contains('_ExercisePickerCard'));
    expect(builder, contains('_ExerciseMediaStatus'));
    expect(builder, contains('mediaTrustLevel'));
    expect(builder, contains('onUploadVideo'));
    expect(detail, contains('_PrescriptionReadinessPanel'));
    expect(treinoDetail, contains('mediaTrustLabel'));
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
}

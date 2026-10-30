import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_video_badge.dart';

void main() {
  group('CheckinVideoBadge', () {
    test('na execução, só o upload do personal ganha selo', () {
      // "Vídeo licenciado" saiu da execução do aluno (cobria a demonstração).
      expect(CheckinVideoBadge.label(licenseStatus: 'LICENSED'), isNull);
      expect(CheckinVideoBadge.icon(licenseStatus: 'LICENSED'), isNull);

      expect(
        CheckinVideoBadge.label(videoSource: 'PERSONAL_UPLOAD'),
        'Enviado pelo personal',
      );
      expect(
        CheckinVideoBadge.icon(videoSource: 'PERSONAL_UPLOAD'),
        Icons.person_rounded,
      );

      expect(CheckinVideoBadge.label(videoSource: 'FOCUX_LIBRARY'), isNull);
      expect(CheckinVideoBadge.icon(videoSource: 'FOCUX_LIBRARY'), isNull);
      expect(CheckinVideoBadge.label(), isNull);
      expect(CheckinVideoBadge.icon(), isNull);
    });

    test('vídeo licenciado enviado pelo personal mostra o do personal', () {
      expect(
        CheckinVideoBadge.label(licenseStatus: 'LICENSED', videoSource: 'PERSONAL_UPLOAD'),
        'Enviado pelo personal',
      );
    });
  });
}

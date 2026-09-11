import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/utils/checkin_video_badge.dart';

void main() {
  group('CheckinVideoBadge', () {
    test('só exibe licenciado e upload do personal', () {
      expect(
        CheckinVideoBadge.label(licenseStatus: 'LICENSED'),
        'Vídeo licenciado',
      );
      expect(
        CheckinVideoBadge.icon(licenseStatus: 'LICENSED'),
        Icons.verified_rounded,
      );

      expect(
        CheckinVideoBadge.label(videoSource: 'PERSONAL_UPLOAD'),
        'Enviado pelo personal',
      );
      expect(
        CheckinVideoBadge.icon(videoSource: 'PERSONAL_UPLOAD'),
        Icons.person_rounded,
      );

      expect(
        CheckinVideoBadge.label(videoSource: 'FOCUX_LIBRARY'),
        isNull,
      );
      expect(CheckinVideoBadge.icon(videoSource: 'FOCUX_LIBRARY'), isNull);
      expect(CheckinVideoBadge.label(), isNull);
      expect(CheckinVideoBadge.icon(), isNull);
    });

    test('LICENSED tem prioridade sobre videoSource', () {
      expect(
        CheckinVideoBadge.label(
          licenseStatus: 'LICENSED',
          videoSource: 'PERSONAL_UPLOAD',
        ),
        'Vídeo licenciado',
      );
      expect(
        CheckinVideoBadge.icon(
          licenseStatus: 'LICENSED',
          videoSource: 'PERSONAL_UPLOAD',
        ),
        Icons.verified_rounded,
      );
    });
  });
}

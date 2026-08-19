import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/screens/widgets/exercise_video_spec_tips.dart';
import 'package:focux_app/features/exercicios/utils/exercise_video_upload_spec.dart';

void main() {
  group('ExerciseVideoUploadSpec.rejectionFor', () {
    test('aceita mp4 dentro do limite', () {
      expect(
        ExerciseVideoUploadSpec.rejectionFor(
          filename: 'supino.mp4',
          bytes: 12 * 1024 * 1024,
        ),
        isNull,
      );
    });

    test('recusa arquivo vazio', () {
      expect(
        ExerciseVideoUploadSpec.rejectionFor(filename: 'a.mp4', bytes: 0),
        contains('vazio'),
      );
    });

    test('recusa acima de 120 MB', () {
      expect(
        ExerciseVideoUploadSpec.rejectionFor(
          filename: 'longo.mp4',
          bytes: ExerciseVideoUploadSpec.maxBytes + 1,
        ),
        contains('120 MB'),
      );
    });

    test('recusa extensão fora do contrato', () {
      expect(
        ExerciseVideoUploadSpec.rejectionFor(filename: 'demo.avi', bytes: 1024),
        contains('MP4 ou MOV'),
      );
    });
  });

  test('tips cobrem resolução, duração e formato', () {
    final blob = ExerciseVideoUploadSpec.tips
        .map((tip) => '${tip.title} ${tip.body}')
        .join(' ');
    expect(blob, contains('1080 × 1920'));
    expect(blob, contains('720 × 1280'));
    expect(blob, contains('9:16'));
    expect(blob, contains('120 MB'));
    expect(blob, contains('45 segundos'));
  });

  testWidgets('Como filmar abre a sheet no ? da Home', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ExerciseVideoSpecTips(isDark: false)),
      ),
    );

    expect(find.text('Como filmar'), findsOneWidget);
    expect(find.textContaining('1080 × 1920'), findsOneWidget);
    expect(find.text('Celular em pé (9:16)'), findsNothing);

    await tester.tap(find.byTooltip('Como filmar'));
    await tester.pumpAndSettle();

    expect(find.text('Celular em pé (9:16)'), findsOneWidget);
    expect(find.textContaining('Full HD vertical'), findsOneWidget);
    expect(find.text('Entendi'), findsNothing);
  });
}

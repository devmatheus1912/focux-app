import 'package:flutter_test/flutter_test.dart';
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

  group('duração e estado do envio (20/11)', () {
    test('galeria: até 60 s passa, acima recusa dizendo a duração', () {
      expect(
        ExerciseVideoUploadSpec.rejectionForDuration(
          const Duration(seconds: 60),
        ),
        isNull,
      );
      expect(ExerciseVideoUploadSpec.rejectionForDuration(null), isNull);
      expect(
        ExerciseVideoUploadSpec.rejectionForDuration(
          const Duration(minutes: 2, seconds: 30),
        ),
        allOf(contains('2:30'), contains('45 segundos')),
      );
    });

    test('resumo do vídeo escolhido: duração e tamanho', () {
      expect(exerciseVideoDuracao(const Duration(seconds: 38)), '0:38');
      expect(exerciseVideoDuracao(const Duration(seconds: 125)), '2:05');
      expect(exerciseVideoTamanho(42 * 1024 * 1024), '42 MB');
      expect(exerciseVideoTamanho(1000), '1 MB');
      expect(
        exerciseVideoResumo(
          duracao: const Duration(seconds: 38),
          bytes: 42 * 1024 * 1024,
        ),
        '0:38 · 42 MB',
      );
      expect(exerciseVideoResumo(bytes: 5 * 1024 * 1024), '5 MB');
    });

    test('rótulo do envio: progresso real, depois processando', () {
      expect(exerciseVideoEnvioRotulo(0), 'Enviando vídeo 0%');
      expect(exerciseVideoEnvioRotulo(0.427), 'Enviando vídeo 42%');
      expect(exerciseVideoEnvioRotulo(1), 'Processando vídeo…');
      expect(exerciseVideoEnvioRotulo(null), 'Processando vídeo…');
    });

    test('linha do cadastro: vazio, preparando e escolhido', () {
      expect(
        exerciseVideoLinhaTitulo(preparando: false, escolhido: false),
        'Adicionar meu vídeo',
      );
      expect(
        exerciseVideoLinhaTitulo(preparando: true, escolhido: false),
        'Preparando vídeo…',
      );
      expect(
        exerciseVideoLinhaApoio(preparando: false, resumo: '0:38 · 42 MB'),
        '0:38 · 42 MB · Toque para trocar',
      );
    });
  });
}

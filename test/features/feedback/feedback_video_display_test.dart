import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/feedback/utils/feedback_video_display.dart';

void main() {
  test('feedbackVideoLabel não expõe id', () {
    expect(feedbackVideoLabel('Joelhada alta'), 'Joelhada alta');
    expect(feedbackVideoLabel('  '), 'Feedback');
    expect(feedbackVideoLabel(null), 'Feedback');
  });

  test('status mostra se o personal já respondeu, sem nota de IA', () {
    final dia = DateTime(2026, 9, 30);
    expect(
      feedbackVideoSubtitle(criadoEm: dia, respondido: false),
      endsWith('Aguardando sua resposta'),
    );
    expect(
      feedbackVideoSubtitle(criadoEm: dia, respondido: true),
      endsWith('Respondido'),
    );
    expect(feedbackVideoStatusLabel(respondido: false), 'Novo');
    expect(feedbackVideoResponderLabel(respondido: true), 'Editar resposta');
    expect(feedbackVideoHelpTip, isNot(contains('IA')));
  });

  test('título usa o exercício e cai no comentário', () {
    expect(feedbackVideoTitulo(exercicioNome: 'Supino', comentario: 'x'), 'Supino');
    expect(feedbackVideoTitulo(exercicioNome: ' ', comentario: 'Ombro'), 'Ombro');
    expect(feedbackVideoTitulo(), 'Feedback');
  });

  test('lado do aluno fala de correção, não de responder', () {
    final dia = DateTime(2026, 9, 30);
    expect(
      feedbackVideoAlunoSubtitle(criadoEm: dia, respondido: false),
      endsWith('Aguardando o personal'),
    );
    expect(
      feedbackVideoAlunoSubtitle(criadoEm: dia, respondido: true),
      endsWith('Correção pronta'),
    );
    expect(feedbackVideoAlunoStatusLabel(respondido: false), 'Enviado');
    expect(feedbackVideoAlunoHelpTip, isNot(contains('IA')));
  });

  test('nome do upload só com extensão aceita pela pasta', () {
    expect(feedbackVideoUploadFilename('/tmp/IMG_1.MOV'), endsWith('.mov'));
    expect(feedbackVideoUploadFilename(r'C:\v\clip.webm'), endsWith('.webm'));
    expect(feedbackVideoUploadFilename('video.3gp'), endsWith('.mp4'));
    expect(feedbackVideoUploadFilename(null), startsWith('feedback_'));
  });

  test('tamanho do vídeo', () {
    expect(feedbackVideoTamanhoErro(0), isNotNull);
    expect(feedbackVideoTamanhoErro(5 * 1024 * 1024), isNull);
    expect(feedbackVideoTamanhoErro(feedbackVideoMaxBytes + 1), contains('120 MB'));
  });

  test('feedbackVideoCountLabel e query', () {
    expect(feedbackVideoCountLabel(1), '1 feedback');
    expect(feedbackVideoCountLabel(2), '2 feedbacks');
    expect(
      feedbackVideoMatchesQuery(comentario: 'Joelhada alta', query: 'joel'),
      isTrue,
    );
    expect(
      feedbackVideoMatchesQuery(comentario: 'Joelhada', query: 'ombro'),
      isFalse,
    );
  });
}

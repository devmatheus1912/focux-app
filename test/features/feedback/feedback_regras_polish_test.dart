import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/feedback/data/feedback_video_repository.dart';
import 'package:focux_app/features/feedback/utils/feedback_video_display.dart';

FeedbackVideo _f(
  int id, {
  String recado = '',
  bool respondido = false,
  required DateTime em,
}) => FeedbackVideo(
  id: id,
  alunoId: 1,
  exercicioId: 1,
  videoUrl: 'https://v.test/$id',
  comentario: recado,
  criadoEm: em,
  status: respondido ? 'RESPONDIDO' : 'ENVIADO',
);

void main() {
  test('dor: "senti" só com parte do corpo', () {
    expect(feedbackRecadoFalaDeDor('senti joelho'), isTrue);
    expect(feedbackRecadoFalaDeDor('senti evolução'), isFalse);
    expect(feedbackRecadoFalaDeDor('doeu a lombar'), isTrue);
    expect(feedbackRecadoFalaDeDor('foi tranquilo'), isFalse);
  });

  test('linha: dor, prévia do recado ou o estado', () {
    final d = DateTime(2026, 11, 10);
    expect(feedbackVideoSubtituloDaLinha(_f(1, recado: 'senti joelho', em: d)),
        startsWith('Fala de dor ·'));
    expect(feedbackVideoSubtituloDaLinha(_f(2, recado: 'cansei', em: d)),
        startsWith('“cansei” ·'));
    expect(feedbackVideoSubtituloDaLinha(_f(3, em: d)),
        endsWith('O aluno espera sua correção'));
  });

  test('ordem: dor, para responder, respondidos; mais novo primeiro', () {
    final ordem = feedbackVideosOrdenados([
      _f(1, respondido: true, em: DateTime(2026, 11, 11)),
      _f(2, em: DateTime(2026, 11, 9)),
      _f(3, recado: 'dor no ombro', em: DateTime(2026, 11, 8)),
      _f(4, em: DateTime(2026, 11, 10)),
    ]);
    expect(ordem.map((f) => f.id), [3, 4, 2, 1]);
  });

  test('correção só com áudio conta como respondida', () {
    final f = FeedbackVideo(
      id: 9,
      alunoId: 1,
      exercicioId: 1,
      videoUrl: 'https://v.test/9',
      comentario: '',
      criadoEm: DateTime(2026, 11, 11),
      respostaAudioUrl: 'https://a.test/9.m4a',
    );
    expect(f.respondido, isTrue);
    expect(feedbackAudioDuracao(42), '0:42');
    expect(feedbackVideoEnviando(0.45), 'Enviando… 45%');
  });
}

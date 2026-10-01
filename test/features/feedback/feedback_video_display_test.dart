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

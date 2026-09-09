import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/feedback/utils/feedback_video_display.dart';

void main() {
  test('feedbackVideoLabel não expõe id', () {
    expect(feedbackVideoLabel('Joelhada alta'), 'Joelhada alta');
    expect(feedbackVideoLabel('  '), 'Feedback');
    expect(feedbackVideoLabel(null), 'Feedback');
  });

  test('feedbackVideo score e ícone', () {
    expect(feedbackVideoValue(null), 'Vídeo');
    expect(feedbackVideoValue(80), '80');
    expect(feedbackVideoFxIcon(null), 'spark');
    expect(feedbackVideoFxIcon(80), 'circle-check');
    expect(feedbackVideoFxIcon(50), 'trend');
    expect(feedbackVideoFxIcon(10), 'alert-triangle');
    expect(feedbackVideoDanger(39), isTrue);
    expect(feedbackVideoDanger(40), isFalse);
    expect(feedbackVideoDanger(null), isFalse);
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

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/widgets/conversation_media_widgets.dart';

void main() {
  test('lê a duração gravada do conteúdo do áudio', () {
    expect(parseChatAudioDuration('Áudio 00:02'), const Duration(seconds: 2));
    expect(
      parseChatAudioDuration('Audio 01:15'),
      const Duration(minutes: 1, seconds: 15),
    );
    expect(parseChatAudioDuration('Áudio'), isNull);
    expect(parseChatAudioDuration(''), isNull);
  });
}

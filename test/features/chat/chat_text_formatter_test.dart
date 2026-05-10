import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/data/chat_text_formatter.dart';

void main() {
  test('collapses legacy duplicated message body halves', () {
    expect(
      formatChatTextForDisplay('Boa tarde Matheus\nBoa tarde Matheus'),
      'Boa tarde Matheus',
    );
    expect(
      formatChatTextForDisplay(
        'Serie pesada\nDor no ombro\nSerie pesada\nDor no ombro',
      ),
      'Serie pesada\nDor no ombro',
    );
  });

  test('keeps intentional non duplicated multiline text', () {
    expect(
      formatChatTextForDisplay('Treino ok\nSenti dor no joelho'),
      'Treino ok\nSenti dor no joelho',
    );
  });

  test('removes lightweight markdown from copilot drafts', () {
    expect(
      formatChatTextForDisplay(
        'Oi, Beatriz. **Contate Beatriz imediatamente**. `ok`',
      ),
      'Oi, Beatriz. Contate Beatriz imediatamente. ok',
    );
  });
}

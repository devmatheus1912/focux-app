import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/ia_chat_display.dart';

void main() {
  test('iaChatComoCalculamos deixa claro que não aplica treino', () {
    expect(iaChatComoCalculamos, contains('Não aplica treino'));
  });
}

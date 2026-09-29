import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/utils/chat_outgoing_dedupe.dart';

void main() {
  test('mesmo texto com caixa e espaços diferentes é duplicado', () {
    expect(
      isRecentDuplicateOutgoing('Bora  TREINAR hoje?', ['bora treinar hoje?']),
      isTrue,
    );
  });

  test('texto diferente ou vazio não é duplicado', () {
    expect(isRecentDuplicateOutgoing('Bom dia', ['Boa noite']), isFalse);
    expect(isRecentDuplicateOutgoing('   ', ['   ']), isFalse);
  });

  test('ação do Copiloto reescrita conta como a mesma mensagem', () {
    expect(
      isRecentDuplicateOutgoing(
        'Oi, vamos ajustar treino pernas amanhã cedo academia central',
        ['vamos ajustar treino pernas amanhã cedo academia central ok'],
      ),
      isTrue,
    );
  });
}

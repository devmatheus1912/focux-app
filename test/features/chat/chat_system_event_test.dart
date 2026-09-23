import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/chat/utils/chat_system_event.dart';

void main() {
  test('compacta treino registrado e some com o CTA de responder', () {
    const raw =
        'Treino registrado: Costa e Braceta. 1/28 series. '
        'Responda no chat se quiser ajustar a próxima sessão.';
    final view = formatChatSystemEvent(raw);
    expect(view.title, 'Treino registrado');
    expect(view.detail, 'Costa e Braceta · 1 de 28 séries');
    expect(view.threadLabel, 'Treino registrado · Costa e Braceta · 1 de 28 séries');
    expect(view.detail, isNot(contains('Responda')));
    expect(view.threadLabel, isNot(contains('series')));
  });

  test('aceita séries com acento e não inventa detalhe vazio', () {
    final view = formatChatSystemEvent(
      'Treino registrado: Full body. 5/28 séries. Responda no chat.',
    );
    expect(view.title, 'Treino registrado');
    expect(view.detail, 'Full body · 5 de 28 séries');
  });

  test('texto de sistema sem padrão vira primeira frase', () {
    final view = formatChatSystemEvent(
      'Carga ajustada no supino. Próxima sessão com 2.5 kg a mais.',
    );
    expect(view.title, 'Carga ajustada no supino');
    expect(view.detail, 'Próxima sessão com 2.5 kg a mais');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/health/utils/health_dashboard_display.dart';

void main() {
  test('copy de saúde explica prontidão e desconectar', () {
    expect(saudeComoCalculamos, contains('sono'));
    expect(saudeComoCalculamos, contains('passos'));
    expect(saudeAtualizarLabel(), 'Atualizar agora');
    expect(saudeDesconectarLabel(), 'Desconectar saúde');
    expect(saudeDesconectarConfirmTitle(), contains('Desconectar'));
    expect(saudeDesconectarConfirmMessage(), contains('Apple Health'));
  });
}

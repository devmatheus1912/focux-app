import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/register_display.dart';

void main() {
  test('copy do cadastro confirma código e criação', () {
    expect(registerCriarLabel(), 'Criar minha conta');
    expect(registerCriarConfirmMessage(), contains('plano'));
    expect(registerEnviarCodigoLabel(), contains('Enviar'));
    expect(registerEnviarConfirmMessage(), contains('6 dígitos'));
    expect(registerJaTenhoContaLabel(), 'Já tenho conta');
  });
}

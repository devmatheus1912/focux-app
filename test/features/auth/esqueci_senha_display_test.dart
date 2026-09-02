import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/esqueci_senha_display.dart';

void main() {
  test('copy e rotas da recuperação preservam papel e slug', () {
    expect(esqueciEnviarLabel(), 'Enviar código');
    expect(esqueciConfirmMessage(), contains('6 dígitos'));
    expect(
      esqueciLoginPath(isAluno: false),
      '/login?role=personal',
    );
    expect(
      esqueciLoginPath(isAluno: true, personalSlug: 'studio'),
      '/login?role=aluno&p=studio',
    );
    expect(
      esqueciVerificarCodigoPath(
        email: 'a@b.com',
        isAluno: false,
      ),
      contains('role=personal'),
    );
    expect(
      esqueciEnvironmentWarning(hasIssue: false),
      contains('SMTP'),
    );
  });
}

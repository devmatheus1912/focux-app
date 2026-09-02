import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/login_display.dart';

void main() {
  test('rotas de login levam papel e slug', () {
    expect(loginRoleQuery(isAluno: false), 'personal');
    expect(loginRoleQuery(isAluno: true), 'aluno');
    expect(
      loginEsqueciPath(isAluno: true, personalSlug: 'studio x'),
      '/esqueci-senha?role=aluno&p=studio%20x',
    );
    expect(
      loginEsqueciPath(isAluno: false, personalSlug: null),
      '/esqueci-senha?role=personal',
    );
    expect(loginRegisterPath(isAluno: false), '/register');
    expect(loginRegisterPath(isAluno: true), '/register/aluno');
    expect(loginEntrarLabel(), 'Entrar');
    expect(loginHelpAlunoBody(), contains('?p=slug'));
  });
}

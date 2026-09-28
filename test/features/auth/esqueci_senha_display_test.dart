import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/esqueci_senha_display.dart';

void main() {
  test('copy e rotas da recuperação preservam papel e slug', () {
    expect(esqueciEnviarLabel(), 'Enviar código');
    expect(esqueciConfirmMessage(), contains('6 dígitos'));
    expect(esqueciLoginPath(isAluno: false), '/login?role=personal');
    expect(
      esqueciLoginPath(isAluno: true, personalSlug: 'studio'),
      '/login?role=aluno&p=studio',
    );
    expect(
      esqueciVerificarCodigoPath(email: 'a@b.com', isAluno: false),
      contains('role=personal'),
    );
    expect(esqueciEnvironmentWarning(hasIssue: false), contains('SMTP'));
  });

  test('aluno pede senha ao personal e não vê código por e-mail', () {
    expect(esqueciMostraCodigo(isAluno: false), isTrue);
    expect(esqueciMostraCodigo(isAluno: true), isFalse);
    expect(
      esqueciAlunoPedePersonalBody(),
      'Peça uma senha nova ao seu personal.',
    );
    expect(esqueciPageSubtitle(isAluno: false), contains('6 dígitos'));
    expect(esqueciPageSubtitle(isAluno: true), esqueciAlunoPedePersonalBody());
    expect(esqueciHelpSubtitle(isAluno: false), contains('10 minutos'));
    expect(esqueciHelpSubtitle(isAluno: true), contains('senha provisória'));
    expect(esqueciHelpSubtitle(isAluno: true), isNot(contains('mesmo fluxo')));
    expect(esqueciAlunoOtpRedirect(isAluno: false), isNull);
    expect(
      esqueciAlunoOtpRedirect(isAluno: true, personalSlug: 'studio'),
      '/esqueci-senha?role=aluno&p=studio',
    );
  });
}

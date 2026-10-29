import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/app_router_redirect.dart';

/// Quem abre o app pelo link do personal não passa pelo onboarding.
void main() {
  test('links de convite e ativação são públicos (sem login nem onboarding)', () {
    expect(isPublicLocation('/convite/abc123'), isTrue);
    expect(isPublicLocation('/aluno/ativar/xyz'), isTrue);
    expect(isAtivacaoAlunoLocation('/aluno/ativar/xyz'), isTrue);
  });

  test('com sessão, o onboarding é sempre pulado', () {
    expect(shouldLeavePreLoginGate('/onboarding', const {}), isTrue);
    expect(shouldLeavePreLoginGate('/convite/abc123', const {}), isFalse);
  });
}

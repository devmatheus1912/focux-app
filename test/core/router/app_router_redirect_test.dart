import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/app_router_redirect.dart';

void main() {
  test('public routes include auth recovery paths', () {
    expect(isPublicLocation('/login'), isTrue);
    expect(isPublicLocation('/esqueci-senha'), isTrue);
    expect(isPublicLocation('/resetar-senha'), isTrue);
    expect(isPublicLocation('/resetar-senha/verificar-codigo'), isTrue);
    expect(isPublicLocation('/dashboard/personal'), isFalse);
  });

  test('personal-only routes block aluno shell paths', () {
    expect(isPersonalOnlyLocation('/white-label'), isTrue);
    expect(isPersonalOnlyLocation('/alunos/42'), isTrue);
    expect(isAlunoOnlyLocation('/checkin/treinos'), isTrue);
    expect(isAlunoOnlyLocation('/checkin/historico'), isTrue);
    expect(isAlunoOnlyLocation('/checkin/historico/12'), isTrue);
    expect(isAlunoOnlyLocation('/checkin/executar'), isTrue);
  });

  test('logged-in users leave pre-login gate', () {
    expect(shouldLeavePreLoginGate('/onboarding', const {}), isTrue);
    expect(shouldLeavePreLoginGate('/login', const {}), isTrue);
    expect(
      shouldLeavePreLoginGate('/login', const {'from': '/dashboard/personal'}),
      isFalse,
    );
    expect(shouldLeavePreLoginGate('/register', const {}), isFalse);
    expect(homePathForRole('ALUNO'), '/dashboard/aluno');
    expect(homePathForRole('PERSONAL'), '/dashboard/personal');
  });
}

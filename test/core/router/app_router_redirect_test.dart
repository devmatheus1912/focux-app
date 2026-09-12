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
    expect(isAlunoOnlyLocation('/aluno/perfil'), isTrue);
    expect(isAlunoOnlyLocation('/aluno/perfil/editar'), isTrue);
    expect(isAlunoOnlyLocation('/aluno/desafios'), isTrue);
    expect(isAlunoOnlyLocation('/aluno/desafios/4'), isTrue);
    expect(isPersonalOnlyLocation('/desafios/4'), isTrue);
    expect(isAlunoOnlyLocation('/aluno/habitos/4'), isTrue);
    expect(isPersonalOnlyLocation('/habitos'), isTrue);
    expect(isPersonalOnlyLocation('/habitos/4'), isTrue);
    expect(isAlunoOnlyLocation('/aluno/trilhas'), isTrue);
    expect(isAlunoOnlyLocation('/aluno/recorrencia'), isTrue);
    expect(isAlunoOnlyLocation('/aluno/form-check'), isTrue);
    expect(isAlunoOnlyLocation('/aluno/grupo-aulas'), isTrue);
    expect(isPersonalOnlyLocation('/retencao'), isTrue);
    expect(isPersonalOnlyLocation('/dunning'), isTrue);
    expect(isPersonalOnlyLocation('/leads-publicos'), isTrue);
    expect(isPersonalOnlyLocation('/leads/kanban'), isTrue);
    expect(isPersonalOnlyLocation('/winback'), isTrue);
    expect(isPersonalOnlyLocation('/alunos/9/ia/progressao'), isTrue);
    expect(isPersonalOnlyLocation('/ia/progressao/aceitar'), isTrue);
    expect(isPersonalOnlyLocation('/relatorio/business'), isTrue);
    expect(isPersonalOnlyLocation('/depoimentos'), isTrue);
    expect(isPersonalOnlyLocation('/depoimentos-aluno'), isFalse);
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

  test('aluno with pending password change cannot leave definir-senha', () {
    expect(
      passwordChangeRedirect(
        requiresPasswordChange: true,
        role: 'ALUNO',
        path: '/dashboard/aluno',
      ),
      '/aluno/definir-senha',
    );
    expect(
      passwordChangeRedirect(
        requiresPasswordChange: true,
        role: 'ALUNO',
        path: '/login',
      ),
      '/aluno/definir-senha',
    );
    expect(
      passwordChangeRedirect(
        requiresPasswordChange: true,
        role: 'ALUNO',
        path: '/home',
      ),
      '/aluno/definir-senha',
    );
    expect(
      passwordChangeRedirect(
        requiresPasswordChange: true,
        role: 'ALUNO',
        path: '/aluno/definir-senha',
      ),
      isNull,
    );
    expect(
      passwordChangeRedirect(
        requiresPasswordChange: false,
        role: 'ALUNO',
        path: '/dashboard/aluno',
      ),
      isNull,
    );
    expect(
      passwordChangeRedirect(
        requiresPasswordChange: true,
        role: 'PERSONAL',
        path: '/dashboard/personal',
      ),
      isNull,
    );
  });
}

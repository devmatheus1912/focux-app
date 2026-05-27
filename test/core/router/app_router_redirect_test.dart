import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/app_router_redirect.dart';

void main() {
  test('public routes include auth recovery paths', () {
    expect(isPublicLocation('/login'), isTrue);
    expect(isPublicLocation('/esqueci-senha'), isTrue);
    expect(isPublicLocation('/resetar-senha'), isTrue);
    expect(isPublicLocation('/dashboard/personal'), isFalse);
  });

  test('personal-only routes block aluno shell paths', () {
    expect(isPersonalOnlyLocation('/white-label'), isTrue);
    expect(isPersonalOnlyLocation('/alunos/42'), isTrue);
    expect(isAlunoOnlyLocation('/checkin/treinos'), isTrue);
  });
}

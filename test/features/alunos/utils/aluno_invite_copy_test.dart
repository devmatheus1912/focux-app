import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno_invite_copy.dart';

void main() {
  test('convite usa primeiro nome, e-mail e senha', () {
    final text = alunoInviteMessage(
      nome: 'Nathalia Costa',
      email: 'nathalia@test.com',
      senhaProvisoria: 'AB12CD',
    );
    expect(text, contains('Olá Nathalia!'));
    expect(text, contains('nathalia@test.com'));
    expect(text, contains('AB12CD'));
    expect(text, contains('primeiro acesso'));
  });
}

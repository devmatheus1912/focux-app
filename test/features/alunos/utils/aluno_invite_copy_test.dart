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
    expect(text, contains('?p=slug'));
  });

  test('convite com slug inclui link de login do aluno', () {
    final text = alunoInviteMessage(
      nome: 'Nathalia Costa',
      email: 'nathalia@test.com',
      senhaProvisoria: 'AB12CD',
      personalSlug: 'nath-coach',
    );
    expect(text, contains('/p/nath-coach'));
    expect(text, isNot(contains('Peça ao personal o link')));
  });

  test('senha provisória com slug inclui link', () {
    final text = alunoSenhaProvisoriaMessage(
      nome: 'Nathalia Costa',
      email: 'nathalia@test.com',
      senha: 'XY99',
      personalSlug: 'studio-x',
    );
    expect(text, contains('/p/studio-x'));
    expect(text, contains('XY99'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/dashboard/utils/aluno_perfil_completion.dart';

void main() {
  test('alunoPerfilCompletionScore counts filled identity fields', () {
    final empty = Aluno(
      id: 1,
      nome: '',
      email: '',
      status: 'ATIVO',
    );
    expect(alunoPerfilCompletionScore(empty), 0);

    final full = Aluno(
      id: 1,
      nome: 'Ana',
      email: 'ana@example.com',
      status: 'ATIVO',
      objetivo: 'Força',
      whatsapp: '62999999999',
      peso: 62,
      altura: 1.64,
      dataNascimento: '1998-03-12',
    );
    expect(alunoPerfilCompletionScore(full), 100);
  });
}

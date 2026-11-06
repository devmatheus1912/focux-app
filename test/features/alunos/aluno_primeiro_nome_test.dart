import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/aluno_status.dart';

void main() {
  test('primeiro nome ignora espaço sobrando entre e em volta dos nomes', () {
    expect(alunoPrimeiroNome('  Ana   Paula Souza '), 'Ana');
    expect(alunoPrimeiroNome('Ana'), 'Ana');
  });

  test('nome vazio usa o texto que cada mensagem pede', () {
    expect(alunoPrimeiroNome('   '), 'o aluno');
    expect(alunoPrimeiroNome('', vazio: 'aluno'), 'aluno');
    expect(alunoPrimeiroNome('', vazio: ''), '');
  });
}

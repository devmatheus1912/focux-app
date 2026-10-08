import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/editar_aluno_display.dart';
import 'package:focux_app/features/chat/data/chat_repository.dart';

void main() {
  group('editarAlunoAlturaValida', () {
    test('vazio é válido (campo opcional)', () {
      expect(editarAlunoAlturaValida(''), isTrue);
      expect(editarAlunoAlturaValida(null), isTrue);
    });

    test('aceita 100 a 250 cm', () {
      expect(editarAlunoAlturaValida('175'), isTrue);
      expect(editarAlunoAlturaValida('100'), isTrue);
      expect(editarAlunoAlturaValida('250'), isTrue);
    });

    test('recusa fora da faixa', () {
      expect(editarAlunoAlturaValida('99'), isFalse);
      expect(editarAlunoAlturaValida('251'), isFalse);
    });

    test('não deixa apagar altura já cadastrada', () {
      expect(editarAlunoAlturaValida('', obrigatorio: true), isFalse);
    });

    test('envia em metros', () {
      expect(editarAlunoAlturaMetros('175'), 1.75);
    });
  });

  group('editarAlunoNascimentoValido', () {
    test('aceita DD-MM-AAAA, DD/MM/AAAA e DDMMAAAA', () {
      expect(editarAlunoNascimentoValido('19-12-1995'), isTrue);
      expect(editarAlunoNascimentoValido('19/12/1995'), isTrue);
      expect(editarAlunoNascimentoValido('19121995'), isTrue);
    });

    test('recusa data inexistente ou futura', () {
      expect(editarAlunoNascimentoValido('31-02-1995'), isFalse);
      expect(editarAlunoNascimentoValido('abc'), isFalse);
      final ano = DateTime.now().year + 1;
      expect(editarAlunoNascimentoValido('01-01-$ano'), isFalse);
    });
  });

  test('ChatBloqueio lê os dois lados do bloqueio', () {
    final livre = ChatBloqueio.fromJson({'alunoId': 1});
    expect(livre.ativo, isFalse);

    final peloAluno = ChatBloqueio.fromJson({
      'blockedByPersonal': false,
      'blockedByAluno': true,
    });
    expect(peloAluno.ativo, isTrue);
    expect(peloAluno.peloAluno, isTrue);
    expect(peloAluno.peloPersonal, isFalse);
  });
}

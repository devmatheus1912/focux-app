import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno_status.dart';

void main() {
  group('alunoStatusAcoesDisponiveis', () {
    test('ativo pode pausar ou bloquear', () {
      expect(alunoStatusAcoesDisponiveis('ATIVO').map(alunoStatusAcaoLabel), [
        'Pausar aluno',
        'Bloquear acesso',
      ]);
    });

    test('pausado pode reativar ou bloquear', () {
      expect(alunoStatusAcoesDisponiveis('INATIVO').map(alunoStatusAcaoLabel), [
        'Reativar',
        'Bloquear acesso',
      ]);
    });

    test('bloqueado pode reativar ou só pausar', () {
      expect(
        alunoStatusAcoesDisponiveis('BLOQUEADO').map(alunoStatusAcaoLabel),
        ['Reativar', 'Pausar aluno'],
      );
    });
  });

  group('alunoStatusAlteradoMessage', () {
    test('usa primeiro nome e gênero', () {
      expect(
        alunoStatusAlteradoMessage(
          'INATIVO',
          nome: 'Nathalia Abrantes',
          genero: 'FEMININO',
        ),
        'Nathalia pausada',
      );
      expect(
        alunoStatusAlteradoMessage(
          'ATIVO',
          nome: 'João Silva',
          genero: 'MASCULINO',
        ),
        'João reativado',
      );
      expect(
        alunoStatusAlteradoMessage('BLOQUEADO', nome: 'Nathalia Abrantes'),
        'Acesso de Nathalia bloqueado',
      );
    });

    test('sem gênero fica neutro', () {
      expect(
        alunoStatusAlteradoMessage('INATIVO', nome: 'Alex Lima'),
        'Pausa aplicada a Alex',
      );
      expect(
        alunoStatusAlteradoMessage('ATIVO', nome: 'Alex Lima'),
        'Cadastro de Alex reativado',
      );
    });
  });

  group('lote', () {
    test('feedback explícito por status', () {
      expect(alunosStatusAlteradosMessage('INATIVO', 2), '2 alunos pausados');
      expect(alunosStatusAlteradosMessage('BLOQUEADO', 1), '1 aluno bloqueado');
      expect(alunosStatusAlteradosMessage('ATIVO', 3), '3 alunos reativados');
    });

    test('confirmação no plural', () {
      expect(alunosStatusConfirmTitle('INATIVO', 2), 'Pausar 2 alunos?');
      expect(
        alunoStatusConfirmMessage('BLOQUEADO', count: 2),
        startsWith('Os alunos perdem o acesso'),
      );
    });

    test('status comum só quando todos batem', () {
      Aluno a(String s) => Aluno(id: 1, nome: 'A', email: '', status: s);
      expect(alunosStatusComum([a('INATIVO'), a('INATIVO')]), 'INATIVO');
      expect(alunosStatusComum([a('INATIVO'), a('ATIVO')]), isNull);
      expect(alunosStatusComum(const []), isNull);
    });
  });

  test('confirmações da ficha explicam o efeito', () {
    expect(
      alunoStatusConfirmTitle('INATIVO', 'Nathalia A'),
      'Pausar Nathalia?',
    );
    expect(
      alunoStatusConfirmMessage('INATIVO'),
      'Sem alertas, cobranças automáticas e lembretes. '
      'O aluno continua vendo o histórico.',
    );
    expect(
      alunoStatusConfirmMessage('BLOQUEADO'),
      'O aluno perde o acesso ao app na hora. '
      'Sem alertas e cobranças automáticas.',
    );
  });
}

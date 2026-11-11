import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/chat/utils/aluno_picker_list.dart';

Aluno _aluno({
  required int id,
  required String nome,
  String email = '',
  String status = 'ATIVO',
  String? risco,
  int? dias,
}) {
  return Aluno(
    id: id,
    nome: nome,
    email: email,
    status: status,
    riscoNivel: risco,
    diasSemTreino: dias,
  );
}

void main() {
  final ana = _aluno(id: 1, nome: 'Ana Silva', email: 'ana@test.com');
  final bruno = _aluno(id: 2, nome: 'Bruno Costa', email: 'bruno@test.com');

  group('filterAlunoPickerAlunos', () {
    test('returns all when query is empty', () {
      expect(filterAlunoPickerAlunos([ana, bruno], '  '), [ana, bruno]);
    });

    test('matches nome or email', () {
      expect(filterAlunoPickerAlunos([ana, bruno], 'bruno'), [bruno]);
      expect(filterAlunoPickerAlunos([ana, bruno], 'ANA@'), [ana]);
    });
  });

  group('Nova conversa', () {
    final parado = _aluno(id: 3, nome: 'Caio', dias: 7);
    final risco = _aluno(id: 4, nome: 'Duda', risco: 'ALTO');

    test('quem precisa de você vem primeiro; o resto em ordem alfabética', () {
      final g = gruposDaNovaConversa([bruno, risco, ana, parado], '');
      expect(g.precisam, [parado, risco]);
      expect(g.todos, [ana, bruno]);
      expect(alunoMotivoAtencao(parado), 'Parado há 7 dias');
      expect(alunoMotivoAtencao(risco), 'Risco alto');
    });

    test('com busca, uma lista só', () {
      final g = gruposDaNovaConversa([bruno, risco, ana, parado], 'u');
      expect(g.precisam, isEmpty);
      expect(g.todos.map((a) => a.nome), ['Bruno Costa', 'Duda']);
    });

    test('sugestões: até 3 ativos sem conversa, atenção primeiro', () {
      final inativo = _aluno(id: 5, nome: 'Eva', status: 'INATIVO');
      final s = sugestoesDeConversa(
        [ana, bruno, parado, risco, inativo],
        comConversa: {1},
      );
      expect(s, [parado, risco, bruno]);
    });
  });
}

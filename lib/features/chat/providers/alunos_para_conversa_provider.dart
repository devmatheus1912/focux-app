import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/sessao_provider.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../alunos/providers/alunos_provider.dart';

/// Teto de páginas: 40 × 25 = 1.000 alunos, bem acima de qualquer plano.
const _paginasMaximas = 25;

/// Todos os alunos da carteira para escolher com quem conversar: sem a busca
/// nem o filtro da tela Alunos (o `alunosHomeProvider` segue os dois e traz só
/// a primeira página), percorrendo as páginas até o fim.
final alunosParaConversaProvider = FutureProvider.autoDispose<List<Aluno>>((
  ref,
) async {
  ref.watch(sessaoProvider);
  final repo = ref.read(alunoRepositoryProvider);
  final todos = <Aluno>[];
  for (var pagina = 0; pagina < _paginasMaximas; pagina++) {
    final home = await repo.getHome(page: pagina, ordenacao: 'nome');
    todos.addAll(home.alunos);
    if (!home.page.hasNext) break;
  }
  return todos;
});

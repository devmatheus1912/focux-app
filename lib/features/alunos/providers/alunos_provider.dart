import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';

final alunoRepositoryProvider = Provider<AlunoRepository>(
  (ref) => AlunoRepository(ref.read(apiClientProvider)),
);

final alunosHomeProvider = FutureProvider<AlunosHomeBundle>((ref) async {
  return ref.read(alunoRepositoryProvider).getHome();
});

final alunosProvider = FutureProvider<List<Aluno>>((ref) async {
  return (await ref.watch(alunosHomeProvider.future)).alunos;
});

final alunoProvider = FutureProvider.family<Aluno, int>((ref, id) async {
  return ref.read(alunoRepositoryProvider).buscar(id);
});

final alunoAutonomiaEventosProvider =
    FutureProvider.family<List<AlunoAutonomiaEvento>, int>((ref, id) async {
      return ref.read(alunoRepositoryProvider).listarAutonomiaEventos(id);
    });

final alunoAutonomiaResumoProvider =
    FutureProvider.family<AlunoAutonomiaResumo, int>((ref, id) async {
      return ref.read(alunoRepositoryProvider).buscarAutonomiaResumo(id);
    });

/// Perfil do aluno autenticado (endpoint /api/alunos/me).
final alunoMeProvider = FutureProvider<Aluno>((ref) async {
  return ref.read(alunoRepositoryProvider).me();
});

void invalidateAlunosCaches(WidgetRef ref) {
  ref.invalidate(alunosHomeProvider);
}

void invalidateAlunosCachesRef(Ref ref) {
  ref.invalidate(alunosHomeProvider);
}

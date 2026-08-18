import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/aluno_repository.dart';
import '../../ia/providers/ia_copilot_providers.dart';

final alunoRepositoryProvider = Provider<AlunoRepository>(
  (ref) => AlunoRepository(ref.read(apiClientProvider)),
);

final alunosHomeProvider = FutureProvider<AlunosHomeBundle>((ref) async {
  return ref.read(alunoRepositoryProvider).getHomeAll();
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

/// Perfil do aluno autenticado (endpoint /api/aluno/me).
final alunoMeProvider = FutureProvider<Aluno>((ref) async {
  return ref.read(alunoRepositoryProvider).me();
});

/// BFF da aba Perfil — `GET /api/aluno/perfil/home`.
final alunoPerfilHomeProvider = FutureProvider<AlunoPerfilHomeBundle>((ref) async {
  return ref.read(alunoRepositoryProvider).getPerfilHome();
});

void invalidateAlunosCaches(WidgetRef ref) {
  ref.invalidate(alunosHomeProvider);
  ref.invalidate(iaCopilotoHomeProvider);
}

void invalidateAlunosCachesRef(Ref ref) {
  ref.invalidate(alunosHomeProvider);
  ref.invalidate(iaCopilotoHomeProvider);
}

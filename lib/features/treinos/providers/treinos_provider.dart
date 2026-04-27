import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/treino_repository.dart';

final treinoRepositoryProvider = Provider<TreinoRepository>(
  (ref) => TreinoRepository(ref.read(apiClientProvider)),
);

final treinosProvider = FutureProvider<List<Treino>>((ref) async {
  return ref.watch(treinoRepositoryProvider).listar();
});

final treinosDoAlunoProvider = FutureProvider.family<List<Treino>, int>((ref, alunoId) async {
  return ref.watch(treinoRepositoryProvider).listarTreinosDoAluno(alunoId);
});

final treinoProvider = FutureProvider.family<Treino, int>((ref, id) async {
  return ref.watch(treinoRepositoryProvider).buscar(id);
});

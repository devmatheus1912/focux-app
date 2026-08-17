import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/treino_repository.dart';

final treinoRepositoryProvider = Provider<TreinoRepository>(
  (ref) => TreinoRepository(ref.read(apiClientProvider)),
);

final treinosHomeProvider = FutureProvider<TreinosHomeBundle>((ref) async {
  return ref.watch(treinoRepositoryProvider).getHome();
});

final treinosProvider = FutureProvider<List<Treino>>((ref) async {
  return (await ref.watch(treinosHomeProvider.future)).treinos;
});

final treinosDoAlunoProvider = FutureProvider.family<List<Treino>, int>((
  ref,
  alunoId,
) async {
  return ref.watch(treinoRepositoryProvider).listarTreinosDoAluno(alunoId);
});

final treinoProvider = FutureProvider.family<Treino, int>((ref, id) async {
  return ref.watch(treinoRepositoryProvider).buscar(id);
});

/// First paint do picker — um GET (`/api/treinos/{id}/picker/home`).
final treinoPickerHomeProvider =
    FutureProvider.family<TreinoPickerHomeBundle, int>((ref, treinoId) async {
      return ref.watch(treinoRepositoryProvider).getPickerHome(treinoId);
    });

void invalidateTreinosCaches(WidgetRef ref) {
  ref.invalidate(treinosHomeProvider);
}

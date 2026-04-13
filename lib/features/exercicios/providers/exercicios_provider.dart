import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/exercicio_repository.dart';

final exercicioRepositoryProvider = Provider<ExercicioRepository>(
  (ref) => ExercicioRepository(ref.read(apiClientProvider)),
);

final exerciciosProvider = FutureProvider<List<Exercicio>>((ref) async {
  return ref.read(exercicioRepositoryProvider).listar();
});

final exercicioProvider = FutureProvider.family<Exercicio, int>((ref, id) async {
  return ref.read(exercicioRepositoryProvider).buscar(id);
});

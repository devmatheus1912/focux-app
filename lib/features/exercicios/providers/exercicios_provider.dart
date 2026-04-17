import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/exercicio_repository.dart';

final exercicioRepositoryProvider = Provider<ExercicioRepository>(
  (ref) => ExercicioRepository(ref.read(apiClientProvider)),
);

// Parâmetros de filtro para a lista de exercícios
class ExercicioFilter {
  final String? categoria;
  final String? tag;
  final bool? favoritos;

  const ExercicioFilter({this.categoria, this.tag, this.favoritos});

  @override
  bool operator ==(Object other) =>
      other is ExercicioFilter &&
      other.categoria == categoria &&
      other.tag == tag &&
      other.favoritos == favoritos;

  @override
  int get hashCode => Object.hash(categoria, tag, favoritos);
}

// Provider com filtros
final exerciciosFilteredProvider =
    FutureProvider.family<List<Exercicio>, ExercicioFilter>((ref, filter) async {
  return ref.read(exercicioRepositoryProvider).listar(
        categoria: filter.categoria,
        tag: filter.tag,
        favoritos: filter.favoritos,
      );
});

// Provider sem filtro (compatibilidade)
final exerciciosProvider = FutureProvider<List<Exercicio>>((ref) async {
  return ref.read(exercicioRepositoryProvider).listar();
});

final exercicioProvider = FutureProvider.family<Exercicio, int>((ref, id) async {
  return ref.read(exercicioRepositoryProvider).buscar(id);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/exercicio_repository.dart';

final exercicioRepositoryProvider = Provider<ExercicioRepository>(
  (ref) => ExercicioRepository(ref.read(apiClientProvider)),
);

// Parâmetros de filtro para a lista de exercícios
class ExercicioFilter {
  final String? nome;
  final String? categoria;
  final String? tag;
  final String? musculoAlvo;
  final String? equipamento;
  final String? nivel;
  final String? mecanica;
  final String? objetivo;
  final bool? favoritos;

  const ExercicioFilter({
    this.nome,
    this.categoria,
    this.tag,
    this.musculoAlvo,
    this.equipamento,
    this.nivel,
    this.mecanica,
    this.objetivo,
    this.favoritos,
  });

  @override
  bool operator ==(Object other) =>
      other is ExercicioFilter &&
      other.nome == nome &&
      other.categoria == categoria &&
      other.tag == tag &&
      other.musculoAlvo == musculoAlvo &&
      other.equipamento == equipamento &&
      other.nivel == nivel &&
      other.mecanica == mecanica &&
      other.objetivo == objetivo &&
      other.favoritos == favoritos;

  @override
  int get hashCode => Object.hash(
        nome,
        categoria,
        tag,
        musculoAlvo,
        equipamento,
        nivel,
        mecanica,
        objetivo,
        favoritos,
      );
}

// Provider com filtros
final exerciciosFilteredProvider =
    FutureProvider.family<List<Exercicio>, ExercicioFilter>((ref, filter) async {
  return ref.read(exercicioRepositoryProvider).listar(
        nome: filter.nome,
        categoria: filter.categoria,
        tag: filter.tag,
        musculoAlvo: filter.musculoAlvo,
        equipamento: filter.equipamento,
        nivel: filter.nivel,
        mecanica: filter.mecanica,
        objetivo: filter.objetivo,
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

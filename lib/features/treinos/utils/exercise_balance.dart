import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';

/// Quantos exercícios de cada grupo já estão no treino. Grupos com zero
/// ficam de fora.
Map<GrupoMuscular, int> balancoDoTreino(Iterable<GrupoMuscular?> grupos) {
  final out = <GrupoMuscular, int>{};
  for (final g in grupos) {
    if (g == null) continue;
    out[g] = (out[g] ?? 0) + 1;
  }
  return out;
}

int _soma(Map<GrupoMuscular, int> b, List<GrupoMuscular> grupos) =>
    grupos.fold(0, (total, g) => total + (b[g] ?? 0));

const _costas = [
  GrupoMuscular.costasLatissimo,
  GrupoMuscular.costasRetangulares,
];

/// Um aviso discreto quando o treino tem 4 ou mais de um grupo e nenhum do
/// oposto. É só sugestão: o personal decide.
String? avisoAntagonista(Map<GrupoMuscular, int> b) {
  const minimo = 4;
  String nome(GrupoMuscular g) =>
      (TaxonomyLabels.grupo[g] ?? g.name).toLowerCase();

  final peito = b[GrupoMuscular.peito] ?? 0;
  final costas = _soma(b, _costas);
  if (peito >= minimo && costas == 0) return 'Sem costas ainda';
  if (costas >= minimo && peito == 0) return 'Sem peito ainda';

  final quad = b[GrupoMuscular.quadriceps] ?? 0;
  final post = b[GrupoMuscular.posteriorCoxa] ?? 0;
  if (quad >= minimo && post == 0) {
    return 'Sem ${nome(GrupoMuscular.posteriorCoxa)} ainda';
  }
  if (post >= minimo && quad == 0) {
    return 'Sem ${nome(GrupoMuscular.quadriceps)} ainda';
  }

  final bi = b[GrupoMuscular.biceps] ?? 0;
  final tri = b[GrupoMuscular.triceps] ?? 0;
  if (bi >= minimo && tri == 0) return 'Sem ${nome(GrupoMuscular.triceps)} ainda';
  if (tri >= minimo && bi == 0) return 'Sem ${nome(GrupoMuscular.biceps)} ainda';
  return null;
}

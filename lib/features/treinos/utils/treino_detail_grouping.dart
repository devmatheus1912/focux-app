import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../data/treino_repository.dart';

String treinoDetailContextLabel(Treino treino, String? alunoNome) {
  final name = alunoNome?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (treino.isTemplate) return 'Template base';
  return 'Plano base';
}

String formatTreinoLoadKg(double? value) {
  if (value == null || value <= 0) return '—';
  if (value == value.roundToDouble()) return '${value.toStringAsFixed(0)}kg';
  return '${value.toStringAsFixed(1)}kg';
}

String treinoDetailGroupLabel(TreinoExercicioItem te) {
  final grupo = te.exercicio.grupoMuscularPrimario;
  if (grupo != null) {
    final label = TaxonomyLabels.grupo[grupo];
    if (label != null && label.isNotEmpty) return label.toUpperCase();
  }
  final alvo = te.exercicio.musculoAlvo?.trim();
  if (alvo != null && alvo.isNotEmpty) return alvo.toUpperCase();
  return 'OUTROS';
}

bool treinoDetailShowsGroupHeader(List<TreinoExercicioItem> items, int index) {
  if (index <= 0) return true;
  return treinoDetailGroupLabel(items[index]) !=
      treinoDetailGroupLabel(items[index - 1]);
}

int treinoDetailLocalIndexInGroup(List<TreinoExercicioItem> items, int index) {
  final group = treinoDetailGroupLabel(items[index]);
  var local = 1;
  for (var i = index - 1; i >= 0; i--) {
    if (treinoDetailGroupLabel(items[i]) != group) break;
    local++;
  }
  return local;
}

int treinoDetailGroupExerciseCount(List<TreinoExercicioItem> items, int index) {
  final group = treinoDetailGroupLabel(items[index]);
  return items.where((item) => treinoDetailGroupLabel(item) == group).length;
}

bool treinoDetailIsLastInGroup(List<TreinoExercicioItem> items, int index) {
  if (index >= items.length - 1) return true;
  return treinoDetailGroupLabel(items[index]) !=
      treinoDetailGroupLabel(items[index + 1]);
}

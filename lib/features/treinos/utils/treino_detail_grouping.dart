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

int treinoDetailSeriesCount(List<TreinoExercicioItem> items) =>
    items.fold<int>(0, (sum, item) => sum + item.series);

int treinoDetailGroupCount(List<TreinoExercicioItem> items) =>
    items.map(treinoDetailGroupLabel).toSet().length;

String treinoDetailSeriesHint(int groups) =>
    groups == 1 ? '1 grupo muscular' : '$groups grupos';

String treinoDetailGroupTileHint(int groups) =>
    groups == 0 ? 'Ainda vazio' : 'Músculos distintos';

double? treinoDetailCargaTotalKg(List<TreinoExercicioItem> items) {
  var sum = 0.0;
  var any = false;
  for (final item in items) {
    final kg = item.cargaKg;
    if (kg == null || kg <= 0) continue;
    sum += kg;
    any = true;
  }
  return any ? sum : null;
}

String treinoDetailCargaValue(List<TreinoExercicioItem> items) =>
    formatTreinoLoadKg(treinoDetailCargaTotalKg(items));

String treinoDetailCargaHint(List<TreinoExercicioItem> items) =>
    treinoDetailCargaTotalKg(items) == null
        ? 'Sem carga prescrita'
        : 'Soma das prescrições';

/// Contagens reais da prescrição — sem duração inventada.
String treinoDetailMetaLine(List<TreinoExercicioItem> items) {
  if (items.isEmpty) return 'Em montagem';
  final exercises = items.length;
  final series = treinoDetailSeriesCount(items);
  final groups = treinoDetailGroupCount(items);
  final ex = exercises == 1 ? '1 exercício' : '$exercises exercícios';
  final ser = series == 1 ? '1 série' : '$series séries';
  final grp = groups == 1 ? '1 grupo' : '$groups grupos';
  return '$ex · $ser · $grp';
}

/// Prescrição numa linha — o que o personal precisa escanear.
String treinoDetailExerciseLine(TreinoExercicioItem te) {
  final parts = <String>['${te.series}×${te.repeticoes}'];
  final load = formatTreinoLoadKg(te.cargaKg);
  if (load != '—') parts.add(load);
  parts.add('${te.descansoSegundos ?? 60}s');
  if (te.tipoSerie == 'SUPERSET') {
    final grupo = te.grupoSuperset;
    parts.add(grupo == null ? 'SS' : 'SS$grupo');
  } else if (te.tipoSerie == 'DROPSET') {
    parts.add('drop');
  }
  return parts.join(' · ');
}

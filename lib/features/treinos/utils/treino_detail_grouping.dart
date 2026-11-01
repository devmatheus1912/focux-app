import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../data/treino_repository.dart';
import '../utils/prescricao_serie.dart';
import '../../../core/utils/pt_br_display.dart';

String treinoDetailContextLabel(Treino treino, String? alunoNome) {
  final name = alunoNome?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (treino.isTemplate) return 'Template base';
  return 'Plano base';
}

String formatTreinoLoadKg(double? value) {
  if (value == null || value <= 0) return '—';
  if (value == value.roundToDouble()) return '${value.toStringAsFixed(0)}kg';
  return '${formatBrDecimal(value)}kg';
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

int treinoDetailSeriesCount(List<TreinoExercicioItem> items) =>
    items.fold<int>(0, (sum, item) => sum + item.series);

int treinoDetailGroupCount(List<TreinoExercicioItem> items) =>
    items.map(treinoDetailGroupLabel).toSet().length;

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
  if (te.seriesLinhas.isNotEmpty) {
    return resumoSeries(
      te.seriesLinhas,
      descansoSegundos: te.descansoSegundos ?? 75,
    );
  }
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

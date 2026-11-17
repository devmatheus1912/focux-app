import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import '../data/treino_repository.dart';
import '../models/metodo_exercicio.dart';
import '../utils/grupos_de_serie.dart';
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

/// Prescrição numa linha — o que o personal precisa escanear. Termina no
/// método ("Drop-set na última", "Pirâmide ↓", "Pico 2 s"): sem ele o personal
/// não via se a técnica tinha sido salva.
String treinoDetailExerciseLine(TreinoExercicioItem te) {
  final base = _linhaDaPrescricao(te);
  final metodo = resumoDoMetodo(te);
  return metodo.isEmpty ? base : '$base · $metodo';
}

String _linhaDaPrescricao(TreinoExercicioItem te) {
  if (te.seriesLinhas.isNotEmpty) {
    final validas = te.seriesLinhas.where((l) => l.papel == PapelDaSerie.valida).toList();
    final soValidas = validas.length == te.seriesLinhas.length;
    // Pirâmide só de válidas: "4 séries · 15 → 9 · 60 s".
    if (te.metodo.piramide && soValidas && validas.length > 1 &&
        validas.first.repeticoes != validas.last.repeticoes) {
      return '${validas.length} séries · ${validas.first.repeticoes} → '
          '${validas.last.repeticoes} · ${te.descansoSegundos ?? 75} s';
    }
    return resumoSeries(
      te.seriesLinhas,
      descansoSegundos: te.descansoSegundos ?? 75,
    );
  }
  final parts = <String>['${te.series} × ${te.repeticoes}'];
  final load = formatTreinoLoadKg(te.cargaKg);
  if (load != '—') parts.add(load);
  parts.add('${te.descansoSegundos ?? 60} s');
  if (te.tipoSerie == 'SUPERSET') {
    final grupo = te.grupoSuperset;
    parts.add(grupo == null ? 'SS' : 'SS$grupo');
  }
  return parts.join(' · ');
}

/// "Pirâmide ↑ · Drop-set na última", "Pico 2 s", "Rest-pause em 2 séries".
String resumoDoMetodo(TreinoExercicioItem te) {
  final m = te.metodo;
  final partes = <String>[
    if (m.piramide) rotuloDaProgressao(m.progressao),
    if (m.tecnica != Tecnica.normal) rotuloCurtoDaTecnica(m.tecnica, m) + _ondeVale(te),
  ];
  return partes.join(' · ');
}

String _ondeVale(TreinoExercicioItem te) {
  final validas = te.seriesLinhas.where((l) => l.papel == PapelDaSerie.valida).toList();
  if (validas.length < 2) return '';
  final marcadas = [for (var i = 0; i < validas.length; i++) if (validas[i].tecnica != null) i];
  if (marcadas.isEmpty || marcadas.length == validas.length) return '';
  if (marcadas.length == 1 && marcadas.single == validas.length - 1) return ' na última';
  return marcadas.length == 1 ? ' em 1 série' : ' em ${marcadas.length} séries';
}

import '../../../core/utils/fx_utils.dart';
import '../data/relatorio_repository.dart';

String relatorioAderenciaMediaLabel(double media) {
  return '${media.clamp(0, 100).toStringAsFixed(1)}%';
}

String relatorioAderenciaPercentLabel(int concluidos, int total) {
  if (total <= 0) return '0%';
  final pct = (concluidos * 100.0 / total).clamp(0, 100);
  return '${pct.toStringAsFixed(0)}%';
}

String relatorioTreinosSubtitle(int concluidos, int total) {
  if (total <= 0) return 'Ainda sem treinos';
  if (concluidos == 1 && total == 1) return '1 de 1 treino concluído';
  return '$concluidos de $total treinos concluídos';
}

double relatorioAderenciaPct(int concluidos, int total) {
  if (total <= 0) return 0;
  return concluidos * 100.0 / total;
}

List<T> relatorioRankingPreview<T>(List<T> items) =>
    items.take(3).toList(growable: false);

List<ResumoAluno> relatorioCatalogoMais(ResumoGlobal dados) {
  final source = dados.itens.isNotEmpty ? dados.itens : dados.maisComprometidos;
  final copy = List<ResumoAluno>.of(source);
  copy.sort(
    (a, b) => relatorioAderenciaPct(
      b.treinosConcluidos,
      b.totalTreinos,
    ).compareTo(relatorioAderenciaPct(a.treinosConcluidos, a.totalTreinos)),
  );
  return copy;
}

List<ResumoAluno> relatorioCatalogoMenos(ResumoGlobal dados) {
  final source = dados.itens.isNotEmpty ? dados.itens : dados.menosComprometidos;
  final copy = List<ResumoAluno>.of(source);
  copy.sort(
    (a, b) => relatorioAderenciaPct(
      a.treinosConcluidos,
      a.totalTreinos,
    ).compareTo(relatorioAderenciaPct(b.treinosConcluidos, b.totalTreinos)),
  );
  return copy;
}

List<T> relatorioRankingSearch<T>(
  List<T> items,
  String q,
  String Function(T item) nomeOf,
) {
  final needle = q.trim().toLowerCase();
  if (needle.isEmpty) return List.of(items);
  return items
      .where((item) => nomeOf(item).toLowerCase().contains(needle))
      .toList(growable: false);
}

T? firstRelatorioAtencao<T>(List<T> menosComprometidos) =>
    menosComprometidos.isEmpty ? null : menosComprometidos.first;

const relatorioComoCalculamos =
    'Média de aderência de todos os alunos da base, não só do ranking.';

String relatorioUltimoTreinoLabel(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return 'Sem treinos';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return fxDateFull(date);
}

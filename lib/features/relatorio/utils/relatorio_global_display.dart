import '../../../core/utils/fx_utils.dart';
import '../data/relatorio_repository.dart';
import '../../../core/utils/pt_br_display.dart';

String relatorioAderenciaMediaLabel(double media) {
  return '${formatBrDecimal(media.clamp(0, 100))}%';
}

String relatorioAderenciaPercentLabel(int concluidos, int total) {
  if (total <= 0) return '0%';
  final pct = (concluidos * 100.0 / total).clamp(0, 100);
  return '${pct.toStringAsFixed(0)}%';
}

String relatorioTreinosSubtitle(int concluidos, int total) {
  if (total <= 0) return 'Ainda sem dias com check-in';
  if (concluidos == 1 && total == 1) return '1 de 1 dia com check-in';
  return '$concluidos de $total dias com check-in';
}

double relatorioAderenciaPct(int concluidos, int total) {
  if (total <= 0) return 0;
  return concluidos * 100.0 / total;
}

List<T> relatorioRankingPreview<T>(List<T> items) =>
    items.take(3).toList(growable: false);

List<ResumoAluno> relatorioRankingMaisPreview(ResumoGlobal dados) {
  final atencaoIds =
      relatorioCatalogoMenos(dados).map((a) => a.alunoId).toSet();
  final mais = relatorioCatalogoMais(
    dados,
  ).where((a) => !atencaoIds.contains(a.alunoId)).toList(growable: false);
  // Base pequena: se sobrar vazio, mostra o top sem duplicar na atenção.
  if (mais.isEmpty) {
    return relatorioRankingPreview(relatorioCatalogoMais(dados));
  }
  return relatorioRankingPreview(mais);
}

List<ResumoAluno> relatorioRankingMenosPreview(ResumoGlobal dados) {
  final maisPreviewIds =
      relatorioRankingMaisPreview(dados).map((a) => a.alunoId).toSet();
  final menos = relatorioCatalogoMenos(
    dados,
  ).where((a) => !maisPreviewIds.contains(a.alunoId)).toList(growable: false);
  if (menos.isEmpty) {
    // Um único aluno: prioriza "atenção" se a média pede; senão lista só em comprometidos.
    if (dados.totalAlunos <= 1) {
      return const [];
    }
    return relatorioRankingPreview(relatorioCatalogoMenos(dados));
  }
  return relatorioRankingPreview(menos);
}

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
  final copy = List<ResumoAluno>.of(source).where(relatorioPrecisaAtencao).toList();
  copy.sort(
    (a, b) => relatorioAderenciaPct(
      a.treinosConcluidos,
      a.totalTreinos,
    ).compareTo(relatorioAderenciaPct(b.treinosConcluidos, b.totalTreinos)),
  );
  return copy;
}

bool relatorioPrecisaAtencao(ResumoAluno a) {
  if (a.treinosConcluidos <= 0) return true;
  return relatorioAderenciaPct(a.treinosConcluidos, a.totalTreinos) < 70;
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
    'Aderência = dias únicos com check-in concluído / 30. '
    'Dois treinos no mesmo dia contam 1. '
    'Média só entre quem treinou. Atenção = 0 dias ou abaixo de 70%.';

String relatorioUltimoTreinoLabel(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return 'Sem treinos';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return fxDateFull(date);
}

import '../../../core/utils/fx_utils.dart';
import '../data/nps_repository.dart';

String npsClassify(int score) {
  if (score >= 9) return 'Promotor';
  if (score >= 7) return 'Neutro';
  return 'Detrator';
}

bool npsIsDetrator(int score) => score <= 6;

NpsItem? firstNpsDetrator(List<NpsItem> items) {
  for (final item in items) {
    if (npsIsDetrator(item.score)) return item;
  }
  return null;
}

List<NpsItem> npsRecentPreview(List<NpsItem> items) =>
    items.take(3).toList(growable: false);

const npsComoCalculamos =
    'Promotores (9–10) menos detratores (0–6), em % do total. O catálogo pagina as respostas e busca nome ou comentário.';

const npsFiltroDetratores = 'detratores';

String npsNormalizeFiltro(String? raw) {
  final value = (raw ?? '').trim().toLowerCase();
  return value == npsFiltroDetratores ? npsFiltroDetratores : '';
}

bool npsHasAluno(NpsItem item) => item.alunoId != null && item.alunoId! > 0;

/// "Promotor · Ana · hoje às 18:39" — nome só quando o título é o comentário.
String npsItemSubtitle(NpsItem item, {DateTime? now}) {
  final parts = <String>[npsClassify(item.score)];
  final temComentario = item.comentario?.trim().isNotEmpty == true;
  final nome = item.alunoNome?.trim();
  if (temComentario && nome != null && nome.isNotEmpty) parts.add(nome);
  final quando = fxDateTimeLabelFromIso(item.criadoEm, now: now);
  if (quando.isNotEmpty) parts.add(quando);
  return parts.join(' · ');
}

List<NpsItem> npsItemsForFiltro(List<NpsItem> items, String? filtro) {
  if (npsNormalizeFiltro(filtro) == npsFiltroDetratores) {
    return items.where((item) => npsIsDetrator(item.score)).toList();
  }
  return items;
}

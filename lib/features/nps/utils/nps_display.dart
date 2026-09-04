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

List<NpsItem> npsItemsForFiltro(List<NpsItem> items, String? filtro) {
  if (filtro == 'detratores') {
    return items.where((item) => npsIsDetrator(item.score)).toList();
  }
  return items;
}

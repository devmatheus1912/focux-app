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

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/nps/data/nps_repository.dart';
import 'package:focux_app/features/nps/utils/nps_display.dart';

void main() {
  test('classifica e recorta recentes', () {
    expect(npsClassify(9), 'Promotor');
    expect(npsClassify(7), 'Neutro');
    expect(npsIsDetrator(6), isTrue);

    final items = [
      NpsItem(id: 1, score: 10, criadoEm: 'hoje'),
      NpsItem(id: 2, score: 4, criadoEm: 'hoje', alunoId: 8),
      NpsItem(id: 3, score: 8, criadoEm: 'hoje'),
      NpsItem(id: 4, score: 3, criadoEm: 'hoje'),
    ];
    expect(firstNpsDetrator(items)?.id, 2);
    expect(npsRecentPreview(items), hasLength(3));
    expect(npsItemsForFiltro(items, 'detratores').map((e) => e.id), [2, 4]);
    expect(npsComoCalculamos, contains('Promotores'));
    expect(npsComoCalculamos, contains('catálogo'));
  });
}

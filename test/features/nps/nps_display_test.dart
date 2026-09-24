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
    expect(npsNormalizeFiltro(' Detratores '), npsFiltroDetratores);
    expect(npsNormalizeFiltro('todos'), '');
    expect(npsHasAluno(items[1]), isTrue);
    expect(npsHasAluno(items[0]), isFalse);
    expect(npsComoCalculamos, contains('Promotores'));
    expect(npsComoCalculamos, contains('catálogo'));
  });

  test('subtítulo formata data do backend sem ISO cru', () {
    final now = DateTime(2026, 9, 24, 20);
    final hoje = NpsItem(
      id: 1,
      score: 10,
      criadoEm: '2026-09-24T18:39:12.123456',
      comentario: 'Top',
      alunoNome: 'Ana',
    );
    expect(npsItemSubtitle(hoje, now: now), 'Promotor · Ana · hoje às 18:39');

    final antigo = NpsItem(id: 2, score: 5, criadoEm: '2025-12-01T07:05:00');
    expect(npsItemSubtitle(antigo, now: now), 'Detrator · 01/12/2025 às 07:05');

    final invalido = NpsItem(id: 3, score: 8, criadoEm: '');
    expect(npsItemSubtitle(invalido, now: now), 'Neutro');
  });
}

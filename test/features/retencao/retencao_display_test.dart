import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/retencao/data/retencao_repository.dart';
import 'package:focux_app/features/retencao/utils/retencao_display.dart';

void main() {
  test('home agregado e risco alto primeiro', () {
    final home = RetencaoHome.fromJson({
      'alto': 2,
      'medio': 1,
      'saudavel': 4,
      'fetchedAt': '2026-09-03T22:00:00Z',
      'top3': [
        {
          'alunoId': 9,
          'alunoNome': 'Ana',
          'scoreAtual': 22,
          'delta': 4,
          'riscoChurn': 'ALTO',
        },
      ],
    });
    expect(home.alto, 2);
    expect(home.top3.single.alunoNome, 'Ana');
    expect(firstAltoRetencao(home.top3)?.alunoId, 9);
    expect(retencaoRiscoLabel('MEDIO'), 'Risco médio');
    expect(retencaoPorque(home.top3.single), contains('subiu 4 pts'));
    expect(retencaoItemsForFiltro(home.top3, 'alto').single.alunoId, 9);
    expect(retencaoEmptyTitle, contains('leitura'));
    expect(retencaoComoCalculamos, contains('catálogo'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/depoimentos/utils/depoimento_display.dart';

void main() {
  test('depoimentoCountLabel e filtro', () {
    expect(depoimentoCountLabel(0), 'Nenhum depoimento');
    expect(depoimentoCountLabel(1), '1 depoimento');
    expect(depoimentoCountLabel(3), '3 depoimentos');
    expect(depoimentoChipLabel(DepoimentoChip.pendentes), 'Pendentes');
    expect(depoimentoNotaLabel(5), '5/5');
    expect(depoimentoNotaLabel(0), '1/5');
    expect(depoimentoNotaLabel(9), '5/5');
    expect(
      depoimentoMatches(
        nomeAluno: 'Ana',
        texto: 'Curti o treino',
        aprovado: false,
        query: 'ana',
        chip: DepoimentoChip.pendentes,
      ),
      isTrue,
    );
    expect(
      depoimentoMatches(
        nomeAluno: 'Ana',
        texto: 'Curti o treino',
        aprovado: true,
        query: '',
        chip: DepoimentoChip.pendentes,
      ),
      isFalse,
    );
  });
}

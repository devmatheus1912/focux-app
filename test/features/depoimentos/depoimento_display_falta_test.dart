import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/depoimentos/utils/depoimento_display.dart';

void main() {
  test('nota começa vazia e o motivo do botão desligado aparece', () {
    expect(depoimentoNotaLabel(0), 'Toque para dar uma nota');
    expect(depoimentoNotaLabel(5), '5 · Excelente');
    expect(depoimentoFalta(nota: 0, texto: 'muito bom mesmo'), 'Escolha uma nota');
    expect(depoimentoFalta(nota: 5, texto: 'bom'), 'Escreva pelo menos 10 letras (faltam 7)');
    expect(depoimentoFalta(nota: 5, texto: 'excelente acompanhamento'), isNull);
  });
}

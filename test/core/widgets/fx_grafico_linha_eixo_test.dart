import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_grafico_linha.dart';

void main() {
  test('marcas do eixo Y saem redondas', () {
    final cintura = FxGraficoLinha.eixoY(30, 70); // com o alvo de 30 cm
    expect(cintura.passo, 20);
    expect(cintura.min, 20);
    expect(cintura.max, 80);

    final peso = FxGraficoLinha.eixoY(90, 110);
    expect(peso.passo % 5, 0);
    expect(peso.min <= 90 && peso.max >= 110, isTrue);
  });

  test('valor único ainda ganha uma faixa', () {
    final e = FxGraficoLinha.eixoY(20, 20);
    expect(e.min < 20 && e.max > 20, isTrue);
  });
}

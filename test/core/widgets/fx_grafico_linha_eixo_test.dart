import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_grafico_linha.dart';

void main() {
  test('marcas do eixo Y saem redondas', () {
    final cintura = FxGraficoLinha.eixoY(30, 70); // com o alvo de 30 cm
    expect(cintura.passo, 25);
    expect(cintura.min, 25);
    expect(cintura.max, 75);

    final peso = FxGraficoLinha.eixoY(90, 110);
    expect(peso.passo % 5, 0);
    expect(peso.min <= 90 && peso.max >= 110, isTrue);
  });

  test('o eixo cobre o menor e o maior valor com passo redondo', () {
    // Print de 13/11: peso de ~105 a 150 só mostrava 120 e 140.
    final e = FxGraficoLinha.eixoY(105, 150);
    expect(e.min <= 105 && e.max >= 150, isTrue);
    expect(e.min, 100);
    expect([10, 20, 25, 50].contains(e.passo), isTrue);
    expect(((e.max - e.min) / e.passo).round(), lessThanOrEqualTo(3));
  });

  test('valor único ainda ganha uma faixa', () {
    final e = FxGraficoLinha.eixoY(20, 20);
    expect(e.min < 20 && e.max > 20, isTrue);
  });
}

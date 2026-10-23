import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/prescricao_serie.dart';

void main() {
  test('sem memória nascem quatro séries válidas', () {
    final series = seriesIniciais();
    expect(series, hasLength(4));
    expect(series.every((s) => s.papel == 'VALIDA'), isTrue);
    expect(series.first.repeticoes, '8-12');
    expect(resumoSeries(series), '4 × 8-12 · 75s');
  });

  test('memória do exercício ganha da global', () {
    final series = seriesIniciais(
      desteExercicio: const [
        SeriePrescrita(numero: 1, repeticoes: '5', papel: 'AQUECIMENTO', cargaKg: 20),
        SeriePrescrita(numero: 2, repeticoes: '5', cargaKg: 60),
      ],
      ultimaGlobal: const [
        SeriePrescrita(numero: 1, repeticoes: '12'),
      ],
    );
    expect(series, hasLength(2));
    expect(series.first.cargaKg, 20);
    expect(resumoSeries(series, descansoSegundos: 150), '1 aquecimento · 1 × 5 · 150s');
  });

  test('duas de aquecimento e quatro válidas', () {
    final series = [
      for (var n = 1; n <= 2; n++)
        SeriePrescrita(numero: n, repeticoes: '10', cargaKg: 20, papel: 'AQUECIMENTO'),
      for (var n = 3; n <= 6; n++)
        SeriePrescrita(numero: n, repeticoes: '8-12', cargaKg: 60),
    ];
    expect(resumoSeries(series), '2 aquecimento · 4 × 8-12 · 75s');
  });
}

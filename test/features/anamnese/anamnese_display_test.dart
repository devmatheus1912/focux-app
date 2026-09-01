import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/anamnese/utils/anamnese_display.dart';

void main() {
  test('anamneseNivelLabel e nulo', () {
    expect(anamneseNivelLabel('SEDENTARIO'), 'Sedentário');
    expect(anamneseNivelLabel('MUITO_INTENSO'), 'Muito intenso');
    expect(anamneseNivelLabel(null), 'Selecionar');
    expect(anamneseNivelOuNulo('LEVE'), 'LEVE');
    expect(anamneseNivelOuNulo('x'), isNull);
  });

  test('anamneseDisponibilidade', () {
    expect(anamneseDisponibilidadeLabel(1), '1 dia por semana');
    expect(anamneseDisponibilidadeLabel(3), '3 dias por semana');
    expect(anamneseDisponibilidadeClamp(null), 3);
    expect(anamneseDisponibilidadeClamp(0), 1);
    expect(anamneseDisponibilidadeClamp(9), 7);
  });
}

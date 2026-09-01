import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dunning/utils/dunning_ops_display.dart';

void main() {
  test('dunningContextoLabel', () {
    expect(dunningContextoLabel('ALUNO_MENSALIDADE'), 'Mensalidade');
    expect(dunningContextoLabel('FOCUX_SUBSCRIPTION'), 'Assinatura Focux');
    expect(dunningContextoLabel(''), 'Pagamento');
    expect(dunningContextoLabel('OUTRO'), 'OUTRO');
  });

  test('dunningFalhaSubtitle e tentativa', () {
    expect(dunningTentativaLabel(0), 'Ainda sem retentativa');
    expect(dunningTentativaLabel(1), 'Tentativa 1');
    expect(dunningTentativaLabel(3), 'Tentativa 3');
    expect(
      dunningFalhaSubtitle('Cartao recusado', 1),
      'Cartao recusado · Tentativa 1',
    );
    expect(dunningFalhaSubtitle('  ', 2), 'Tentativa 2');
  });

  test('dunningTaxaFraca e recuperadas', () {
    expect(dunningTaxaFraca(0, 0), isFalse);
    expect(dunningTaxaFraca(49.9, 10), isTrue);
    expect(dunningTaxaFraca(50, 10), isFalse);
    expect(dunningRecuperadasLabel(7, 10), '7 de 10');
    expect(dunningRateLabel(70), '70.0%');
  });
}

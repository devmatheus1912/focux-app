import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/pacotes/utils/pacote_display.dart';

void main() {
  test('pacoteDuracaoLabel', () {
    expect(pacoteDuracaoLabel(1), '1 mês');
    expect(pacoteDuracaoLabel(0), '1 mês');
    expect(pacoteDuracaoLabel(12), '12 meses');
    expect(pacoteDuracaoMesesValues, [1, 3, 6, 12]);
  });

  test('pacoteIncluiValue', () {
    expect(pacoteIncluiValue(true), 'Sim');
    expect(pacoteIncluiValue(false), 'Não');
  });
}

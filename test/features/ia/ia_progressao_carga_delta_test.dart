import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/ia_progressao_carga_delta.dart';

void main() {
  test('computeProgressaoDeltaLabel returns +2,5 kg for Supino', () {
    expect(
      computeProgressaoDeltaLabel('80kg 3x8', '82,5kg 3x8'),
      '+2,5 kg',
    );
  });

  test('computeProgressaoDeltaLabel usa volume quando não há kg', () {
    expect(
      computeProgressaoDeltaLabel('Desconhecida 4x15', '60kg 4x12'),
      '4x15 → 4x12',
    );
  });

  test('computeProgressaoDeltaLabel returns null when equal', () {
    expect(
      computeProgressaoDeltaLabel('80kg', '80kg'),
      isNull,
    );
  });
}

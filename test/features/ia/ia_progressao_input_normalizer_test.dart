import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/utils/ia_progressao_input_normalizer.dart';

void main() {
  test('normalizeHistorico fixes Supni typo and 3-15 format', () {
    expect(
      normalizeIaProgressaoHistorico('Supni 80kg 3-15'),
      'Supino 80kg 3x15',
    );
  });

  test('normalizeObjetivo capitalizes first letter', () {
    expect(normalizeIaProgressaoObjetivo('hipertrofia'), 'Hipertrofia');
  });

  test('detects when historico was normalized', () {
    expect(
      iaProgressaoHistoricoWasNormalized(
        'Supni 80kg 3-15',
        normalizeIaProgressaoHistorico('Supni 80kg 3-15'),
      ),
      isTrue,
    );
  });
}

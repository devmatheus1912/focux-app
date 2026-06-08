import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/altura_display.dart';

void main() {
  group('normalizeAlturaMeters', () {
    test('mantém valor já em metros', () {
      expect(normalizeAlturaMeters(1.75), 1.75);
      expect(normalizeAlturaMeters(2.1), 2.1);
    });

    test('converte cm para metros quando > 3', () {
      expect(normalizeAlturaMeters(190), closeTo(1.9, 0.001));
      expect(normalizeAlturaMeters(175), closeTo(1.75, 0.001));
    });
  });

  group('formatAlturaDisplay', () {
    test('retorna placeholder quando nulo', () {
      final display = formatAlturaDisplay(null);
      expect(display.value, '—');
      expect(display.unit, 'm');
    });

    test('formata metros corretos', () {
      final display = formatAlturaDisplay(1.75);
      expect(display.value, '1.75');
      expect(display.unit, 'm');
    });

    test('corrige valor salvo em cm', () {
      final display = formatAlturaDisplay(190);
      expect(display.value, '1.90');
      expect(display.unit, 'm');
    });
  });
}

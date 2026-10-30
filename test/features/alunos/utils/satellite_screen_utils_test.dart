import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/utils/satellite_screen_utils.dart';

void main() {
  group('financeiroMensalidadeStatusLabel', () {
    test('localizes API enums', () {
      expect(financeiroMensalidadeStatusLabel('PAGO'), 'Pago');
      expect(financeiroMensalidadeStatusLabel('PENDENTE'), 'Pendente');
      expect(financeiroMensalidadeStatusLabel('ATRASADO'), 'Atrasado');
    });
  });

  group('satelliteFirstName', () {
    test('returns first token', () {
      expect(satelliteFirstName('Beatriz Costa'), 'Beatriz');
    });
  });

  group('financeiroMensalidadeStatusInk', () {
  });
}

import 'package:flutter/material.dart';
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
    test('darkens Pago on light theme', () {
      final ink = financeiroMensalidadeStatusInk(
        Colors.green,
        status: 'PAGO',
        isDark: false,
      );
      expect(ink, const Color(0xFF14532D));
    });
  });
}

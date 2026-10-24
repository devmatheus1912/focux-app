import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _arquivos = [
  'fx_choice_chip',
  'fx_choice_strip',
  'fx_tap_row',
  'fx_day_row',
  'fx_status_pill',
  'fx_sticky_actions',
  'fx_action_sheet',
];

void main() {
  for (final nome in _arquivos) {
    test('$nome cumpre o contrato do kit da ficha', () {
      final fonte = File('lib/core/widgets/$nome.dart').readAsStringSync();
      final linhas = fonte.split('\n').length;

      expect(linhas, lessThan(150), reason: 'arquivos do kit têm menos de 150 linhas');
      expect(fonte, isNot(contains('Color(0x')), reason: 'sem cor literal');
      expect(fonte, isNot(contains('fontSize:')), reason: 'sem fonte literal');
      expect(
        RegExp(r"Text\(\s*'[^'$]").hasMatch(fonte),
        isFalse,
        reason: 'sem texto fixo: o rótulo vem por parâmetro',
      );
    });
  }
}

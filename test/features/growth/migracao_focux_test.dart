import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migracao focux usa polish 10/10 e copy alinhada', () {
    final screen = File(
      'lib/features/growth/screens/migracao_magica_screen.dart',
    ).readAsStringSync();

    expect(screen, contains('Migração Focux'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxStaggerItem'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('Colar da área de transferência'));
    expect(screen, contains('Nenhum aluno identificado'));
    expect(screen, isNot(contains('Migração Mágica')));
    expect(screen, isNot(contains('Cole PDF, Excel')));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editar aluno usa polish 10/10: cards, a11y e sticky save', () {
    final screen = File(
      'lib/features/alunos/screens/editar_aluno_screen.dart',
    ).readAsStringSync();

    expect(screen, contains("subtitle: 'ALUNO'"));
    expect(screen, contains("loadingLabel: 'Salvando…'"));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('invalidateAluno360Providers'));
    expect(screen, contains('ListenableBuilder'));
    expect(screen, contains('Salvando alterações do aluno'));
    expect(screen, isNot(contains('ElevatedButton')));
  });
}

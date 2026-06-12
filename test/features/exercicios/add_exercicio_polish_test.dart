import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('novo exercicio biblioteca polish', () {
    final screen =
        File(
          'lib/features/exercicios/screens/add_exercicio_screen.dart',
        ).readAsStringSync();

    expect(screen, contains("'Novo exercício'"));
    expect(screen, contains('Erro ao cadastrar exercício.'));
    expect(screen, contains('Novo exercício'));
    expect(screen, contains('Semantics('));
    expect(screen, contains('Cadastrar exercício'));
    expect(screen, contains('Perfil rápido'));
    expect(screen, contains('selectedColor: primary'));
    expect(screen, contains('Colors.white'));
    expect(screen, contains('Fechar seletor'));
    expect(screen, isNot(contains('DropdownButtonFormField')));

    final semanticsCount = 'Semantics('.allMatches(screen).length;
    expect(semanticsCount, greaterThanOrEqualTo(8));
  });
}

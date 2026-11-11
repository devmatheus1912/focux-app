import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Evolução devolve se a medida foi revisada (Copiloto marca sozinho)', () {
    final src = File(
      'lib/features/evolucao/screens/evolucao_screen.dart',
    ).readAsStringSync();
    // Sai sempre pelo mesmo lugar, com o resultado.
    expect(src, contains('result: _revisou'));
    expect(src, isNot(contains("safePopOrGo(context, '/alunos/\${widget.alunoId}')")));
    // Conferir, registrar, editar e excluir medida marcam a revisão.
    expect('_revisou = true'.allMatches(src).length, greaterThanOrEqualTo(4));
  });
}

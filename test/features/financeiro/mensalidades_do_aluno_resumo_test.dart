import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resumo de um aluno soma todas as cobranças, não só as carregadas', () {
    final tab = File(
      'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
    ).readAsStringSync();
    final aluno = File(
      'lib/features/financeiro/screens/financeiro_mensalidades_tab_aluno.part.dart',
    ).readAsStringSync();
    expect(tab, contains('listarPorAluno(alunoId'));
    // Com a lista completa, sem o aviso "nas cobranças carregadas".
    expect(aluno, contains('parcial: todas == null && _hasMore'));
  });
}

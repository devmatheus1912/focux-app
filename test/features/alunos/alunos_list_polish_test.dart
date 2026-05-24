import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('alunos list usa microcopy, chips de status e scroll peek 10/10', () {
    final screen =
        File(
          'lib/features/alunos/screens/alunos_list_screen.dart',
        ).readAsStringSync();

    expect(screen, contains('_alunosSelectionTitle'));
    expect(screen, contains('_mensalidadesPagasMessage'));
    expect(screen, contains('_HorizontalScrollPeek'));
    expect(screen, contains('Deslize horizontalmente para ver mais filtros'));
    expect(screen, contains("statusText = 'Risco alto'"));
    expect(screen, contains("statusText = 'Inadimplente'"));
    expect(screen, contains("label: 'Ativo'"));
    expect(screen, contains("label: 'Inativo'"));
    expect(screen, contains("label: 'Bloqueado'"));
    expect(screen, contains('_SheetShortcutChip'));
    expect(screen, contains('isScrollControlled: true'));
    expect(screen, contains('useSafeArea: true'));
    expect(screen, contains('SingleChildScrollView'));
    expect(screen, isNot(contains('aluno(s) selecionado(s)')));
    expect(screen, isNot(contains('DropdownButtonFormField')));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _alunosListLibrarySource() {
  const dir = 'lib/features/alunos/screens';
  const mainFile = '$dir/alunos_list_screen.dart';
  final main = File(mainFile).readAsStringSync();
  final partPattern = RegExp(r"part '([^']+\.part\.dart)';");
  final parts = partPattern
      .allMatches(main)
      .map((m) => File('$dir/${m.group(1)!}').readAsStringSync())
      .join('\n');
  return '$main\n$parts';
}

void main() {
  test('alunos list usa microcopy, chips de status e scroll peek', () {
    final screen = _alunosListLibrarySource();

    expect(screen, contains('alunosSelectionTitle'));
    expect(screen, contains('mensalidadesPagasMessage'));
    expect(screen, contains('FxHorizontalScrollPeek'));
    expect(screen, contains('fx_horizontal_scroll_peek.dart'));
    expect(screen, contains("statusText = 'Risco alto'"));
    expect(screen, contains("statusText = 'Inadimplente'"));
    expect(screen, contains("label: 'Ativo'"));
    expect(screen, contains("label: 'Inativo'"));
    expect(screen, contains("label: 'Bloqueado'"));
    expect(screen, contains('_SheetShortcutChip'));
    expect(screen, contains('Lista compacta'));
    expect(screen, contains('AlunoListPreferencesStore'));
    expect(screen, contains('maskEmailForList'));
    expect(screen, contains('alunoRiscoAltoBadgeColors'));
    expect(screen, contains('alunoListSecondaryInk'));
    expect(screen, contains('AlunosLayout'));
    expect(screen, contains('_AlunoStatusPill'));
    expect(screen, contains("part 'alunos_list_screen_state.part.dart'"));
    expect(screen, contains("part 'alunos_list_screen_filters.part.dart'"));
    expect(screen, contains("part 'alunos_list_screen_header.part.dart'"));
    expect(screen, contains("part 'alunos_list_screen_body.part.dart'"));
    expect(screen, contains("part 'alunos_list_screen_cards.part.dart'"));
    expect(screen, contains("part 'alunos_list_screen_aluno_card.part.dart'"));
    expect(screen, isNot(contains("aluno.email.toLowerCase()")));
    expect(screen, contains('isScrollControlled: true'));
    expect(screen, contains('useSafeArea: true'));
    expect(screen, contains('SingleChildScrollView'));
    expect(screen, isNot(contains('aluno(s) selecionado(s)')));
    expect(screen, isNot(contains('DropdownButtonFormField')));
    expect(screen, contains('home.alertasConfig'));
    expect(screen, isNot(contains('alertasConfigProvider')));
  });
}

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
    expect(screen, contains('AlunoListCard'));
    expect(screen, contains('aluno_list_card.dart'));
    expect(screen, contains("label: 'Ativo'"));
    expect(screen, contains("label: 'Inativo'"));
    expect(screen, contains("label: 'Bloqueado'"));
    expect(screen, contains('_SheetShortcutChip'));
    expect(screen, contains('Lista compacta'));
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, contains('FxHomeSheetSurface'));
    expect(screen, contains('FxHomeSheetHeader'));
    expect(screen, isNot(contains('Atalhos de foco')));
    expect(screen, contains('showAlunosBulkPayCta'));
    expect(screen, contains('ListenableBuilder'));
    expect(screen, isNot(contains('_searchFocusNode.addListener')));
    expect(screen, contains('AlunoListPreferencesStore'));
    expect(
      screen,
      anyOf(contains('maskEmailForList'), contains('AlunoListCard')),
    );
    expect(
      screen,
      anyOf(contains('alunoListSecondaryInk'), contains('AlunoListCard')),
    );
    expect(screen, contains('AlunosLoadingScaffold'));
    expect(screen, contains('AlunosErrorScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('ProductEvents.alunosViewed'));
    expect(screen, contains("part 'alunos_list_screen_state.part.dart'"));
    expect(screen, contains("part 'alunos_list_screen_filters.part.dart'"));
    expect(screen, contains("part 'alunos_list_screen_header.part.dart'"));
    expect(screen, contains("part 'alunos_list_screen_body.part.dart'"));
    expect(screen, contains("part 'alunos_list_screen_cards.part.dart'"));
    expect(
      screen,
      isNot(contains("part 'alunos_list_screen_aluno_card.part.dart'")),
    );
    expect(screen, isNot(contains("aluno.email.toLowerCase()")));
    expect(screen, contains('SingleChildScrollView'));
    expect(screen, isNot(contains('aluno(s) selecionado(s)')));
    expect(screen, isNot(contains('DropdownButtonFormField')));
    expect(screen, contains('home.alertasConfig'));
    expect(screen, isNot(contains('alertasConfigProvider')));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, isNot(contains('ShellThemeToggle')));
    expect(screen, contains('showAlunosListHelpSheet'));
    expect(
      File(
        'lib/features/alunos/widgets/alunos_list_help_sheet.dart',
      ).readAsStringSync(),
      allOf(contains('showFxHelpSheet'), isNot(contains('Entendi'))),
    );
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('"Abrir Copiloto" da Evolução abre a folha, não troca de aba', () {
    final tela = readScreenSourceBundle(
      'lib/features/alunos/screens/aluno_detail_screen.dart',
    );
    expect(tela, isNot(contains('onOpenCopilot:\n                                        () => _tabController.animateTo(0)')));
    expect(tela, contains('abrirCopiloto360('));
    final resumo =
        File('lib/features/alunos/widgets/aluno360_resumo_tab.dart')
            .readAsStringSync();
    expect(resumo, contains('abrirCopiloto360('));
  });

  test('tarefa já aberta: aviso com "Ver", sem posição presa no topo', () {
    final src =
        File('lib/features/alunos/utils/aluno360_copilot_task_actions.dart')
            .readAsStringSync();
    expect(src, contains("actionLabel: 'Ver'"));
    expect(src, isNot(contains('operacaoTop')));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('o Copiloto do 360 abre só pelo Resumo; a Evolução mostra dado', () {
    final tela = readScreenSourceBundle(
      'lib/features/alunos/screens/aluno_detail_screen.dart',
    );
    expect(tela, isNot(contains('onOpenCopilot')));
    expect(tela, isNot(contains('abrirCopiloto360(')));
    final evolucao = File(
      'lib/features/alunos/widgets/aluno360_evolucao_inteligente_card.dart',
    ).readAsStringSync();
    expect(evolucao, isNot(contains('Abrir Copiloto')));
    expect(evolucao, isNot(contains('Sugestão:')));
    final resumo = File(
      'lib/features/alunos/widgets/aluno360_resumo_tab.dart',
    ).readAsStringSync();
    expect(resumo, contains('abrirCopiloto360('));
  });

  test('tarefa já aberta: aviso com "Ver", sem posição presa no topo', () {
    final src = File(
      'lib/features/alunos/utils/aluno360_copilot_task_actions.dart',
    ).readAsStringSync();
    expect(src, contains("actionLabel: 'Ver'"));
    expect(src, isNot(contains('operacaoTop')));
  });

  test('folha sem sugestão não abre vazia', () {
    final src = File(
      'lib/features/alunos/widgets/aluno360_copilot_folha.dart',
    ).readAsStringSync();
    expect(src, contains("context.push('/ia/copiloto')"));
  });
}

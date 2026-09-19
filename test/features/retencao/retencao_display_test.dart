import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/retencao/data/retencao_repository.dart';
import 'package:focux_app/features/retencao/utils/retencao_display.dart';

void main() {
  test('placeholder Aluno names are filtered from lists', () {
    final scores = [
      RetencaoAlunoScore(
        alunoId: 1,
        alunoNome: 'Nathalia',
        riscoChurn: 'ALTO',
        scoreAtual: 20,
        delta: -5,
      ),
      RetencaoAlunoScore(
        alunoId: 2,
        alunoNome: 'Aluno',
        riscoChurn: 'ALTO',
        scoreAtual: 10,
        delta: 0,
      ),
    ];
    expect(retencaoNomeExibivel('Nathalia'), isTrue);
    expect(retencaoNomeExibivel('Aluno'), isFalse);
    expect(retencaoItemsForFiltro(scores, null).single.alunoNome, 'Nathalia');
    expect(firstAltoRetencao(scores)?.alunoNome, 'Nathalia');
    expect(
      retencaoContagensSubtitulo(
        alto: 1,
        medio: 0,
        saudavel: 0,
        topNomeados: 1,
      ),
      '0 médios · 0 saudáveis',
    );
    expect(
      retencaoContagensSubtitulo(
        alto: 1,
        medio: 0,
        saudavel: 0,
        topNomeados: 0,
      ),
      contains('atualize a base'),
    );
    expect(retencaoComoCalculamos, contains('ATIVOS'));
    expect(retencaoComoCalculamos, contains('dias únicos'));
    expect(retencaoEmptySubtitle, contains('dias únicos'));
    expect(retencaoMetricAltoLabel(1), '1 alto');
    expect(retencaoMetricMedioLabel(2), '2 médios');
  });

  test('retencaoFocusActions and hub links stay A30-shaped', () {
    final hot = retencaoFocusActions(hasAlto: true);
    expect(hot.primary, RetencaoFocusActionId.chat);
    expect(hot.secondary, [
      RetencaoFocusActionId.cobrar,
      RetencaoFocusActionId.aluno360,
    ]);
    final cold = retencaoFocusActions(hasAlto: false);
    expect(cold.primary, RetencaoFocusActionId.verAlunos);
    expect(cold.secondary, isEmpty);
    expect(retencaoHubLinks, hasLength(2));
    expect(retencaoHubLinkRoute(RetencaoHubLinkId.winback), '/winback');
    expect(retencaoHubLinkLabel(RetencaoHubLinkId.dunning), 'Cobrança auto');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ranking/utils/ranking_display.dart';

void main() {
  test('ranking labels', () {
    expect(rankingCountLabel(0), 'Nenhum personal');
    expect(rankingCountLabel(1), '1 personal');
    expect(rankingCountLabel(4), '4 personais');
    expect(rankingAlunosLabel(1), '1 aluno ativo');
    expect(rankingAlunosLabel(3), '3 alunos ativos');
    expect(rankingPosicaoLabel(1), '1º');
    expect(rankingComoCalculamos, contains('alunos ativos'));
    expect(rankingSearchEmptyTitle(''), 'Ranking ainda sem dados');
    expect(rankingSearchEmptyTitle('ana'), 'Nenhum personal encontrado');
    expect(rankingSearchEmptySubtitle('ana'), contains('nome'));
  });
}

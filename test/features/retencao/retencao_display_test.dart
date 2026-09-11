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
  });
}

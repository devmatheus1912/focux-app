import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_core_models.dart';
import 'package:focux_app/features/alunos/utils/alunos_list_utils.dart';

AlunosStats _stats({required int total, int? inativos}) => AlunosStats(
  total: total,
  totalAtivos: total - (inativos ?? 0),
  totalInadimplentes: 0,
  totalRiscoAlto: 0,
  totalConvites: 0,
  totalInativos: inativos,
);

void main() {
  test('vaga conta só aluno ativo', () {
    expect(_stats(total: 5, inativos: 3).totalOcupandoVaga, 2);
    expect(_stats(total: 3).totalOcupandoVaga, 3);
    expect(_stats(total: 2, inativos: 9).totalOcupandoVaga, 0);
  });

  test('Free com 3 ativos esgota; inativos liberam vaga', () {
    expect(
      alunoVagasEsgotadas(limiteAlunos: 3, stats: _stats(total: 3)),
      isTrue,
    );
    expect(
      alunoVagasEsgotadas(
        limiteAlunos: 3,
        stats: _stats(total: 5, inativos: 3),
      ),
      isFalse,
    );
  });

  test('sem limite ou sem stats não bloqueia', () {
    expect(
      alunoVagasEsgotadas(limiteAlunos: null, stats: _stats(total: 99)),
      isFalse,
    );
    expect(alunoVagasEsgotadas(limiteAlunos: 3, stats: null), isFalse);
  });
}

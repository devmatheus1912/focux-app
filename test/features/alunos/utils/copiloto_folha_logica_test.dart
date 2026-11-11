import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/utils/aluno360_copilot_logic.dart';
import 'package:focux_app/features/alunos/utils/aluno360_operacao_logic.dart';

void main() {
  test('o botão combina com o tipo da sugestão', () {
    expect(
      copilotoAcaoDaSugestao('CARGA')?.destination,
      OperacaoStickyDestination.progressao,
    );
    expect(copilotoAcaoDaSugestao('CARGA')?.label, 'Ajustar cargas');
    expect(
      copilotoAcaoDaSugestao('MEDIDA')?.destination,
      OperacaoStickyDestination.evolucao,
    );
    // Sem tipo próprio: a folha oferece "Criar tarefa".
    expect(copilotoAcaoDaSugestao(null), isNull);
    expect(copilotoAcaoDaSugestao('RECUPERACAO'), isNull);
  });

  test('"Por quê": números do app, e do motivo só o que é outra coisa', () {
    final aluno = Aluno(
      id: 1,
      nome: 'Julio',
      email: '',
      status: 'ATIVO',
      aderenciaPercent: 64,
      diasSemTreino: 2,
    );
    final fatos = copilotoFatos(
      aluno,
      motivo: '2 dias parados · aderência 64% · medida fora do esperado',
    );
    expect(fatos, [
      'Aderência em 64% do previsto',
      'Último treino há 2 dias',
      'Medida fora do esperado',
    ]);
  });
}

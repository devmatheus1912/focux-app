import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/widgets/evolucao_resumo.dart';
import 'package:focux_app/features/onboarding/data/setup_steps_catalog.dart';

void main() {
  test('resumo do aluno: a meta quando existe', () {
    final texto = evolucaoResumoDoAluno(
      const EvolucaoAneis(metaProgresso: 40, ultimaMedida: '2026-11-10'),
      metaNome: 'Cintura',
    );
    expect(texto, contains('40%'));
    expect(texto, contains('Cintura'));
  });

  test('resumo do aluno sem meta: a próxima medida, nunca "Sem meta"', () {
    final texto = evolucaoResumoDoAluno(
      const EvolucaoAneis(ultimaMedida: '2026-11-10'),
    );
    expect(texto, startsWith('Medidas'));
    expect(texto, isNot(contains('Sem meta')));
  });

  test('nomes juntos com vírgula e "e"', () {
    expect(juntarNomes(const []), '');
    expect(juntarNomes(const ['Hábitos']), 'Hábitos');
    expect(juntarNomes(const ['Hábitos', 'Desafios']), 'Hábitos e Desafios');
    expect(
      juntarNomes(const ['Hábitos', 'Desafios', 'Financeiro']),
      'Hábitos, Desafios e Financeiro',
    );
  });
}

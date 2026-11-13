import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/desafios/data/desafio_repository.dart';
import 'package:focux_app/features/desafios/utils/desafio_display.dart';

void main() {
  final hoje = DateTime(2026, 11, 11);

  test('unidade real no lugar de pontos', () {
    expect(desafioUnidade('TREINOS', 12), '12 treinos');
    expect(desafioUnidade('TREINOS', 1), '1 treino');
    expect(desafioUnidade('HABITOS', 20), '20 hábitos marcados');
    expect(desafioTipoLabel('TREINOS'), 'Treinos concluídos');
    expect(desafioRegraFrase('HABITOS'), 'Cada hábito marcado conta 1.');
  });

  test('linha da lista diz a regra numa frase', () {
    final d = Desafio(
      id: 1,
      titulo: 'Quem treinar mais',
      tipo: 'TREINOS',
      metaPontos: 12,
      fim: DateTime(2026, 11, 29),
    );
    expect(
      desafioLinhaLista(d, now: hoje),
      // Meta com unidade (SPEC 12/11).
      'Treinos concluídos · meta 12 treinos · faltam 18 dias',
    );
  });

  test('líder só com contagem', () {
    const com = Desafio(
      id: 1,
      titulo: 'x',
      tipo: 'TREINOS',
      metaPontos: 12,
      liderNome: 'Julio Souza',
      liderContagem: 7,
    );
    const sem = Desafio(id: 2, titulo: 'y', tipo: 'TREINOS', metaPontos: 12);
    expect(desafioLiderLabel(com), 'Julio lidera com 7');
    expect(desafioLiderLabel(sem), isNull);
  });

  test('aluno vê a própria contagem e a posição; líder só quando não é ele', () {
    const segundo = Desafio(
      id: 1,
      titulo: 'x',
      tipo: 'TREINOS',
      metaPontos: 5,
      liderNome: 'Julio Souza',
      liderContagem: 3,
      minhaContagem: 1,
      minhaPosicao: 2,
    );
    const lider = Desafio(
      id: 2,
      titulo: 'y',
      tipo: 'TREINOS',
      metaPontos: 5,
      liderNome: 'Ana',
      liderContagem: 1,
      minhaContagem: 1,
      minhaPosicao: 1,
    );
    const zerado = Desafio(
      id: 3,
      titulo: 'z',
      tipo: 'HABITOS',
      metaPontos: 10,
      minhaContagem: 0,
    );
    expect(
      desafioLinhaAluno(segundo),
      'Você: 1 de 5 treinos · 2º lugar · Julio lidera com 3',
    );
    expect(desafioLinhaAluno(lider), 'Você: 1 de 5 treinos · 1º lugar');
    expect(desafioLinhaAluno(zerado), 'Você: 0 de 10 hábitos marcados');
  });

  test('prazo por extenso', () {
    expect(desafioFaltam(DateTime(2026, 11, 12), now: hoje), 'falta 1 dia');
    expect(desafioFaltam(hoje, now: hoje), 'último dia');
    expect(desafioFaltam(DateTime(2026, 11, 1), now: hoje), 'encerrado');
  });

  test('resumo do aluno com unidade e lugar', () {
    expect(
      desafioMeuResumo(tipo: 'TREINOS', index: 1, contagem: 7, meta: 12),
      'Você tem 7 de 12 treinos · 2º lugar',
    );
    expect(
      desafioMeuResumo(tipo: 'TREINOS', index: 0, contagem: 12, meta: 12),
      'Você tem 12 de 12 treinos · 1º lugar · meta batida',
    );
    expect(
      desafioMeuResumo(tipo: 'HABITOS', index: null, contagem: 0, meta: 20),
      'Você ainda não marcou hábito neste desafio.',
    );
  });

  test('meta sugerida pelo prazo', () {
    expect(desafioMetaSugerida(tipo: 'TREINOS', dias: 30), 13);
    expect(desafioMetaSugerida(tipo: 'TREINOS', dias: 7), 3);
    expect(desafioMetaSugerida(tipo: 'HABITOS', dias: 7, habitosAtivos: 2), 10);
    expect(desafioNomeSugerido(14), 'Desafio de 14 dias');
  });

  test('quem entra e filtros só com mais de 6', () {
    expect(desafioQuemEntra(8), 'Entram todos os seus 8 alunos ativos.');
    expect(desafioMostraFiltros(total: 6, filtrando: false), isFalse);
    expect(desafioMostraFiltros(total: 7, filtrando: false), isTrue);
    expect(desafioMostraFiltros(total: 0, filtrando: true), isTrue);
  });

  test('progresso e fração até a meta', () {
    expect(desafioProgresso(7, 12), '7 de 12');
    expect(desafioFracao(18, 12), 1);
    expect(desafioFracao(0, 0), 0);
  });
}

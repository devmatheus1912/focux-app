import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/retencao/data/retencao_repository.dart';
import 'package:focux_app/features/retencao/utils/retencao_display.dart';
import 'package:focux_app/features/retencao/utils/retencao_fila.dart';

RetencaoAlunoScore _s(int id, String nome, int score, {int delta = 0}) =>
    RetencaoAlunoScore(
      alunoId: id,
      alunoNome: nome,
      scoreAtual: score,
      delta: delta,
      riscoChurn: 'ALTO',
    );

void main() {
  test('nivelDoScore respeita os limites do servidor (39, 40, 69, 70)', () {
    expect(nivelDoScore(0), RetencaoNivel.alto);
    expect(nivelDoScore(39), RetencaoNivel.alto);
    expect(nivelDoScore(40), RetencaoNivel.atencao);
    expect(nivelDoScore(69), RetencaoNivel.atencao);
    expect(nivelDoScore(70), RetencaoNivel.saudavel);
    expect(nivelDoScore(100), RetencaoNivel.saudavel);
  });

  group('filaSemOPrimeiro', () {
    test('vazia, um e vários', () {
      expect(filaSemOPrimeiro(const []), isEmpty);
      expect(filaSemOPrimeiro([_s(1, 'Ana', 10)]), isEmpty);
      final r = filaSemOPrimeiro([_s(1, 'Ana', 10), _s(2, 'Beto', 20)]);
      expect(r.map((e) => e.alunoNome), ['Beto']);
    });
    test('filaSemAluno tira o destaque pelo id, onde ele estiver', () {
      final lista = [_s(1, 'Ana', 10), _s(2, 'Beto', 20), _s(3, 'Cris', 30)];
      expect(filaSemAluno(lista, 2).map((e) => e.alunoId), [1, 3]);
      expect(filaSemAluno(lista, null), hasLength(3));
    });
  });

  group('mostrarFiltros', () {
    test('um grupo só: sem filtros', () {
      expect(
        mostrarFiltros({
          RetencaoNivel.alto: 5,
          RetencaoNivel.atencao: 0,
          RetencaoNivel.saudavel: 0,
        }),
        isFalse,
      );
    });
    test('dois ou três grupos: com filtros', () {
      expect(
        mostrarFiltros({
          RetencaoNivel.alto: 2,
          RetencaoNivel.atencao: 1,
          RetencaoNivel.saudavel: 0,
        }),
        isTrue,
      );
      expect(
        mostrarFiltros({
          RetencaoNivel.alto: 2,
          RetencaoNivel.atencao: 1,
          RetencaoNivel.saudavel: 9,
        }),
        isTrue,
      );
    });
    test('base vazia: sem filtros', () {
      expect(
        mostrarFiltros({
          RetencaoNivel.alto: 0,
          RetencaoNivel.atencao: 0,
          RetencaoNivel.saudavel: 0,
        }),
        isFalse,
      );
    });
  });

  test('retencaoFiltrar tira nomes placeholder e filtra por nível', () {
    final lista = [
      _s(1, 'Ana', 10),
      _s(2, 'Aluno', 5),
      _s(3, 'Beto', 55),
      _s(4, 'Cris', 90),
    ];
    expect(retencaoFiltrar(lista, null).map((e) => e.alunoId), [1, 3, 4]);
    expect(retencaoFiltrar(lista, RetencaoNivel.alto).map((e) => e.alunoId), [
      1,
    ]);
    expect(
      retencaoFiltrar(lista, RetencaoNivel.atencao).map((e) => e.alunoId),
      [3],
    );
    expect(
      retencaoFiltrar(lista, RetencaoNivel.saudavel).map((e) => e.alunoId),
      [4],
    );
  });

  test('chamar agora: o primeiro em risco alto, do servidor ou da base', () {
    final base = [_s(5, 'Eva', 80), _s(6, 'Fábio', 30)];
    expect(retencaoChamarAgora([_s(1, 'Ana', 10)], base)?.alunoId, 1);
    expect(retencaoChamarAgora(const [], base)?.alunoId, 6);
    expect(retencaoChamarAgora(const [], [_s(5, 'Eva', 80)]), isNull);
    expect(retencaoChamarAgora([_s(2, 'Aluno', 5)], const []), isNull);
  });

  test('contagem vem do servidor', () {
    final home = RetencaoHome.fromJson({
      'alto': 5,
      'medio': 2,
      'saudavel': 7,
      'top3': <dynamic>[],
    });
    expect(retencaoContagem(home), {
      RetencaoNivel.alto: 5,
      RetencaoNivel.atencao: 2,
      RetencaoNivel.saudavel: 7,
    });
    expect(
      RetencaoHome.fromJson({
        'alto': 2,
        'altoSemanaAnterior': 1,
      }).altoSemanaAnterior,
      1,
    );
  });

  test('nomes placeholder e texto curto de saúde', () {
    expect(retencaoNomeExibivel('Nathalia'), isTrue);
    expect(retencaoNomeExibivel('Aluno'), isFalse);
    expect(retencaoNomeExibivel('  '), isFalse);
    expect(retencaoSaudeCurta(_s(1, 'Ana', 10)), 'Saúde 10 de 100');
  });
}

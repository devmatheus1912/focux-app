import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/utils/treino_blocos.dart';

Exercicio _ex(int id) => Exercicio.fromJson({'id': id, 'nome': 'Ex $id'});

TreinoExercicioItem _it(
  int id,
  String bloco,
  int ordem, {
  int series = 3,
  int? descanso = 60,
}) => TreinoExercicioItem(
  id: id,
  exercicio: _ex(id),
  series: series,
  repeticoes: '10',
  ordem: ordem,
  bloco: bloco,
  descansoSegundos: descanso,
);

String _forma(List<LinhaTreino> l) => [
  for (final x in l)
    switch (x) {
      LinhaSecao(:final bloco) => '[$bloco]',
      LinhaItem(:final item) => '${item.id}',
    },
].join(' ');

void main() {
  group('linhasDoTreino', () {
    test('as três seções aparecem mesmo vazias', () {
      expect(
        _forma(linhasDoTreino(const [])),
        '[AQUECIMENTO] [TRABALHO] [ALONGAMENTO]',
      );
    });

    test('vários exercícios por bloco, na ordem global', () {
      final l = linhasDoTreino([
        _it(1, 'AQUECIMENTO', 0),
        _it(2, 'AQUECIMENTO', 1),
        _it(3, 'AQUECIMENTO', 2),
        _it(4, 'TRABALHO', 3),
        _it(5, 'ALONGAMENTO', 4),
        _it(6, 'ALONGAMENTO', 5),
      ]);
      expect(_forma(l), '[AQUECIMENTO] 1 2 3 [TRABALHO] 4 [ALONGAMENTO] 5 6');
    });

    test('AJUSTE legado só aparece com exercício', () {
      expect(
        _forma(linhasDoTreino([_it(1, 'AJUSTE', 0)])),
        '[AQUECIMENTO] [TRABALHO] [ALONGAMENTO] [AJUSTE] 1',
      );
      expect(
        _forma(linhasDoTreino([_it(1, 'TRABALHO', 0)])).contains('AJUSTE'),
        isFalse,
      );
    });
  });

  group('moverNaLista', () {
    final base = [
      _it(1, 'AQUECIMENTO', 0),
      _it(2, 'TRABALHO', 1),
      _it(3, 'TRABALHO', 2),
      _it(4, 'ALONGAMENTO', 3),
    ];
    // [AQ] 1 [TR] 2 3 [AL] 4  → índices 0..6

    test('dentro do mesmo bloco só reordena', () {
      final m = moverNaLista(linhasDoTreino(base), 3, 4)!;
      expect(m.idsEmOrdem, [1, 3, 2, 4]);
      expect(m.blocoNovo, 'TRABALHO');
      expect(m.mudouDeBloco, isFalse);
    });

    test('de Trabalho para o Aquecimento muda o bloco', () {
      final m = moverNaLista(linhasDoTreino(base), 3, 1)!;
      expect(m.idsEmOrdem, [2, 1, 3, 4]);
      expect(m.blocoNovo, 'AQUECIMENTO');
      expect(m.mudouDeBloco, isTrue);
    });

    test('solto no começo da lista vale a primeira seção', () {
      final m = moverNaLista(linhasDoTreino(base), 6, 0)!;
      expect(m.idsEmOrdem.first, 4);
      expect(m.blocoNovo, 'AQUECIMENTO');
    });

    test('solto logo abaixo do cabeçalho de um bloco vazio', () {
      final l = linhasDoTreino([_it(1, 'TRABALHO', 0), _it(2, 'TRABALHO', 1)]);
      // [AQ] [TR] 1 2 [AL]: o 1 (índice 2) cai depois de [AL] (índice 4)
      final m = moverNaLista(l, 2, 4)!;
      expect(m.blocoNovo, 'ALONGAMENTO');
    });

    test('arrastar cabeçalho não faz nada', () {
      expect(moverNaLista(linhasDoTreino(base), 0, 3), isNull);
    });

    test('nenhum exercício se perde nem duplica', () {
      final linhas = linhasDoTreino(base);
      for (var a = 0; a < linhas.length; a++) {
        for (var b = 0; b < linhas.length; b++) {
          final m = moverNaLista(linhas, a, b);
          if (m == null) continue;
          expect([...m.idsEmOrdem]..sort(), [1, 2, 3, 4], reason: '$a→$b');
        }
      }
    });
  });

  group('moverParaBloco', () {
    test('vai para o fim do bloco escolhido', () {
      final base = [
        _it(1, 'TRABALHO', 0),
        _it(2, 'TRABALHO', 1),
        _it(3, 'ALONGAMENTO', 2),
      ];
      final m = moverParaBloco(base, base[0], 'ALONGAMENTO');
      expect(m.blocoNovo, 'ALONGAMENTO');
      expect(m.idsEmOrdem, [2, 3, 1]);
    });

    test('para um bloco vazio', () {
      final base = [_it(1, 'TRABALHO', 0), _it(2, 'TRABALHO', 1)];
      final m = moverParaBloco(base, base[1], 'AQUECIMENTO');
      expect(m.blocoNovo, 'AQUECIMENTO');
      expect(m.idsEmOrdem, [2, 1]);
    });
  });

  group('duracaoEstimadaMin', () {
    test('vazio é zero', () => expect(duracaoEstimadaMin(const []), 0));

    test('soma séries × (descanso + execução) e arredonda a 5 min', () {
      expect(duracaoEstimadaMin([_it(1, 'TRABALHO', 0)]), 5); // 300 s
      expect(
        duracaoEstimadaMin([
          for (var i = 0; i < 10; i++) _it(i, 'TRABALHO', i),
        ]),
        50, // 3000 s
      );
    });

    test('sem descanso informado usa 60 s', () {
      expect(
        duracaoEstimadaMin([_it(1, 'TRABALHO', 0, descanso: null)]),
        duracaoEstimadaMin([_it(1, 'TRABALHO', 0, descanso: 60)]),
      );
    });

    test('nunca abaixo de 5 min quando há exercício', () {
      expect(
        duracaoEstimadaMin([_it(1, 'TRABALHO', 0, series: 1, descanso: 0)]),
        5,
      );
    });
  });
}

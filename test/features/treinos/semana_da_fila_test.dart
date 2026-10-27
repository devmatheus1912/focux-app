import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';

void main() {
  _remontarTest();
  _frequenciaTest();
}

void _frequenciaTest() {
  group('semanaPorFrequencia', () {
    List<String> nomes(List<DiaDaSemana> semana) => [
      for (final dia in semana)
        dia.sessoes.isEmpty ? '-' : dia.sessoes.single.nome,
    ];

    test('4 dias: A, B, C e D em seg, ter, qui e sex', () {
      final semana = semanaPorFrequencia(4);
      expect(semana, hasLength(7));
      expect(nomes(semana), [
        'Treino A',
        'Treino B',
        '-',
        'Treino C',
        'Treino D',
        '-',
        '-',
      ]);
      expect(semana.where((d) => d.descanso).map((d) => d.dia), [3, 6, 7]);
    });

    test('2, 3, 5, 6 e 7 dias caem nos dias padrão', () {
      const esperado = {
        2: [1, 4],
        3: [1, 3, 5],
        5: [1, 2, 3, 4, 5],
        6: [1, 2, 3, 4, 5, 6],
        7: [1, 2, 3, 4, 5, 6, 7],
      };
      esperado.forEach((n, dias) {
        final semana = semanaPorFrequencia(n);
        expect(
          semana.where((d) => d.sessoes.isNotEmpty).map((d) => d.dia),
          dias,
        );
        expect(
          semana.expand((d) => d.sessoes).map((s) => s.nome),
          [for (var i = 0; i < n; i++) 'Treino ${String.fromCharCode(65 + i)}'],
        );
      });
    });

    test('frequência fora de 2 a 7 devolve semana de descanso', () {
      final semana = semanaPorFrequencia(1);
      expect(semana.every((d) => d.sessoes.isEmpty && d.descanso), isTrue);
    });
  });
}

DiaDaSemana _d(int dia, [List<String> nomes = const [], int? count]) => DiaDaSemana(
  dia: dia,
  descanso: nomes.isEmpty,
  sessoes: [
    for (final n in nomes) SessaoDaSemana(nome: n, exerciciosCount: count),
  ],
);

void _remontarTest() {
  group('moverDia', () {
    final semana = [
      _d(1, ['A']),
      _d(2),
      _d(3, ['B']),
      for (var i = 4; i <= 7; i++) _d(i),
    ];

    test('para um dia vazio: a origem vira descanso', () {
      final nova = moverDia(semana, de: 1, para: 2);
      expect(nova.firstWhere((d) => d.dia == 1).sessoes, isEmpty);
      expect(nova.firstWhere((d) => d.dia == 1).descanso, isTrue);
      expect(nova.firstWhere((d) => d.dia == 2).sessoes.single.nome, 'A');
      expect(nova.firstWhere((d) => d.dia == 2).descanso, isFalse);
    });

    test('para um dia ocupado: as sessões trocam de lugar', () {
      final nova = moverDia(semana, de: 1, para: 3);
      expect(nova.firstWhere((d) => d.dia == 1).sessoes.single.nome, 'B');
      expect(nova.firstWhere((d) => d.dia == 3).sessoes.single.nome, 'A');
    });

    test('mesmo dia não muda nada e não mexe nos outros dias', () {
      expect(identical(moverDia(semana, de: 3, para: 3), semana), isTrue);
      final nova = moverDia(semana, de: 1, para: 2);
      expect(nova.firstWhere((d) => d.dia == 3).sessoes.single.nome, 'B');
      expect(nova, hasLength(7));
    });
  });

  group('comSessaoNoDia', () {
    test('acrescenta ao fim e tira o descanso', () {
      final nova = comSessaoNoDia(
        [_d(1, ['A']), _d(2)],
        dia: 2,
        sessao: const SessaoDaSemana(treinoId: 9, nome: 'Cópia de A'),
      );
      expect(nova[1].sessoes.single.treinoId, 9);
      expect(nova[1].descanso, isFalse);
      expect(nova[0].sessoes.single.nome, 'A');
    });

    test('num dia com sessão, a cópia vira a segunda', () {
      final nova = comSessaoNoDia(
        [_d(1, ['A'])],
        dia: 1,
        sessao: const SessaoDaSemana(nome: 'Cópia de A'),
      );
      expect(nova.single.sessoes.map((s) => s.nome), ['A', 'Cópia de A']);
    });
  });

  test('semanaVazia tem sete dias de descanso', () {
    final semana = semanaVazia();
    expect(semana, hasLength(7));
    expect(semana.every((d) => d.sessoes.isEmpty && d.descanso), isTrue);
  });

  group('estadoDaFicha', () {
    test('conta dias, sessões e prontas', () {
      final estado = estadoDaFicha([
        _d(1, ['A'], 5),
        _d(2, ['B'], 0),
        _d(3),
        _d(4, ['C', 'D'], 3),
      ]);
      expect(estado.dias, 3);
      expect(estado.sessoes, 4);
      expect(estado.prontas, 3);
      expect(estado.incompletas, 1);
      expect(estado.completa, isFalse);
    });

    test('contagem desconhecida conta como pronta', () {
      final estado = estadoDaFicha([_d(1, ['A'])]);
      expect(estado.completa, isTrue);
    });

    test('ficha vazia', () {
      final estado = estadoDaFicha(semanaVazia());
      expect(estado.vazia, isTrue);
      expect(estado.completa, isFalse);
    });
  });
}

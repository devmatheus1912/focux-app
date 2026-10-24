import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';

DiaDaSemana _dia(int dia, List<String> nomes, {bool descanso = false}) =>
    DiaDaSemana(
      dia: dia,
      descanso: descanso || nomes.isEmpty,
      sessoes: [for (final nome in nomes) SessaoDaSemana(nome: nome)],
    );

void main() {
  _frequenciaTest();
  test('semana cheia, duas sessões e descanso no meio', () {
    final dias = [
      _dia(1, ['Peito']),
      _dia(2, ['Costas']),
      _dia(3, const [], descanso: true),
      _dia(4, ['Pernas']),
      _dia(5, ['Ombro', 'Posterior']),
      _dia(6, const [], descanso: true),
      _dia(7, const [], descanso: true),
    ];
    final fila = filaDaSemana(dias);
    expect(
      fila.itens.map((item) => item.descanso ? 'D' : item.nome).toList(),
      ['Peito', 'Costas', 'D', 'Pernas', 'Ombro', 'Posterior', 'D'],
    );
    expect(fila.itens.where((item) => item.nome == 'Ombro').single.dia, 5);
    expect(fila.itens.where((item) => item.nome == 'Posterior').single.dia, 5);
    expect(fila.avisos, [3, 6, 7]);
    expect(
      fila.itens.where((item) => item.descanso).length,
      lessThan(3),
    );
  });

  test('descanso antes da primeira sessão só avisa', () {
    final fila = filaDaSemana([
      _dia(1, const [], descanso: true),
      _dia(2, ['Peito']),
      for (var dia = 3; dia <= 7; dia++) _dia(dia, const [], descanso: true),
    ]);
    expect(fila.itens.first.nome, 'Peito');
    expect(fila.avisos.first, 1);
  });

  test('semana vazia não cria card de descanso', () {
    final fila = filaDaSemana([
      for (var dia = 1; dia <= 7; dia++) _dia(dia, const [], descanso: true),
    ]);
    expect(fila.itens, isEmpty);
    expect(fila.avisos, [1, 2, 3, 4, 5, 6, 7]);
  });
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

    test('a fila resultante não tem dois descansos seguidos', () {
      for (var n = 2; n <= 7; n++) {
        final fila = filaDaSemana(semanaPorFrequencia(n));
        for (var i = 1; i < fila.itens.length; i++) {
          expect(fila.itens[i].descanso && fila.itens[i - 1].descanso, isFalse);
        }
        expect(fila.itens.where((i) => !i.descanso), hasLength(n));
      }
    });

    test('frequência fora de 2 a 7 devolve semana de descanso', () {
      final semana = semanaPorFrequencia(1);
      expect(semana.every((d) => d.sessoes.isEmpty && d.descanso), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/treinos/utils/semana_da_fila.dart';

DiaDaSemana _dia(int dia, List<String> nomes, {bool descanso = false}) =>
    DiaDaSemana(
      dia: dia,
      descanso: descanso || nomes.isEmpty,
      sessoes: [for (final nome in nomes) SessaoDaSemana(nome: nome)],
    );

void main() {
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

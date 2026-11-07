import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/data/meta_corporal.dart';

void main() {
  test('conquistas saem de meta concluída, mantida e recorde superado', () {
    final metas = [
      MetaCorporal(
        id: 1,
        metrica: 'PESO',
        tipo: 'META',
        valorInicial: 90,
        valorAlvo: 82,
        valorFinal: 82,
        progresso: 100,
        status: 'CONCLUIDA',
        criadoEm: DateTime(2026, 1, 1),
        concluidaEm: DateTime(2026, 3, 16),
      ),
      MetaCorporal(
        id: 2,
        metrica: 'PESO',
        tipo: 'MANUTENCAO',
        valorInicial: 82,
        valorAlvo: 82,
        progresso: 100,
        status: 'ATIVA',
        mantidaEm: DateTime(2026, 6, 20),
      ),
    ];
    RecordePessoal r(int id, String data, double carga) => RecordePessoal(
      id: id,
      exercicioId: 1,
      exercicioNome: 'Supino',
      data: data,
      cargaKg: carga,
    );
    final lista = conquistasDe(metas, [r(1, '2026-01-01', 80), r(2, '2026-02-01', 90)]);
    expect(lista.map((c) => c.tipo), [
      ConquistaTipo.mantido,
      ConquistaTipo.meta,
      ConquistaTipo.recorde,
    ]);
    expect(lista[1].titulo, '−8,0 kg');
    expect(lista[1].detalhe, contains('74 dias'));
    expect(lista.last.celebra, isFalse);
  });

  MetaCorporal metaPeso({required DateTime criada, required DateTime concluida}) => MetaCorporal(
    id: 7,
    metrica: 'PESO',
    tipo: 'META',
    valorInicial: 110,
    valorAlvo: 116,
    valorFinal: 116,
    progresso: 100,
    status: 'CONCLUIDA',
    criadoEm: criada,
    concluidaEm: concluida,
  );
  MedidaCorporal medida(int id, String data, double peso) =>
      MedidaCorporal(id: id, data: data, peso: peso);

  test('dias contam pelas medidas, não pela vida da meta', () {
    // Meta criada e concluída no mesmo dia; as medidas são de 04/11 e 08/11.
    final lista = conquistasDe(
      [metaPeso(criada: DateTime(2026, 11, 8), concluida: DateTime(2026, 11, 8, 10))],
      const [],
      medidas: [medida(1, '2026-11-04', 110), medida(2, '2026-11-08', 116)],
    );
    expect(lista.single.detalhe, contains('em 4 dias'));
  });

  test('mesmo dia vira "no mesmo dia"', () {
    final lista = conquistasDe(
      [metaPeso(criada: DateTime(2026, 11, 8), concluida: DateTime(2026, 11, 8))],
      const [],
    );
    expect(lista.single.detalhe, endsWith('no mesmo dia'));
  });

  test('salto que pede Confira não vira conquista', () {
    // 110 → 116 kg em 2 dias passa de 1,5 kg/dia.
    final lista = conquistasDe(
      [metaPeso(criada: DateTime(2026, 11, 4), concluida: DateTime(2026, 11, 6))],
      const [],
      medidas: [medida(1, '2026-11-04', 110), medida(2, '2026-11-06', 116)],
    );
    expect(lista, isEmpty);
  });

  test('primeira marca não é recorde', () {
    final lista = conquistasDe(const [], [
      RecordePessoal(id: 1, exercicioId: 1, exercicioNome: 'Supino', data: '2026-01-01', cargaKg: 80),
    ]);
    expect(lista, isEmpty);
  });
}

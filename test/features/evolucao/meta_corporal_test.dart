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

  test('primeira marca não é recorde', () {
    final lista = conquistasDe(const [], [
      RecordePessoal(id: 1, exercicioId: 1, exercicioNome: 'Supino', data: '2026-01-01', cargaKg: 80),
    ]);
    expect(lista, isEmpty);
  });
}

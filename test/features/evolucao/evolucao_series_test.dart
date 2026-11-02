import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_grafico_linha.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/engajamento_display.dart';
import 'package:focux_app/features/evolucao/utils/evolucao_series.dart';

MedidaCorporal _m(int id, String data, double peso) =>
    MedidaCorporal(id: id, data: data, peso: peso);

RecordePessoal _r(int id, String data, double carga, [int? reps]) =>
    RecordePessoal(
      id: id,
      exercicioId: 1,
      exercicioNome: 'Supino',
      data: data,
      cargaKg: carga,
      repeticoes: reps,
    );

void main() {
  test('duas medidas no mesmo dia: a última registrada é a atual', () {
    final pontos = serieDaMetrica([
      _m(3, '2026-10-31', 60),
      _m(2, '2026-10-31', 100),
      _m(1, '2026-10-30', 90),
    ], EvolucaoMetrica.peso);
    expect(pontos.map((p) => p.valor), [90, 100, 60]);
  });

  test('tendência só aparece a partir de 7 pontos', () {
    PontoGrafico p(int d) => PontoGrafico(DateTime(2026, 10, d), 80.0 + d);
    expect(tendenciaDe([for (var d = 1; d <= 6; d++) p(d)]), isEmpty);
    expect(tendenciaDe([for (var d = 1; d <= 7; d++) p(d)]), hasLength(7));
  });

  test('período corta pela data', () {
    final hoje = DateTime(2026, 11, 1);
    final pontos = [
      PontoGrafico(DateTime(2026, 1, 1), 1),
      PontoGrafico(DateTime(2026, 10, 20), 2),
    ];
    expect(pontosDoPeriodo(pontos, EvolucaoPeriodo.dias30, hoje: hoje), hasLength(1));
    expect(pontosDoPeriodo(pontos, EvolucaoPeriodo.tudo, hoje: hoje), hasLength(2));
  });

  test('recordes: melhor marca, ganho e 1RM só na faixa útil', () {
    final lista = progressoDosRecordes([
      _r(1, '2026-01-01', 80, 5),
      _r(2, '2026-03-01', 100, 5),
    ]);
    expect(lista.single.melhor.cargaKg, 100);
    expect(lista.single.ganhoKg, 20);
    expect(maiorProgresso(lista), isNotNull);
    expect(umRmEstimado(_r(3, '2026-03-01', 100, 1)), isNull);
    expect(umRmEstimado(_r(3, '2026-03-01', 100, 15)), isNull);
    expect(umRmEstimado(_r(3, '2026-03-01', 90, 10)), 120);
  });

  group('quadro de semanas', () {
    final agora = DateTime(2026, 11, 4); // quarta

    test('começa na segunda e marca hoje', () {
      final semanas = engajamentoSemanas(const [], diasDescanso: const [], diaDaFicha: 60, now: agora);
      expect(semanas, hasLength(5));
      expect(semanas.last.inicio, DateTime(2026, 11, 2));
      expect(semanas.last.dias[2].hoje, isTrue);
      expect(semanas.last.dias[3].estado, EngajamentoDiaEstado.futuro);
    });

    test('sem dias de descanso não inventa falta', () {
      final semanas = engajamentoSemanas(const [], diasDescanso: const [], diaDaFicha: 60, now: agora);
      expect(semanas.first.dias.first.estado, EngajamentoDiaEstado.semRegistro);
    });

    test('com descanso marcado, dia previsto sem treino é falta e hoje não', () {
      final semanas = engajamentoSemanas(const [], diasDescanso: const [6, 7], diaDaFicha: 60, now: agora);
      expect(semanas.first.dias.first.estado, EngajamentoDiaEstado.faltou);
      expect(semanas.first.dias.last.estado, EngajamentoDiaEstado.descanso);
      expect(semanas.last.dias[2].estado, EngajamentoDiaEstado.semRegistro);
    });

    test('antes do início da ficha nada é falta', () {
      final semanas = engajamentoSemanas(const [], diasDescanso: const [6, 7], diaDaFicha: 3, now: agora);
      expect(semanas.first.dias.first.estado, EngajamentoDiaEstado.semRegistro);
      expect(engajamentoContagemQuadro(semanas).previstos, 2);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/evolucao/data/evolucao_repository.dart';
import 'package:focux_app/features/evolucao/utils/engajamento_display.dart';

void main() {
  // Segunda, 09/11/2026.
  final hoje = DateTime(2026, 11, 9, 8);

  test('mês passado pede outubro inteiro e mostra as semanas do mês', () {
    final c = engajamentoPeriodoConsulta(
      EngajamentoPeriodo.mesPassado,
      now: hoje,
    );
    expect(c.inicio, DateTime(2026, 10, 1));
    expect(c.fim, DateTime(2026, 10, 31));
    final q = engajamentoQuadroDoPeriodo(
      EngajamentoPeriodo.mesPassado,
      diaDaFicha: 40,
      now: hoje,
    );
    // 01/10 é quinta (semana de 29/09) e 31/10 é sábado (semana de 26/10).
    expect(q.semanas, 5);
    expect(q.ate, DateTime(2026, 10, 31));
  });

  test('o quadro começa na semana do início, sem semanas vazias antes', () {
    // Treina desde 28/10 (dia 13): semanas de 26/10, 02/11 e 09/11.
    final q = engajamentoQuadroDoPeriodo(
      EngajamentoPeriodo.cincoSemanas,
      diaDaFicha: 13,
      now: hoje,
    );
    expect(q.semanas, 3);
    expect(
      engajamentoQuadroDoPeriodo(
        EngajamentoPeriodo.cincoSemanas,
        diaDaFicha: 200,
        now: hoje,
      ).semanas,
      5,
    );
  });

  test('segunda de manhã sem treino: a semana só começou', () {
    final semana =
        engajamentoSemanas(
          const <EventoEngajamento>[],
          diasDescanso: const [6, 7],
          diaDaFicha: 30,
          now: hoje,
          semanas: 1,
        ).last;
    expect(engajamentoSemanaComecou(semana), isTrue);
  });

  test('tendência do período em pontos', () {
    expect(engajamentoTendenciaPeriodo(null), isNull);
    expect(engajamentoTendenciaPeriodo(12)!.texto, '12 pontos acima do período anterior');
    expect(engajamentoTendenciaPeriodo(-1)!.texto, '1 ponto abaixo do período anterior');
    expect(engajamentoTendenciaPeriodo(0)!.texto, 'Igual ao período anterior');
  });

  test('periodo do servidor', () {
    final p = AderenciaPeriodo.fromJson({
      'inicio': '2026-10-01',
      'fim': '2026-10-31',
      'feitos': 12,
      'previstos': 22,
      'percent': 55,
      'percentAnterior': 40,
      'diferenca': 15,
    });
    expect(p.inicio, DateTime(2026, 10, 1));
    expect(p.diferenca, 15);
  });
}

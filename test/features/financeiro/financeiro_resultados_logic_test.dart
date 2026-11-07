import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/financeiro/utils/financeiro_resultados_logic.dart';

void main() {
  group('resultadosDetalhesVisiveis (10 pagantes e 3 meses)', () {
    test('limites exatos', () {
      expect(
        resultadosDetalhesVisiveis(pagantes: 10, mesesComCobranca: 3),
        isTrue,
      );
      expect(
        resultadosDetalhesVisiveis(pagantes: 9, mesesComCobranca: 3),
        isFalse,
      );
      expect(
        resultadosDetalhesVisiveis(pagantes: 10, mesesComCobranca: 2),
        isFalse,
      );
    });
    test('as duas condições valem juntas', () {
      expect(
        resultadosDetalhesVisiveis(pagantes: 50, mesesComCobranca: 1),
        isFalse,
      );
      expect(
        resultadosDetalhesVisiveis(pagantes: 1, mesesComCobranca: 24),
        isFalse,
      );
    });
    test('os limites são constantes nomeadas', () {
      expect(resultadosMinPagantes, 10);
      expect(resultadosMinMeses, 3);
    });
  });

  group('de onde veio o recebido', () {
    test('divide em do mês, anteriores e adiantado', () {
      final r = ResumoMensal.fromJson({
        'totalRecebido': '600.00',
        'totalPrevisto': '200.00',
        'recebidoDeMesesAnteriores': '200.00',
        'recebidoAdiantado': '200.00',
        'pagoDoMes': '200.00',
      });
      expect(r.recebidoDoMes.cents, 20000);
      expect(r.emAbertoDoMes.cents, 0);
    });
  });

  test('gráfico começa no primeiro mês com dinheiro', () {
    final itens = [
      for (final (m, v) in [('2026-06', '0'), ('2026-07', '0'), ('2026-10', '100'), ('2026-11', '600')])
        EvolucaoMensalItem.fromJson({'mes': m, 'recebido': v}),
    ];
    final r = resultadosDesdePrimeiroMes(itens, 2026, 11);
    expect(r.map((e) => e.mes), ['2026-10', '2026-11']);
  });

  test('mês atual', () {
    final hoje = DateTime(2026, 10, 26);
    expect(resultadosEhMesAtual(2026, 10, hoje), isTrue);
    expect(resultadosEhMesAtual(2026, 9, hoje), isFalse);
    expect(resultadosEhMesAtual(2025, 10, hoje), isFalse);
  });

  test('formatação: percentual e meses', () {
    expect(resultadosPct(null), '—');
    expect(resultadosPct(112.5), contains('112'));
    expect(resultadosMesesLabel(12), '12');
    expect(resultadosMesesLabel(7.5), '7,5');
  });
}

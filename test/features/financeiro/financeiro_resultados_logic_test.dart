import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/financeiro/utils/financeiro_resultados_logic.dart';

ResumoMensal _r({required String recebido, required String previsto}) =>
    ResumoMensal(
      totalRecebido: recebido,
      totalPrevisto: previsto,
      inadimplentes: 0,
      ticketMedio: '0',
      acumuladoAnual: '0',
    );

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

  group('recebido maior que lançado', () {
    test('recebido de mês anterior passa do lançado do mês', () {
      expect(
        resultadosRecebidoMaiorQueLancado(
          _r(recebido: '100.00', previsto: '0.00'),
        ),
        isTrue,
      );
    });
    test('igual ou menor não precisa de explicação', () {
      expect(
        resultadosRecebidoMaiorQueLancado(
          _r(recebido: '100.00', previsto: '100.00'),
        ),
        isFalse,
      );
      expect(
        resultadosRecebidoMaiorQueLancado(
          _r(recebido: '0.00', previsto: '100.00'),
        ),
        isFalse,
      );
    });
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

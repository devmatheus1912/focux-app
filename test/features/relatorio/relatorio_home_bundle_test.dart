import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/relatorio/data/relatorio_repository.dart';

void main() {
  test('RelatoriosHomeBundle parses aderencia + comparativo', () {
    final bundle = RelatoriosHomeBundle.fromJson({
      'aderencia': {
        'diasAnalisados': 30,
        'treinosConcluidos': 8,
        'treinosTotal': 10,
        'taxaAderenciaPercent': 80.0,
      },
      'comparativo': {
        'aderenciaAtual': 80.0,
        'aderenciaAnterior': 70.0,
        'deltaPercent': 10.0,
        'checkInsAtual': 8,
        'checkInsAnterior': 7,
      },
    });

    expect(bundle.aderencia.diasAnalisados, 30);
    expect(bundle.aderencia.treinosConcluidos, 8);
    expect(bundle.aderencia.treinosTotal, 10);
    expect(bundle.aderencia.taxaAderenciaPercent, 80.0);
    expect(bundle.comparativo, isNotNull);
    expect(bundle.comparativo!.aderenciaAtual, 80.0);
    expect(bundle.comparativo!.aderenciaAnterior, 70.0);
    expect(bundle.comparativo!.deltaPercent, 10.0);
    expect(bundle.comparativo!.checkInsAtual, 8);
    expect(bundle.comparativo!.checkInsAnterior, 7);
  });

  test('RelatoriosHomeBundle tolerates missing comparativo', () {
    final bundle = RelatoriosHomeBundle.fromJson({
      'aderencia': {
        'diasAnalisados': 7,
        'treinosConcluidos': 0,
        'treinosTotal': 0,
        'taxaAderenciaPercent': 0.0,
      },
    });
    expect(bundle.aderencia.diasAnalisados, 7);
    expect(bundle.comparativo, isNull);
  });

  test('RelatoriosHomeBundle tolerates missing aderencia', () {
    final bundle = RelatoriosHomeBundle.fromJson({});
    expect(bundle.aderencia.treinosTotal, 0);
    expect(bundle.aderencia.taxaAderenciaPercent, 0);
    expect(bundle.comparativo, isNull);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/financeiro/data/financeiro_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  Map<String, dynamic> dashboardJson() => {
    'receitaMes': 1200.0,
    'receitaAcumulada': 4800.0,
    'ticketMedio': 300.0,
    'totalInadimplentes': 1,
    'previsaoReceita': 1500.0,
    'vencimentosProximos': <dynamic>[],
    'topAlunos': <dynamic>[],
    'evolucaoMensal': <dynamic>[],
  };

  test('FinanceiroHomeBundle parses aggregates + optional planoFeatures', () {
    final bundle = FinanceiroHomeBundle.fromJson({
      'dashboard': dashboardJson(),
      'mensalidades': <dynamic>[],
      'resumoMesAtual': {
        'totalRecebido': 900.0,
        'totalPrevisto': 1200.0,
        'inadimplentes': 1,
        'ticketMedio': 300.0,
        'acumuladoAnual': 4800.0,
      },
      'planoFeatures': {
        'plano': 'PREMIUM',
        'features': {'financeiro': true, 'agenda': true},
      },
    });

    expect(bundle.dashboard.receitaMes, 1200.0);
    expect(bundle.mensalidades, isEmpty);
    expect(bundle.resumoMesAtual.totalRecebido, 900.0);
    expect(bundle.planoFeatures?.plano, SubscriptionPlan.PREMIUM);
    expect(bundle.planoFeatures?.financeiro, isTrue);
  });

  test('FinanceiroHomeBundle tolerates missing planoFeatures', () {
    final bundle = FinanceiroHomeBundle.fromJson({
      'dashboard': dashboardJson(),
      'mensalidades': <dynamic>[],
      'resumoMesAtual': <String, dynamic>{},
    });

    expect(bundle.planoFeatures, isNull);
    expect(bundle.resumoMesAtual.totalRecebido, 0);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/money/fx_money.dart';
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
        'plano': 'PRO',
        'features': {'financeiro': true, 'agenda': true},
      },
    });

    expect(bundle.dashboard.receitaMes, FxMoney.parse(1200.0));
    expect(bundle.mensalidades, isEmpty);
    expect(bundle.resumoMesAtual.totalRecebido, FxMoney.parse(900.0));
    expect(bundle.planoFeatures?.plano, SubscriptionPlan.PRO);
    expect(bundle.planoFeatures?.financeiro, isTrue);
    expect(bundle.hasMore, isFalse);
    expect(bundle.page, 0);
  });

  test('FinanceiroHomeBundle parses pagination fields', () {
    final bundle = FinanceiroHomeBundle.fromJson({
      'dashboard': dashboardJson(),
      'mensalidades': <dynamic>[],
      'resumoMesAtual': <String, dynamic>{},
      'page': 1,
      'size': 20,
      'hasMore': true,
    });
    expect(bundle.page, 1);
    expect(bundle.hasMore, isTrue);
  });

  test('MensalidadesPage parses envelope', () {
    final page = MensalidadesPage.fromJson({
      'mensalidades': <dynamic>[],
      'page': 0,
      'size': 20,
      'hasMore': false,
    });
    expect(page.mensalidades, isEmpty);
    expect(page.hasMore, isFalse);
  });

  test('FinanceiroHomeBundle tolerates missing planoFeatures', () {
    final bundle = FinanceiroHomeBundle.fromJson({
      'dashboard': dashboardJson(),
      'mensalidades': <dynamic>[],
      'resumoMesAtual': <String, dynamic>{},
    });

    expect(bundle.planoFeatures, isNull);
    expect(bundle.resumoMesAtual.totalRecebido, FxMoney.zero);
  });
}

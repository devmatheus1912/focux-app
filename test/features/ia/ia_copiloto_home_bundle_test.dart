import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/models/ia_copiloto_home.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('IaCopilotoHomeBundle parses picker + quota without insights', () {
    final bundle = IaCopilotoHomeBundle.fromJson({
      'alunosResumo': [
        {'id': 3, 'nome': 'Ana', 'objetivo': 'Hipertrofia'},
      ],
      'planoFeatures': {
        'plano': 'PREMIUM',
        'limiteIaMensal': 120,
        'iaUsadaMes': 8,
        'features': {'iaCopiloto': true, 'financeiro': true, 'agenda': true},
      },
    });

    expect(bundle.alunosResumo, hasLength(1));
    expect(bundle.alunosResumo.first.id, 3);
    expect(bundle.alunosResumo.first.nome, 'Ana');
    expect(bundle.planoFeatures?.plano, SubscriptionPlan.PRO);
    expect(bundle.planoFeatures?.iaRestantes, 112);
    expect(bundle.planoFeatures?.iaCopiloto, isTrue);
  });
}

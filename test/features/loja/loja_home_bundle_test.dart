import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/loja/data/loja_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

void main() {
  test('LojaHomeBundle parses pacotes + pedidos + optional planoFeatures', () {
    final bundle = LojaHomeBundle.fromJson({
      'pacotes': [
        {
          'id': 1,
          'titulo': 'Musculação',
          'valor': 150,
          'duracaoMeses': 3,
          'incluiTreino': true,
          'incluiNutri': false,
          'incluiConsultoria': false,
          'destaque': true,
          'ativo': true,
        },
      ],
      'pedidos': [
        {
          'id': 10,
          'pacoteId': 1,
          'buyerEmail': 'ana@test.com',
          'buyerNome': 'Ana',
          'valor': 150,
          'status': 'PENDENTE',
          'pixCopiaECola': 'PIX-MOCK-1',
        },
      ],
      'planoFeatures': {
        'plano': 'ENTERPRISE',
        'features': {'lojaDigital': true, 'agenda': true},
      },
    });
    expect(bundle.pacotes, hasLength(1));
    expect(bundle.pacotes.first.titulo, 'Musculação');
    expect(bundle.pacotes.first.valor, 150);
    expect(bundle.pedidos, hasLength(1));
    expect(bundle.pedidos.first.buyerEmail, 'ana@test.com');
    expect(bundle.pedidos.first.status, 'PENDENTE');
    expect(bundle.pedidos.first.pixCopiaECola, 'PIX-MOCK-1');
    expect(bundle.planoFeatures?.plano, SubscriptionPlan.ENTERPRISE);
    expect(bundle.planoFeatures?.lojaDigital, isTrue);
  });

  test('LojaHomeBundle skips inactive pacotes and missing lists', () {
    final bundle = LojaHomeBundle.fromJson({
      'pacotes': [
        {
          'id': 2,
          'titulo': 'Inativo',
          'valor': 80,
          'duracaoMeses': 1,
          'incluiTreino': true,
          'incluiNutri': false,
          'incluiConsultoria': false,
          'destaque': false,
          'ativo': false,
        },
      ],
    });
    expect(bundle.pacotes, isEmpty);
    expect(bundle.pedidos, isEmpty);
    expect(bundle.planoFeatures, isNull);
  });
}

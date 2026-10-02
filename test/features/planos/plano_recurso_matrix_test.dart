import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/planos/utils/plano_capability.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

PlanoFeatures _tier(SubscriptionPlan plano) =>
    PlanoFeatures.fromJson({'plano': plano.name});

void main() {
  test('matriz de fallback é a matriz de produto', () {
    expect(PlanoRecursoKeys.matrix, const {
      'financeiro': SubscriptionPlan.PRO,
      'recorrencia': SubscriptionPlan.PRO,
      'carteira': SubscriptionPlan.PRO,
      'relatorios': SubscriptionPlan.PRO,
      'habitos': SubscriptionPlan.PRO,
      'feedbackVideo': SubscriptionPlan.PRO,
      'ia': SubscriptionPlan.PRO,
      'importacaoFoto': SubscriptionPlan.PRO,
      'leads': SubscriptionPlan.PRO,
      'landing': SubscriptionPlan.ENTERPRISE,
      'whiteLabel': SubscriptionPlan.ENTERPRISE,
      'loja': SubscriptionPlan.ENTERPRISE,
      'automacoes': SubscriptionPlan.ENTERPRISE,
      'winback': SubscriptionPlan.ENTERPRISE,
      'desafios': SubscriptionPlan.ENTERPRISE,
      'equipe': SubscriptionPlan.ENTERPRISE,
      'nfse': SubscriptionPlan.ENTERPRISE,
    });
  });

  test('sem recursos no JSON, cada tier libera só o que a matriz manda', () {
    for (final plano in SubscriptionPlan.values) {
      final features = _tier(plano);
      PlanoRecursoKeys.matrix.forEach((key, minimo) {
        expect(
          features.recurso(key),
          PlanoRecurso(liberado: plano.canAccess(minimo), planoMinimo: minimo),
          reason: '${plano.name}/$key',
        );
      });
    }
  });

  test('Free mantém o núcleo e trava o pago', () {
    final free = _tier(SubscriptionPlan.FREE);
    expect(PlanoCapability.has(free, 'agenda'), isTrue);
    expect(free.financeiro, isFalse);
    expect(free.relatorios, isFalse);
    expect(free.iaCopiloto, isFalse);
    expect(PlanoCapability.has(free, 'leads'), isFalse);
    expect(free.comunidadePrivada, isFalse);
    expect(free.limiteLeads, isNull);
  });

  test('recursos do servidor vencem a matriz', () {
    final features = PlanoFeatures.fromJson({
      'plano': 'FREE',
      'recursos': {
        'leads': {'liberado': true, 'planoMinimo': 'PRO'},
        'financeiro': {'liberado': true, 'planoMinimo': 'PRO'},
      },
    });
    expect(features.recurso('leads').liberado, isTrue);
    expect(features.financeiro, isTrue);
    expect(PlanoCapability.has(features, 'leads'), isTrue);
    expect(features.recurso('ia').liberado, isFalse);

    final enterprise = PlanoFeatures.fromJson({
      'plano': 'ENTERPRISE',
      'recursos': {
        'landing': {'liberado': false, 'planoMinimo': 'ENTERPRISE'},
      },
    });
    expect(enterprise.landingCompleta, isFalse);
    expect(PlanoCapability.has(enterprise, 'landingCompleta'), isFalse);
    expect(enterprise.whiteLabel, isTrue);
  });

  test('recursos sobrevivem ao cache (toJson → fromJson)', () {
    final features = PlanoFeatures.fromJson({
      'plano': 'PRO',
      'recursos': {
        'ia': {'liberado': false, 'planoMinimo': 'PRO'},
      },
    });
    final back = PlanoFeatures.fromJson(features.toJson());
    expect(back.recurso('ia').liberado, isFalse);
    expect(back.iaCopiloto, isFalse);
  });

  test('aluno sem plano confirmado cai no Free', () {
    expect(PlanoFeatures.optimisticAluno.plano, SubscriptionPlan.FREE);
    expect(
      PlanoFeatures.optimisticAluno.normalizeForTier().habitCoaching,
      isFalse,
    );
  });

  test('PREMIUM do servidor continua virando Pro', () {
    expect(subscriptionPlanFromApi('PREMIUM'), SubscriptionPlan.PRO);
    expect(subscriptionPlanFromApi('ENTERPRISE_PRO'), SubscriptionPlan.FREE);
  });
}

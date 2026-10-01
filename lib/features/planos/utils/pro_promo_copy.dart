import '../../../l10n/app_localizations.dart';
import '../../assinatura/data/plano.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/subscription_products.dart';
import '../paywall/paywall_price.dart';

/// O trial do checkout web não cobra: ao vencer, a conta volta para o Free.
String proPromoTrialFimTexto(S l10n, DateTime fimTeste) {
  final dia = fimTeste.day.toString().padLeft(2, '0');
  final mes = fimTeste.month.toString().padLeft(2, '0');
  return l10n.proPromoTrialFim('$dia/$mes/${fimTeste.year}');
}

/// Preço mensal do plano do trial vindo da API, como referência pós-teste.
/// Nulo quando a API não mandou preço — a linha some.
String? proPromoPrecoPosTesteTexto(S l10n, List<Plano>? planos) {
  final plano = planos
      ?.where((p) => subscriptionPlanFromApi(p.nome) == kTrialPlan)
      .firstOrNull;
  if (plano == null || plano.precoMensal <= 0) return null;
  final preco = buildPaywallPriceCopy(
    precoMensal: plano.precoMensal,
    period: SubscriptionBillingPeriod.monthly,
  ).primary;
  return l10n.proPromoPrecoPosTeste(preco);
}

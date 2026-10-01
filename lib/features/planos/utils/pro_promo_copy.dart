import '../../../l10n/app_localizations.dart';
import '../../assinatura/data/plano.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/subscription_products.dart';
import '../paywall/paywall_price.dart';

/// O trial do checkout web não cobra: ao vencer, a conta volta para o Free.
String enterprisePromoTrialFimTexto(S l10n, DateTime fimTeste) {
  final dia = fimTeste.day.toString().padLeft(2, '0');
  final mes = fimTeste.month.toString().padLeft(2, '0');
  return l10n.enterprisePromoTrialFim('$dia/$mes/${fimTeste.year}');
}

/// Preço mensal do Enterprise vindo da API, como referência pós-teste.
/// Nulo quando a API não mandou preço — a linha some.
String? enterprisePromoPrecoPosTesteTexto(S l10n, List<Plano>? planos) {
  final enterprise = planos
      ?.where((p) => subscriptionPlanFromApi(p.nome) == SubscriptionPlan.ENTERPRISE)
      .firstOrNull;
  if (enterprise == null || enterprise.precoMensal <= 0) return null;
  final preco = buildPaywallPriceCopy(
    precoMensal: enterprise.precoMensal,
    period: SubscriptionBillingPeriod.monthly,
  ).primary;
  return l10n.enterprisePromoPrecoPosTeste(preco);
}

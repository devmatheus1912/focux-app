import '../../subscription/models/subscription_plan.dart';
import '../../subscription/subscription_products.dart';

/// 30 dias grátis só no Enterprise Pro, na primeira assinatura (cadastro de cartão).
const kPaywallMaxPlanTrialDays = 30;

class PaywallPriceCopy {
  const PaywallPriceCopy({required this.primary, this.secondary});

  final String primary;
  final String? secondary;
}

String formatPaywallBrl(double value) {
  final formatted = value.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $formatted';
}

/// Preço do fold: loja se existir, senão catálogo BFF.
PaywallPriceCopy buildPaywallPriceCopy({
  required double precoMensal,
  double? precoAnual,
  double? precoAnualMensalEquiv,
  required SubscriptionBillingPeriod period,
  String? storePrice,
}) {
  if (precoMensal <= 0) {
    return const PaywallPriceCopy(primary: 'Grátis');
  }

  final yearly = period == SubscriptionBillingPeriod.yearly;
  final trimmedStore = storePrice?.trim();
  if (trimmedStore != null && trimmedStore.isNotEmpty) {
    return PaywallPriceCopy(
      primary: '$trimmedStore${yearly ? '/ano' : '/mês'}',
      secondary: yearly ? _monthlyEquiv(precoAnualMensalEquiv, precoMensal) : null,
    );
  }

  if (yearly) {
    final annual = precoAnual ?? (precoMensal * 12 * 0.8);
    return PaywallPriceCopy(
      primary: '${formatPaywallBrl(annual)}/ano',
      secondary: _monthlyEquiv(precoAnualMensalEquiv, annual / 12),
    );
  }

  return PaywallPriceCopy(primary: '${formatPaywallBrl(precoMensal)}/mês');
}

String? _monthlyEquiv(double? explicit, double fallback) {
  final value = (explicit != null && explicit > 0) ? explicit : fallback;
  if (value <= 0) return null;
  return 'Equiv. ${formatPaywallBrl(value)}/mês';
}

/// 30 dias grátis só no Pro, na primeira assinatura (cadastro de cartão).
bool paywallShowsMaxPlanTrial({
  required SubscriptionPlan selected,
  required SubscriptionPlan current,
  bool? trialEligible,
}) {
  if (selected != SubscriptionPlan.ENTERPRISE_PRO) return false;
  if (current != SubscriptionPlan.FREE) return false;
  return trialEligible != false;
}

import '../../subscription/models/subscription_plan.dart';
import '../../subscription/subscription_products.dart';

/// 30 dias grátis só no Enterprise, na primeira assinatura (cadastro de cartão).
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
  String? labelDescontoAnual,
  String? labelEconomiaAnual,
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
      secondary: yearly
          ? _yearlySecondary(
              precoAnualMensalEquiv,
              precoMensal,
              labelDescontoAnual,
              labelEconomiaAnual,
            )
          : null,
    );
  }

  if (yearly) {
    final annual = precoAnual ?? (precoMensal * 10);
    return PaywallPriceCopy(
      primary: '${formatPaywallBrl(annual)}/ano',
      secondary: _yearlySecondary(
        precoAnualMensalEquiv,
        annual / 12,
        labelDescontoAnual,
        labelEconomiaAnual,
      ),
    );
  }

  return PaywallPriceCopy(primary: '${formatPaywallBrl(precoMensal)}/mês');
}

String? _yearlySecondary(
  double? explicitEquiv,
  double fallbackEquiv,
  String? labelDesconto,
  String? labelEconomia,
) {
  final equiv = (explicitEquiv != null && explicitEquiv > 0)
      ? explicitEquiv
      : fallbackEquiv;
  final parts = <String>[];
  if (equiv > 0) parts.add('Equiv. ${formatPaywallBrl(equiv)}/mês');
  final desconto = labelDesconto?.trim();
  if (desconto != null && desconto.isNotEmpty) parts.add(desconto);
  final economia = labelEconomia?.trim();
  if (economia != null && economia.isNotEmpty) parts.add(economia);
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

/// 30 dias grátis só no Enterprise, na primeira assinatura (cadastro de cartão).
bool paywallShowsMaxPlanTrial({
  required SubscriptionPlan selected,
  required SubscriptionPlan current,
  bool? trialEligible,
}) {
  if (selected != SubscriptionPlan.ENTERPRISE) return false;
  if (current != SubscriptionPlan.FREE) return false;
  return trialEligible != false;
}

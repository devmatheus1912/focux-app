import '../../subscription/models/subscription_plan.dart';
import 'paywall_catalog.dart';

/// Fold ChatGPT-like: uma aba, um card. Lógica fora do widget.
class PaywallCompareView {
  const PaywallCompareView({
    required this.selected,
    required this.baseline,
    required this.headline,
    required this.subtitle,
    required this.baselineColumnLabel,
    required this.selectedColumnLabel,
    required this.rows,
    required this.showTwoColumns,
    required this.showBillingToggle,
  });

  final SubscriptionPlan selected;
  final SubscriptionPlan baseline;
  final String headline;
  final String subtitle;
  final String baselineColumnLabel;
  final String selectedColumnLabel;
  final List<PaywallCompareRow> rows;
  final bool showTwoColumns;
  final bool showBillingToggle;
}

class PaywallCompareRow {
  const PaywallCompareRow({
    required this.feature,
    required this.baseline,
    required this.selected,
  });

  final String feature;
  final String baseline;
  final String selected;
}

String paywallTabLabel(SubscriptionPlan plan) => switch (plan) {
  SubscriptionPlan.FREE => 'Free',
  SubscriptionPlan.PRO => 'Pro',
  SubscriptionPlan.ENTERPRISE => 'Enterprise',
};

String paywallPrettyName(SubscriptionPlan plan) => switch (plan) {
  SubscriptionPlan.FREE => 'FREE',
  SubscriptionPlan.PRO => 'Pro',
  SubscriptionPlan.ENTERPRISE => 'Enterprise',
};

String paywallCompareHeadline({
  required SubscriptionPlan selected,
  required SubscriptionPlan current,
}) {
  if (selected == current) {
    return 'Seu plano ${paywallPrettyName(selected)}';
  }
  if (selected.level > current.level) {
    return 'Assinar ${paywallPrettyName(selected)}';
  }
  return 'Ver ${paywallPrettyName(selected)}';
}

String paywallCompareSubtitle({
  required SubscriptionPlan selected,
  required SubscriptionPlan current,
  required bool managementMode,
}) {
  if (managementMode && selected == current) {
    return 'Status, cobrança na loja e cancelamento — sem vitrine de upgrade.';
  }
  return PaywallCatalog.subtitleForPlan(selected);
}

bool paywallCompareCellIncluded(String value) {
  final t = value.trim();
  return t.isNotEmpty && t != '—';
}

PaywallCompareView buildPaywallCompareView({
  required SubscriptionPlan selected,
  required SubscriptionPlan current,
  List<PaywallComparisonRow>? rows,
  bool managementMode = false,
}) {
  const baseline = SubscriptionPlan.FREE;
  final showTwo = selected != SubscriptionPlan.FREE;
  final source =
      (rows != null && rows.isNotEmpty)
          ? rows
          : switch (selected) {
            SubscriptionPlan.ENTERPRISE =>
              PaywallCatalog.comparisonFreeVsEnterprise,
            _ => PaywallCatalog.comparisonFreeVsPro,
          };
  final mapped =
      source
          .map((row) {
            final parsed = PaywallCatalog.parseFeatureLabel(row.feature);
            return PaywallCompareRow(
              feature: parsed.label,
              baseline: row.free,
              selected: row.paid,
            );
          })
          .toList(growable: false);

  final managingCurrent = managementMode && selected == current;

  return PaywallCompareView(
    selected: selected,
    baseline: baseline,
    headline: paywallCompareHeadline(selected: selected, current: current),
    subtitle: paywallCompareSubtitle(
      selected: selected,
      current: current,
      managementMode: managementMode,
    ),
    baselineColumnLabel: paywallTabLabel(baseline),
    selectedColumnLabel: paywallTabLabel(selected),
    rows: mapped,
    showTwoColumns: showTwo,
    // Gestão do plano máximo: sem toggle mensal/anual (não há checkout de upgrade).
    showBillingToggle: selected != SubscriptionPlan.FREE && !managingCurrent,
  );
}

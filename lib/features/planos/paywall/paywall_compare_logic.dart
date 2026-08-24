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
  SubscriptionPlan.PREMIUM => 'Premium',
  SubscriptionPlan.ENTERPRISE => 'Enterprise',
  SubscriptionPlan.ENTERPRISE_PRO => 'Pro',
};

String paywallPrettyName(SubscriptionPlan plan) => switch (plan) {
  SubscriptionPlan.FREE => 'FREE',
  SubscriptionPlan.PREMIUM => 'Premium',
  SubscriptionPlan.ENTERPRISE => 'Enterprise',
  SubscriptionPlan.ENTERPRISE_PRO => 'Enterprise Pro',
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

bool paywallCompareCellIncluded(String value) {
  final t = value.trim();
  return t.isNotEmpty && t != '—';
}

PaywallCompareView buildPaywallCompareView({
  required SubscriptionPlan selected,
  required SubscriptionPlan current,
  List<PaywallComparisonRow> rows = PaywallCatalog.comparisonRows,
}) {
  const baseline = SubscriptionPlan.FREE;
  final showTwo = selected != SubscriptionPlan.FREE;
  final mapped =
      rows
          .map((row) {
            final parsed = PaywallCatalog.parseFeatureLabel(row.feature);
            return PaywallCompareRow(
              feature: parsed.label,
              baseline: row.valueFor(baseline),
              selected: row.valueFor(selected),
            );
          })
          .toList(growable: false);

  return PaywallCompareView(
    selected: selected,
    baseline: baseline,
    headline: paywallCompareHeadline(selected: selected, current: current),
    subtitle: PaywallCatalog.subtitleForPlan(selected),
    baselineColumnLabel: paywallTabLabel(baseline),
    selectedColumnLabel: paywallTabLabel(selected),
    rows: mapped,
    showTwoColumns: showTwo,
    showBillingToggle: selected != SubscriptionPlan.FREE,
  );
}

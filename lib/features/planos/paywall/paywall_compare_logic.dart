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

String paywallCompareSubtitle({required SubscriptionPlan selected}) {
  return PaywallCatalog.subtitleForPlan(selected);
}

bool paywallCompareCellIncluded(String value) {
  final t = value.trim();
  return t.isNotEmpty && t != '—';
}

/// Só o que muda de um plano para outro, até [limite] linhas.
List<PaywallComparisonRow> paywallLinhasDecisivas(
  List<PaywallComparisonRow> rows, {
  int limite = 6,
}) => rows.where((r) => r.free.trim() != r.paid.trim()).take(limite).toList();

/// O que o plano traz, com o valor junto; linhas com número vêm primeiro.
List<String> paywallInclusos(List<PaywallComparisonRow> rows) {
  final inclusas = rows.where((r) => paywallCompareCellIncluded(r.paid));
  return [
    ...inclusas.where((r) => r.paid.trim() != '✓'),
    ...inclusas.where((r) => r.paid.trim() == '✓'),
  ].map(_inclusoTexto).toList(growable: false);
}

String _inclusoTexto(PaywallComparisonRow row) {
  final bruto = PaywallCatalog.parseFeatureLabel(row.feature).label;
  final porMes = bruto.endsWith(' / mês');
  final label = porMes ? bruto.substring(0, bruto.length - 6) : bruto;
  final valor = row.paid.trim();
  if (valor == '✓') return label;
  if (valor == '∞') return '$label sem limite';
  return porMes ? '$label: $valor por mês' : '$label: $valor';
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
    subtitle: paywallCompareSubtitle(selected: selected),
    baselineColumnLabel: paywallTabLabel(baseline),
    selectedColumnLabel: paywallTabLabel(selected),
    rows: mapped,
    showTwoColumns: showTwo,
    // Gestão do plano máximo: sem toggle mensal/anual (não há checkout de upgrade).
    showBillingToggle: selected != SubscriptionPlan.FREE && !managingCurrent,
  );
}

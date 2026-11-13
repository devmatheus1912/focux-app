import '../../subscription/models/subscription_plan.dart';
import 'paywall_catalog.dart';

/// Comparações da vitrine (BFF `/api/planos/paywall/home` ou fallback estático).
///
/// Só carrega o que o compare-stage consome (`rowsFor`). Social proof / ROI strip
/// da vitrine antiga foram retirados — não há UI que os renderize.
class PaywallVitrineSnapshot {
  const PaywallVitrineSnapshot({
    this.comparisonFreeVsPro = const [],
    this.comparisonFreeVsEnterprise = const [],
    this.comparisonProVsEnterprise = const [],
  });

  final List<PaywallComparisonRow> comparisonFreeVsPro;
  final List<PaywallComparisonRow> comparisonFreeVsEnterprise;

  /// Quem já é Pro vê só o que muda no Enterprise.
  final List<PaywallComparisonRow> comparisonProVsEnterprise;

  List<PaywallComparisonRow> rowsFor(
    SubscriptionPlan plan, {
    SubscriptionPlan current = SubscriptionPlan.FREE,
  }) => switch (plan) {
    SubscriptionPlan.ENTERPRISE when current == SubscriptionPlan.PRO =>
      comparisonProVsEnterprise.isNotEmpty
          ? comparisonProVsEnterprise
          : PaywallCatalog.comparisonProVsEnterprise,
    SubscriptionPlan.ENTERPRISE =>
      comparisonFreeVsEnterprise.isNotEmpty
          ? comparisonFreeVsEnterprise
          : PaywallCatalog.comparisonFreeVsEnterprise,
    _ =>
      comparisonFreeVsPro.isNotEmpty
          ? comparisonFreeVsPro
          : PaywallCatalog.comparisonFreeVsPro,
  };

  factory PaywallVitrineSnapshot.fromApi(Map<String, dynamic> json) {
    final comparisonPro = _parseComparisonRows(
      json['comparisonFreeVsPro'] ?? json['comparisonRows'],
    );
    final comparisonEnt = _parseComparisonRows(
      json['comparisonFreeVsEnterprise'],
    );
    final comparisonProEnt = _parseComparisonRows(
      json['comparisonProVsEnterprise'],
    );
    if (comparisonPro.isEmpty && comparisonEnt.isEmpty) {
      return PaywallVitrineSnapshot.fromCatalog();
    }
    return PaywallVitrineSnapshot(
      comparisonFreeVsPro: comparisonPro,
      comparisonFreeVsEnterprise: comparisonEnt,
      comparisonProVsEnterprise: comparisonProEnt,
    );
  }

  factory PaywallVitrineSnapshot.fromCatalog() => PaywallVitrineSnapshot(
    comparisonFreeVsPro: PaywallCatalog.comparisonFreeVsPro,
    comparisonFreeVsEnterprise: PaywallCatalog.comparisonFreeVsEnterprise,
    comparisonProVsEnterprise: PaywallCatalog.comparisonProVsEnterprise,
  );

  static List<PaywallComparisonRow> _parseComparisonRows(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) {
          final m = e as Map<String, dynamic>;
          final feature = m['feature'] as String? ?? '';
          if (feature.isEmpty) return null;
          return PaywallComparisonRow(
            feature: feature,
            free: m['free'] as String? ?? '—',
            paid:
                m['paid'] as String? ??
                m['pro'] as String? ??
                m['premium'] as String? ??
                '—',
          );
        })
        .whereType<PaywallComparisonRow>()
        .toList();
  }
}

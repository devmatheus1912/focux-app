import 'package:flutter/material.dart';

import '../../subscription/models/subscription_plan.dart';
import 'paywall_catalog.dart';
import 'paywall_price.dart';

/// Conteúdo educativo da vitrine (BFF `/api/planos/paywall/home` ou fallback estático).
class PaywallVitrineSnapshot {
  const PaywallVitrineSnapshot({
    required this.socialProof,
    this.roiStrip = const [],
    this.comparisonFreeVsPro = const [],
    this.comparisonFreeVsEnterprise = const [],
    this.trialDaysOffer,
    this.fromApi = false,
    this.version,
  });

  final List<({String value, String label})> socialProof;
  final List<({String value, String label, Color color})> roiStrip;
  final List<PaywallComparisonRow> comparisonFreeVsPro;
  final List<PaywallComparisonRow> comparisonFreeVsEnterprise;
  final int? trialDaysOffer;
  final bool fromApi;
  final String? version;

  List<({String value, String label, Color color})> get effectiveRoiStrip =>
      roiStrip.isNotEmpty ? roiStrip : PaywallCatalog.roiStrip;

  List<PaywallComparisonRow> get effectiveComparisonRows =>
      comparisonFreeVsPro.isNotEmpty
          ? comparisonFreeVsPro
          : PaywallCatalog.comparisonFreeVsPro;

  List<PaywallComparisonRow> rowsFor(SubscriptionPlan plan) => switch (plan) {
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
    final social = _parseSocialProof(json['socialProof']);
    final roi = _parseRoiStrip(json['roiStrip']);
    final comparisonPro = _parseComparisonRows(
      json['comparisonFreeVsPro'] ?? json['comparisonRows'],
    );
    final comparisonEnt = _parseComparisonRows(json['comparisonFreeVsEnterprise']);
    final trial = (json['trialDaysOffer'] as num?)?.toInt();
    final version = json['version'] as String?;
    if (social.isEmpty &&
        roi.isEmpty &&
        comparisonPro.isEmpty &&
        comparisonEnt.isEmpty &&
        trial == null) {
      return PaywallVitrineSnapshot.fromCatalog();
    }
    return PaywallVitrineSnapshot(
      socialProof: social.isNotEmpty ? social : PaywallCatalog.socialProof,
      roiStrip: roi,
      comparisonFreeVsPro: comparisonPro,
      comparisonFreeVsEnterprise: comparisonEnt,
      trialDaysOffer: trial,
      fromApi: true,
      version: version,
    );
  }

  factory PaywallVitrineSnapshot.fromCatalog() => PaywallVitrineSnapshot(
    socialProof: PaywallCatalog.socialProof,
    roiStrip: PaywallCatalog.roiStrip,
    comparisonFreeVsPro: PaywallCatalog.comparisonFreeVsPro,
    comparisonFreeVsEnterprise: PaywallCatalog.comparisonFreeVsEnterprise,
    trialDaysOffer: kPaywallMaxPlanTrialDays,
    fromApi: false,
    version: null,
  );

  static List<({String value, String label})> _parseSocialProof(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) {
          final m = e as Map<String, dynamic>;
          return (
            value: m['value'] as String? ?? '',
            label: m['label'] as String? ?? '',
          );
        })
        .where((e) => e.value.isNotEmpty)
        .toList();
  }

  static List<({String value, String label, Color color})> _parseRoiStrip(
    Object? raw,
  ) {
    if (raw is! List) return const [];
    return raw
        .map((e) {
          final m = e as Map<String, dynamic>;
          final value = m['value'] as String? ?? '';
          final label = m['label'] as String? ?? '';
          if (value.isEmpty) return null;
          return (
            value: value,
            label: label,
            color: _toneColor(m['tone'] as String?),
          );
        })
        .whereType<({String value, String label, Color color})>()
        .toList();
  }

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
            paid: m['paid'] as String? ??
                m['pro'] as String? ??
                m['premium'] as String? ??
                '—',
          );
        })
        .whereType<PaywallComparisonRow>()
        .toList();
  }

  static Color _toneColor(String? tone) => switch (tone) {
    'gold' => PaywallCatalog.tierEnterprise,
    'green' => PaywallCatalog.green,
    'purple' => PaywallCatalog.brandDeep,
    'brandDeep' => PaywallCatalog.brandDeep,
    'brand' => PaywallCatalog.brand,
    _ => PaywallCatalog.brand,
  };
}

import 'package:flutter/material.dart';

import 'paywall_catalog.dart';

/// Conteúdo educativo da vitrine (API `/api/planos/vitrine` ou fallback estático).
class PaywallVitrineSnapshot {
  const PaywallVitrineSnapshot({
    required this.socialProof,
    this.roiStrip = const [],
    this.comparisonRows = const [],
    this.trialDaysOffer,
    this.fromApi = false,
    this.version,
  });

  final List<({String value, String label})> socialProof;
  final List<({String value, String label, Color color})> roiStrip;
  final List<PaywallComparisonRow> comparisonRows;
  final int? trialDaysOffer;
  final bool fromApi;
  final String? version;

  List<({String value, String label, Color color})> get effectiveRoiStrip =>
      roiStrip.isNotEmpty ? roiStrip : PaywallCatalog.roiStrip;

  List<PaywallComparisonRow> get effectiveComparisonRows =>
      comparisonRows.isNotEmpty
          ? comparisonRows
          : PaywallCatalog.comparisonRows;

  factory PaywallVitrineSnapshot.fromApi(Map<String, dynamic> json) {
    final social = _parseSocialProof(json['socialProof']);
    final roi = _parseRoiStrip(json['roiStrip']);
    final comparison = _parseComparisonRows(json['comparisonRows']);
    final trial = (json['trialDaysOffer'] as num?)?.toInt();
    final version = json['version'] as String?;
    if (social.isEmpty && roi.isEmpty && comparison.isEmpty && trial == null) {
      return PaywallVitrineSnapshot.fromCatalog();
    }
    return PaywallVitrineSnapshot(
      socialProof: social.isNotEmpty ? social : PaywallCatalog.socialProof,
      roiStrip: roi,
      comparisonRows: comparison,
      trialDaysOffer: trial,
      fromApi: true,
      version: version,
    );
  }

  factory PaywallVitrineSnapshot.fromCatalog() => PaywallVitrineSnapshot(
    socialProof: PaywallCatalog.socialProof,
    roiStrip: PaywallCatalog.roiStrip,
    comparisonRows: PaywallCatalog.comparisonRows,
    trialDaysOffer: 14,
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
            premium: m['premium'] as String? ?? '—',
            enterprise: m['enterprise'] as String? ?? '—',
            enterprisePro:
                m['enterprisePro'] as String? ?? m['entPro'] as String? ?? '—',
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

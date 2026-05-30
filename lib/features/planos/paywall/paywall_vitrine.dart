import 'package:flutter/material.dart';

import 'paywall_catalog.dart';

/// Conteúdo educativo da vitrine (API `/api/planos/vitrine` ou fallback estático).
class PaywallVitrineSnapshot {
  const PaywallVitrineSnapshot({
    required this.socialProof,
    this.roiStrip = const [],
    this.trialDaysOffer,
    this.fromApi = false,
  });

  final List<({String value, String label})> socialProof;
  final List<({String value, String label, Color color})> roiStrip;
  final int? trialDaysOffer;
  final bool fromApi;

  List<({String value, String label, Color color})> get effectiveRoiStrip =>
      roiStrip.isNotEmpty ? roiStrip : PaywallCatalog.roiStrip;

  factory PaywallVitrineSnapshot.fromApi(Map<String, dynamic> json) {
    final social = _parseSocialProof(json['socialProof']);
    final roi = _parseRoiStrip(json['roiStrip']);
    final trial = (json['trialDaysOffer'] as num?)?.toInt();
    if (social.isEmpty && roi.isEmpty && trial == null) {
      return PaywallVitrineSnapshot.fromCatalog();
    }
    return PaywallVitrineSnapshot(
      socialProof: social.isNotEmpty ? social : PaywallCatalog.socialProof,
      roiStrip: roi,
      trialDaysOffer: trial,
      fromApi: true,
    );
  }

  factory PaywallVitrineSnapshot.fromCatalog() => PaywallVitrineSnapshot(
    socialProof: PaywallCatalog.socialProof,
    roiStrip: PaywallCatalog.roiStrip,
    trialDaysOffer: 14,
    fromApi: false,
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

  static Color _toneColor(String? tone) => switch (tone) {
    'gold' => PaywallCatalog.gold,
    'green' => PaywallCatalog.green,
    'purple' => PaywallCatalog.purple,
    'brand' => PaywallCatalog.brand,
    _ => PaywallCatalog.brand,
  };
}

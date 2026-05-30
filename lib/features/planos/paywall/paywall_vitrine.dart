import 'paywall_catalog.dart';

/// Prova social da vitrine (API ou fallback estático).
class PaywallVitrineSnapshot {
  const PaywallVitrineSnapshot({required this.socialProof});

  final List<({String value, String label})> socialProof;

  factory PaywallVitrineSnapshot.fromApi(Map<String, dynamic> json) {
    final raw = json['socialProof'] as List<dynamic>? ?? const [];
    final items = raw
        .map((e) {
          final m = e as Map<String, dynamic>;
          return (
            value: m['value'] as String? ?? '',
            label: m['label'] as String? ?? '',
          );
        })
        .where((e) => e.value.isNotEmpty)
        .toList();
    if (items.isEmpty) return PaywallVitrineSnapshot.fromCatalog();
    return PaywallVitrineSnapshot(socialProof: items);
  }

  factory PaywallVitrineSnapshot.fromCatalog() =>
      PaywallVitrineSnapshot(socialProof: PaywallCatalog.socialProof);
}

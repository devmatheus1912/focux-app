import 'focux_brand_copy.dart';

/// Item de prova social do catálogo público (borda API → UI).
class BrandSocialProofItem {
  const BrandSocialProofItem({required this.value, required this.label});

  final String value;
  final String label;

  factory BrandSocialProofItem.fromJson(Map<String, dynamic> json) {
    return BrandSocialProofItem(
      value: (json['value'] as String?)?.trim() ?? '',
      label: (json['label'] as String?)?.trim() ?? '',
    );
  }

  bool get isValid => value.isNotEmpty && label.isNotEmpty;
}

/// Monta a linha do pill a partir do pulse; fallback neutro se vazio/inválido.
String formatBrandSocialProofLine(List<BrandSocialProofItem> items) {
  final valid = items.where((i) => i.isValid).toList();
  if (valid.isEmpty) {
    return FocuxBrandCopy.onboardingSocialProofFallback;
  }
  final first = valid.first;
  return '${first.value} ${first.label}';
}

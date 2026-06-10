/// Extracts kg delta between current and suggested loads for progressão cards.
String? computeProgressaoDeltaLabel(String cargaAtual, String cargaSugerida) {
  final atual = _parseKg(cargaAtual);
  final sugerida = _parseKg(cargaSugerida);
  if (atual == null || sugerida == null) return null;

  final delta = sugerida - atual;
  if (delta.abs() < 0.01) return null;

  final sign = delta > 0 ? '+' : '';
  final abs = delta.abs();
  final formatted =
      abs == abs.roundToDouble()
          ? abs.toStringAsFixed(0)
          : abs.toStringAsFixed(1).replaceAll('.', ',');
  return '$sign$formatted kg';
}

double? _parseKg(String value) {
  final match = RegExp(
    r'(\d+(?:[,.]\d+)?)\s*kg',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return null;
  return double.tryParse(match.group(1)!.replaceAll(',', '.'));
}

/// Extracts kg or volume delta between current and suggested loads.
String? computeProgressaoDeltaLabel(String cargaAtual, String cargaSugerida) {
  final kgDelta = _computeKgDeltaLabel(cargaAtual, cargaSugerida);
  if (kgDelta != null) return kgDelta;
  return _computeVolumeDeltaLabel(cargaAtual, cargaSugerida);
}

String? _computeKgDeltaLabel(String cargaAtual, String cargaSugerida) {
  final atual = _parseKg(cargaAtual);
  final sugerida = _parseKg(cargaSugerida);
  if (atual == null || sugerida == null) return null;

  final delta = sugerida - atual;
  if (delta.abs() < 0.01) return null;

  return _formatSignedDelta(delta, 'kg');
}

String? _computeVolumeDeltaLabel(String cargaAtual, String cargaSugerida) {
  final atual = _parseSeriesReps(cargaAtual);
  final sugerida = _parseSeriesReps(cargaSugerida);
  if (atual == null || sugerida == null) return null;

  final semKg =
      _parseKg(cargaAtual) == null || _parseKg(cargaSugerida) == null;
  if (semKg && (atual.$1 != sugerida.$1 || atual.$2 != sugerida.$2)) {
    return '${atual.$1}x${atual.$2} → ${sugerida.$1}x${sugerida.$2}';
  }

  if (atual.$1 == sugerida.$1) {
    final repDelta = sugerida.$2 - atual.$2;
    if (repDelta != 0) {
      return _formatSignedDelta(repDelta.toDouble(), 'reps', integer: true);
    }
  }

  final volumeDelta = (sugerida.$1 * sugerida.$2) - (atual.$1 * atual.$2);
  if (volumeDelta == 0) return null;
  return _formatSignedDelta(volumeDelta.toDouble(), 'reps totais', integer: true);
}

String _formatSignedDelta(double delta, String unit, {bool integer = false}) {
  final sign = delta > 0 ? '+' : '';
  final abs = delta.abs();
  final formatted = integer
      ? abs.round().toString()
      : abs == abs.roundToDouble()
      ? abs.toStringAsFixed(0)
      : abs.toStringAsFixed(1).replaceAll('.', ',');
  return '$sign$formatted $unit';
}

(int series, int reps)? _parseSeriesReps(String value) {
  final match = RegExp(
    r'(\d+)\s*[x×]\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return null;
  final series = int.tryParse(match.group(1)!);
  final reps = int.tryParse(match.group(2)!);
  if (series == null || reps == null) return null;
  return (series, reps);
}

double? _parseKg(String value) {
  final match = RegExp(
    r'(\d+(?:[,.]\d+)?)\s*kg',
    caseSensitive: false,
  ).firstMatch(value.trim());
  if (match == null) return null;
  return double.tryParse(match.group(1)!.replaceAll(',', '.'));
}

/// Normaliza altura bruta (pode vir em cm quando > 3) para metros.
double normalizeAlturaMeters(double raw) {
  if (raw > 3) return raw / 100;
  return raw;
}

class AlturaDisplay {
  final String value;
  final String unit;

  const AlturaDisplay({required this.value, required this.unit});
}

/// Formata altura para exibição na ficha do aluno.
AlturaDisplay formatAlturaDisplay(double? raw) {
  if (raw == null) {
    return const AlturaDisplay(value: '—', unit: 'm');
  }
  final meters = normalizeAlturaMeters(raw);
  return AlturaDisplay(value: meters.toStringAsFixed(2), unit: 'm');
}

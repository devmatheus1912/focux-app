/// Volume de treino em kg (carga×reps). Nunca rotular como "t" sem conversão clara.
String formatAlunoVolumeKg(double value) {
  if (value <= 0) return '--';
  if (value >= 1000) {
    final mil = value / 1000;
    final milLabel =
        mil == mil.roundToDouble()
            ? mil.toStringAsFixed(0)
            : mil.toStringAsFixed(1);
    return '$milLabel mil kg';
  }
  return '${value.round()} kg';
}

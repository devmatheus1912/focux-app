List<double> parseAlunoHomeSeries(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => (e as num?)?.toDouble() ?? 0.0)
      .toList(growable: false);
}

/// Semanas `> 0` da série semanal. `<= 0` são buracos — fora do min/max.
class AlunoTrendPlot {
  const AlunoTrendPlot({
    required this.indexes,
    required this.values,
    required this.minVal,
    required this.maxVal,
    required this.slotCount,
  });

  final List<int> indexes;
  final List<double> values;
  final double minVal;
  final double maxVal;
  final int slotCount;

  double get span =>
      (maxVal - minVal).abs() < 0.001 ? 1.0 : maxVal - minVal;

  bool startsSegment(int pointIndex) =>
      pointIndex == 0 || indexes[pointIndex] != indexes[pointIndex - 1] + 1;

  bool isIsolated(int pointIndex) {
    final prev =
        pointIndex > 0 && indexes[pointIndex] == indexes[pointIndex - 1] + 1;
    final next =
        pointIndex + 1 < indexes.length &&
        indexes[pointIndex + 1] == indexes[pointIndex] + 1;
    return !prev && !next;
  }
}

/// `null` quando a série não tem valor positivo.
AlunoTrendPlot? alunoTrendPlot(List<double> data) {
  final indexes = <int>[];
  final values = <double>[];
  double? minVal;
  double? maxVal;
  for (var i = 0; i < data.length; i++) {
    final v = data[i];
    if (v <= 0) continue;
    indexes.add(i);
    values.add(v);
    minVal = minVal == null || v < minVal ? v : minVal;
    maxVal = maxVal == null || v > maxVal ? v : maxVal;
  }
  if (indexes.isEmpty) return null;
  return AlunoTrendPlot(
    indexes: List.unmodifiable(indexes),
    values: List.unmodifiable(values),
    minVal: minVal!,
    maxVal: maxVal!,
    slotCount: data.length,
  );
}

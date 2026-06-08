/// Volume sparkline resolution for Evolução inteligente card.
class Aluno360EvolucaoInteligenteLogic {
  Aluno360EvolucaoInteligenteLogic._();

  /// Returns sparkline data; duplicates a single non-zero week so the chart renders.
  static List<double> resolveVolumeSparklineData(List<double> volumePorSemana) {
    final nonZero = volumePorSemana.where((v) => v > 0).toList();
    if (nonZero.isEmpty) return const [];
    if (nonZero.length == 1) return [nonZero.first, nonZero.first];
    return volumePorSemana;
  }

  static bool isSingleWeekVolume(List<double> volumePorSemana) {
    return volumePorSemana.where((v) => v > 0).length == 1;
  }
}

/// Volume sparkline resolution for Evolução inteligente card.
class Aluno360EvolucaoInteligenteLogic {
  Aluno360EvolucaoInteligenteLogic._();

  /// Soft-cap de leitura: % WoW absurdo (baseline pequena) vira texto.
  static const int tendenciaPctSoftCap = 200;

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

  /// Rótulo legível da tendência WoW — evita `+596%` no fold.
  static String? formatTendenciaVolumeHint(int? pct) {
    if (pct == null) return null;
    if (pct.abs() > tendenciaPctSoftCap) {
      return pct > 0
          ? 'Volume bem acima da semana anterior'
          : 'Volume bem abaixo da semana anterior';
    }
    final sign = pct > 0 ? '+' : '';
    return '$sign$pct% vs semana anterior';
  }

  static String? composeSinalHint({
    required String resumo,
    int? tendenciaPct,
  }) {
    final parts = <String>[];
    final trimmed = resumo.trim();
    if (trimmed.isNotEmpty) parts.add(trimmed);
    final tendencia = formatTendenciaVolumeHint(tendenciaPct);
    if (tendencia != null) parts.add(tendencia);
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }
}

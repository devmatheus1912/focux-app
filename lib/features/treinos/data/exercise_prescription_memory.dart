/// Última prescrição usada ao adicionar exercício (para repetir no próximo).
class ExercisePrescriptionMemory {
  const ExercisePrescriptionMemory({
    required this.presetId,
    required this.series,
    required this.repeticoes,
    required this.descansoSegundos,
    required this.tipoSerie,
    this.cargaKg,
    this.observacoes = '',
    this.grupoSuperset,
  });

  final String presetId;
  final int series;
  final String repeticoes;
  final int descansoSegundos;
  final String tipoSerie;
  final double? cargaKg;
  final String observacoes;
  final int? grupoSuperset;

  String get summary => '$series×$repeticoes · ${descansoSegundos}s descanso';
}

class WorkoutBuilderPreset {
  final String id;
  final String label;
  final String summary;
  final int series;
  final String repeticoes;
  final int descansoSegundos;
  final String tipoSerie;
  final String observacoes;
  final int? grupoSuperset;

  const WorkoutBuilderPreset({
    required this.id,
    required this.label,
    required this.summary,
    required this.series,
    required this.repeticoes,
    required this.descansoSegundos,
    required this.tipoSerie,
    required this.observacoes,
    this.grupoSuperset,
  });
}

/// Presets de volume — tipo de série (normal/superset/drop) fica no seletor dedicado.
const workoutBuilderPresets = [
  WorkoutBuilderPreset(
    id: 'hypertrophy',
    label: 'Hipertrofia',
    summary: 'Volume controlado para ganho de massa.',
    series: 4,
    repeticoes: '8-12',
    descansoSegundos: 75,
    tipoSerie: 'NORMAL',
    observacoes: 'Priorizar amplitude, controle e falha técnica próxima.',
  ),
  WorkoutBuilderPreset(
    id: 'strength',
    label: 'Força',
    summary: 'Carga alta com descanso maior.',
    series: 5,
    repeticoes: '3-6',
    descansoSegundos: 150,
    tipoSerie: 'NORMAL',
    observacoes: 'Usar carga alta, técnica limpa e descanso completo.',
  ),
  WorkoutBuilderPreset(
    id: 'endurance',
    label: 'Resistência',
    summary: 'Mais repetições e pausa curta.',
    series: 3,
    repeticoes: '15-20',
    descansoSegundos: 45,
    tipoSerie: 'NORMAL',
    observacoes: 'Manter ritmo constante e respiração controlada.',
  ),
];

WorkoutBuilderPreset workoutBuilderPresetById(String id) {
  return workoutBuilderPresets.firstWhere(
    (preset) => preset.id == id,
    orElse: () => workoutBuilderPresets.first,
  );
}

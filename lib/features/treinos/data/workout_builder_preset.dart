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

const workoutBuilderPresets = [
  WorkoutBuilderPreset(
    id: 'hypertrophy',
    label: 'Hipertrofia',
    summary: 'Volume controlado para ganho de massa.',
    series: 4,
    repeticoes: '8-12',
    descansoSegundos: 75,
    tipoSerie: 'NORMAL',
    observacoes: 'Priorizar amplitude, controle e falha tecnica proxima.',
  ),
  WorkoutBuilderPreset(
    id: 'strength',
    label: 'Forca',
    summary: 'Carga alta com descanso maior.',
    series: 5,
    repeticoes: '3-6',
    descansoSegundos: 150,
    tipoSerie: 'NORMAL',
    observacoes: 'Usar carga alta, tecnica limpa e descanso completo.',
  ),
  WorkoutBuilderPreset(
    id: 'endurance',
    label: 'Resistencia',
    summary: 'Mais repeticoes e pausa curta.',
    series: 3,
    repeticoes: '15-20',
    descansoSegundos: 45,
    tipoSerie: 'NORMAL',
    observacoes: 'Manter ritmo constante e respiracao controlada.',
  ),
  WorkoutBuilderPreset(
    id: 'superset',
    label: 'Superset',
    summary: 'Agrupa exercicios sem pausa entre eles.',
    series: 3,
    repeticoes: '10-12',
    descansoSegundos: 90,
    tipoSerie: 'SUPERSET',
    grupoSuperset: 1,
    observacoes: 'Executar em sequencia com o outro exercicio do grupo.',
  ),
  WorkoutBuilderPreset(
    id: 'dropset',
    label: 'Drop set',
    summary: 'Intensificador com reducao de carga.',
    series: 3,
    repeticoes: '8-10 + drop',
    descansoSegundos: 90,
    tipoSerie: 'DROPSET',
    observacoes: 'Apos a serie principal, reduzir a carga e continuar com boa tecnica.',
  ),
];

WorkoutBuilderPreset workoutBuilderPresetById(String id) {
  return workoutBuilderPresets.firstWhere(
    (preset) => preset.id == id,
    orElse: () => workoutBuilderPresets.first,
  );
}

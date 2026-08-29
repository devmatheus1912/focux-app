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

/// Escolhe o preset mais próximo da prescrição já salva (edição no detalhe).
String matchWorkoutBuilderPresetId({
  required int series,
  required String repeticoes,
  required int descansoSegundos,
}) {
  final reps = repeticoes.trim().toLowerCase();
  for (final preset in workoutBuilderPresets) {
    if (preset.series == series &&
        preset.repeticoes.toLowerCase() == reps &&
        preset.descansoSegundos == descansoSegundos) {
      return preset.id;
    }
  }

  var best = workoutBuilderPresets.first;
  var bestScore = 1 << 30;
  for (final preset in workoutBuilderPresets) {
    var score =
        (preset.series - series).abs() * 10 +
        (preset.descansoSegundos - descansoSegundos).abs();
    if (preset.repeticoes.toLowerCase() == reps) score -= 20;
    if (score < bestScore) {
      bestScore = score;
      best = preset;
    }
  }
  return best.id;
}

/// Atalhos de repetição por objetivo — 1 toque no sheet de reps.
List<String> workoutBuilderRepShortcuts(String presetId) {
  return switch (presetId) {
    'strength' => const ['3-6', '4-6', '5'],
    'endurance' => const ['15-20', '12-20', 'AMRAP'],
    _ => const ['8-12', '10-15', '12-15'],
  };
}

String workoutTipoSerieLabel(String tipoSerie) {
  return switch (tipoSerie.trim().toUpperCase()) {
    'SUPERSET' => 'Superset',
    'DROPSET' => 'Drop set',
    _ => 'Normal',
  };
}

String? workoutTipoSerieSubtitle(String tipoSerie) {
  return switch (tipoSerie.trim().toUpperCase()) {
    'SUPERSET' => 'Dois exercícios sem pausa entre eles.',
    'DROPSET' => 'Reduza a carga nas observações.',
    _ => 'Séries isoladas com descanso.',
  };
}

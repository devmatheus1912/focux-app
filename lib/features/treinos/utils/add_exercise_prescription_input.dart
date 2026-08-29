import 'treino_prescription_rules.dart';

/// Valores de prescrição resolvidos para adicionar exercício ao treino.
class AddExercisePrescriptionInput {
  const AddExercisePrescriptionInput({
    required this.series,
    required this.repeticoes,
    required this.descansoSegundos,
    this.cargaKg,
    this.observacoes,
    required this.tipoSerie,
    this.grupoSuperset,
  });

  final int series;
  final String repeticoes;
  final int descansoSegundos;
  final double? cargaKg;
  final String? observacoes;
  final String tipoSerie;
  final int? grupoSuperset;
}

/// Resolve e valida prescrição antes do POST — paridade com detalhe do treino.
({String? error, AddExercisePrescriptionInput? values}) resolveAddExercisePrescription({
  required String seriesText,
  required String repeticoesText,
  required String descansoText,
  required String cargaText,
  required String observacoesText,
  required String tipoSerie,
  required String grupoSupersetText,
}) {
  final series = int.tryParse(seriesText.trim());
  if (series == null) {
    return (error: 'Informe um número válido de séries.', values: null);
  }

  final descanso = int.tryParse(descansoText.trim());
  if (descanso == null) {
    return (error: 'Informe um descanso válido em segundos.', values: null);
  }

  final rejection = treinoPrescriptionRejection(
    series: series,
    descansoSegundos: descanso,
  );
  if (rejection != null) {
    return (error: rejection, values: null);
  }

  final reps = repeticoesText.trim();
  if (reps.isEmpty) {
    return (error: 'Informe as repetições.', values: null);
  }

  int? grupoSuperset;
  if (tipoSerie == 'SUPERSET') {
    grupoSuperset = int.tryParse(grupoSupersetText.trim());
    if (grupoSuperset == null || grupoSuperset < 1) {
      return (
        error: 'Informe o grupo do superset (número a partir de 1).',
        values: null,
      );
    }
  }

  final cargaRaw = cargaText.trim();
  double? cargaKg;
  if (cargaRaw.isNotEmpty) {
    cargaKg = double.tryParse(cargaRaw.replaceAll(',', '.'));
    if (cargaKg == null) {
      return (error: 'Carga inválida. Use apenas números.', values: null);
    }
  }

  final observacoes = observacoesText.trim();

  return (
    error: null,
    values: AddExercisePrescriptionInput(
      series: series,
      repeticoes: reps,
      descansoSegundos: descanso,
      cargaKg: cargaKg,
      observacoes: observacoes.isEmpty ? null : observacoes,
      tipoSerie: tipoSerie,
      grupoSuperset: grupoSuperset,
    ),
  );
}

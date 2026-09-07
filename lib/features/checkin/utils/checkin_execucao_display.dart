import '../../../core/theme/tokens_strip.dart';

/// Thumb-zone minimum for S8 execution controls.
const double checkinExecutionControlMin = TokensStrip.s8;

Duration checkinElapsedSince(String? iniciadoEm, [DateTime? now]) {
  final origin = now ?? DateTime.now();
  if (iniciadoEm == null || iniciadoEm.isEmpty) {
    return Duration.zero;
  }
  try {
    return origin.difference(DateTime.parse(iniciadoEm).toLocal());
  } catch (_) {
    return Duration.zero;
  }
}

int checkinRestRemaining({required DateTime endsAt, DateTime? now}) {
  final left = endsAt.difference(now ?? DateTime.now()).inSeconds;
  return left < 0 ? 0 : left;
}

String checkinDurationLabel(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String checkinSerieKpiLabel(int feitas, int? total) {
  if (total == null || total <= 0) return '$feitas';
  return '$feitas/$total';
}

String checkinChromeContextLine({
  required String duration,
  required int concluido,
  required int total,
}) {
  if (total <= 0) return duration;
  return '$duration · $concluido/$total exercícios';
}

String checkinSeriesRepsLabel(int? series, String? reps) {
  final s = series == null ? '—' : '$series';
  final r = reps == null || reps.trim().isEmpty ? '—' : reps.trim();
  return '$s × $r';
}

String checkinSerieContextLine({
  required int index,
  required int total,
  required String seriesReps,
  String? carga,
  int? descansoSegundos,
}) {
  final parts = <String>[
    '$index/$total',
    seriesReps,
    if (carga != null && carga.trim().isNotEmpty) carga.trim(),
    if (descansoSegundos != null && descansoSegundos > 0)
      'descanso ${descansoSegundos}s',
  ];
  return parts.join(' · ');
}

String? checkinCargaLabel(double? value) {
  if (value == null) return null;
  final rounded =
      value.roundToDouble() == value
          ? value.toStringAsFixed(0)
          : value.toStringAsFixed(1);
  return '${rounded.replaceAll('.', ',')} kg';
}

String checkinKgLabel(double value) {
  final fixed = value.toStringAsFixed(
    value.truncateToDouble() == value ? 0 : 1,
  );
  return fixed.replaceAll('.', ',');
}

String checkinEvolucaoTipoLabel(String tipo) {
  switch (tipo) {
    case 'REPETICOES':
      return 'Repetições';
    case 'VOLUME':
      return 'Volume';
    default:
      return 'Carga';
  }
}

String checkinRegistrarLabel({required bool first}) =>
    first ? 'Registrar série' : 'Próxima série';

String checkinDesfazerLabel() => 'Desfazer série';

String checkinFinalizarLabel() => 'Finalizar treino';

String checkinPularDescansoLabel() => 'Pular descanso';

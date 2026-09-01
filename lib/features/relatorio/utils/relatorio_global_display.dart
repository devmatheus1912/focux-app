import '../../../core/utils/fx_utils.dart';

String relatorioAderenciaMediaLabel(double media) {
  return '${media.clamp(0, 100).toStringAsFixed(1)}%';
}

String relatorioAderenciaPercentLabel(int concluidos, int total) {
  if (total <= 0) return '0%';
  final pct = (concluidos * 100.0 / total).clamp(0, 100);
  return '${pct.toStringAsFixed(0)}%';
}

String relatorioTreinosSubtitle(int concluidos, int total) {
  if (total <= 0) return 'Ainda sem treinos';
  if (concluidos == 1 && total == 1) return '1 de 1 treino concluído';
  return '$concluidos de $total treinos concluídos';
}

String relatorioUltimoTreinoLabel(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return 'Sem treinos';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return fxDateFull(date);
}

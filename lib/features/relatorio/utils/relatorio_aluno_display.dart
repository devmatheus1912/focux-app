import '../../../core/utils/fx_utils.dart';

const relatorioAlunoPeriodoKeys = ['7', '30', '90', '180', 'custom'];

String relatorioAlunoPeriodoPresetLabel(int dias) {
  switch (dias) {
    case 7:
      return '7 dias';
    case 30:
      return '30 dias';
    case 90:
      return '3 meses';
    case 180:
      return '6 meses';
    default:
      return '$dias dias';
  }
}

String relatorioAlunoRangeLabel(DateTime start, DateTime end) {
  return '${fxDateShort(start)} – ${fxDateShort(end)}';
}

String relatorioAlunoPeriodoValueLabel({
  required int dias,
  DateTime? inicio,
  DateTime? fim,
}) {
  if (inicio != null && fim != null) {
    return relatorioAlunoRangeLabel(inicio, fim);
  }
  return relatorioAlunoPeriodoPresetLabel(dias);
}

String relatorioAlunoPeriodoKey({
  required int dias,
  required bool personalizado,
}) {
  if (personalizado) return 'custom';
  return '$dias';
}

String relatorioAlunoPeriodoOpcaoLabel(String key) {
  switch (key) {
    case '7':
      return '7 dias';
    case '30':
      return '30 dias';
    case '90':
      return '3 meses';
    case '180':
      return '6 meses';
    case 'custom':
      return 'Personalizado';
    default:
      return key;
  }
}

int? relatorioAlunoDiasFromKey(String key) {
  if (key == 'custom') return null;
  return int.tryParse(key);
}

String relatorioAlunoAderenciaStatus(double taxa) {
  if (taxa >= 75) return 'Excelente';
  if (taxa >= 50) return 'Regular';
  return 'Baixa';
}

bool relatorioAlunoAderenciaBaixa(double taxa) => taxa < 50;

bool relatorioAlunoMostraComparativo({required bool personalizado}) =>
    !personalizado;

String relatorioAlunoDeltaLabel(double delta) {
  if (delta > 0) return '+${delta.toStringAsFixed(1)}%';
  return '${delta.toStringAsFixed(1)}%';
}

String relatorioAlunoCheckinsLabel(int count) {
  if (count <= 0) return 'Nenhum';
  if (count == 1) return '1 check-in';
  return '$count check-ins';
}

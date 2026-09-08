import '../../../core/utils/fx_utils.dart';
import '../../../core/utils/pt_br_display.dart';

const relatorioAlunoPeriodoPresetKeys = ['7', '30', '90', '180'];

class RelatorioAlunoPeriodoOpcao {
  const RelatorioAlunoPeriodoOpcao({
    required this.key,
    required this.label,
    this.dias,
    this.inicio,
    this.fim,
  });

  final String key;
  final String label;
  final int? dias;
  final DateTime? inicio;
  final DateTime? fim;

  bool get isMes => inicio != null && fim != null;
}

String relatorioAlunoMesKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

DateTime relatorioAlunoMesInicio(DateTime d) => DateTime(d.year, d.month, 1);

DateTime relatorioAlunoMesFim(DateTime d) => DateTime(d.year, d.month + 1, 0);

int relatorioAlunoDiasDoRange(DateTime inicio, DateTime fim) {
  final start = DateTime(inicio.year, inicio.month, inicio.day);
  final end = DateTime(fim.year, fim.month, fim.day);
  return end.difference(start).inDays + 1;
}

bool relatorioAlunoRangeEhMesCheio(DateTime inicio, DateTime fim) {
  final start = DateTime(inicio.year, inicio.month, inicio.day);
  final end = DateTime(fim.year, fim.month, fim.day);
  final mesFim = relatorioAlunoMesFim(start);
  return start.day == 1 &&
      end.year == mesFim.year &&
      end.month == mesFim.month &&
      end.day == mesFim.day;
}

List<RelatorioAlunoPeriodoOpcao> relatorioAlunoPeriodoOpcoes({
  DateTime? agora,
}) {
  final now = agora ?? DateTime.now();
  final presets = [
    for (final key in relatorioAlunoPeriodoPresetKeys)
      RelatorioAlunoPeriodoOpcao(
        key: key,
        label: relatorioAlunoPeriodoPresetLabel(int.parse(key)),
        dias: int.parse(key),
      ),
  ];
  final meses = <RelatorioAlunoPeriodoOpcao>[];
  for (var i = 0; i < 6; i++) {
    final d = DateTime(now.year, now.month - i, 1);
    meses.add(
      RelatorioAlunoPeriodoOpcao(
        key: 'm:${relatorioAlunoMesKey(d)}',
        label: monthYearLabelPtBr(d),
        inicio: relatorioAlunoMesInicio(d),
        fim: relatorioAlunoMesFim(d),
      ),
    );
  }
  return [...presets, ...meses];
}

RelatorioAlunoPeriodoOpcao? relatorioAlunoPeriodoOpcaoByKey(
  String key, {
  DateTime? agora,
}) {
  for (final o in relatorioAlunoPeriodoOpcoes(agora: agora)) {
    if (o.key == key) return o;
  }
  if (!key.startsWith('m:') || key.length != 9) return null;
  final y = int.tryParse(key.substring(2, 6));
  final m = int.tryParse(key.substring(7, 9));
  if (y == null || m == null || m < 1 || m > 12) return null;
  final d = DateTime(y, m, 1);
  return RelatorioAlunoPeriodoOpcao(
    key: key,
    label: monthYearLabelPtBr(d),
    inicio: relatorioAlunoMesInicio(d),
    fim: relatorioAlunoMesFim(d),
  );
}

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
    if (relatorioAlunoRangeEhMesCheio(inicio, fim)) {
      return monthYearLabelPtBr(inicio);
    }
    return relatorioAlunoRangeLabel(inicio, fim);
  }
  return relatorioAlunoPeriodoPresetLabel(dias);
}

String relatorioAlunoPeriodoKey({
  required int dias,
  DateTime? inicio,
  DateTime? fim,
}) {
  if (inicio != null &&
      fim != null &&
      relatorioAlunoRangeEhMesCheio(inicio, fim)) {
    return 'm:${relatorioAlunoMesKey(inicio)}';
  }
  return '$dias';
}

String relatorioAlunoPeriodoOpcaoLabel(String key, {DateTime? agora}) {
  return relatorioAlunoPeriodoOpcaoByKey(key, agora: agora)?.label ?? key;
}

int? relatorioAlunoDiasFromKey(String key) {
  if (key.startsWith('m:')) return null;
  return int.tryParse(key);
}

String relatorioAlunoAderenciaStatus(double taxa) {
  if (taxa >= 75) return 'Excelente';
  if (taxa >= 50) return 'Regular';
  return 'Baixa';
}

bool relatorioAlunoAderenciaBaixa(double taxa) => taxa < 50;

String relatorioAlunoDeltaLabel(double delta) {
  if (delta > 0) return '+${delta.toStringAsFixed(1)}%';
  return '${delta.toStringAsFixed(1)}%';
}

String relatorioAlunoCheckinsLabel(int count) {
  if (count <= 0) return 'Nenhum';
  if (count == 1) return '1 check-in';
  return '$count check-ins';
}

String relatorioAlunoStickyExport() => 'Exportar PDF';

String relatorioAlunoStickyEmpty() => 'Ver evolução';

String relatorioAlunoCheckinChip() => 'Pedir check-in';

const relatorioDetalheSecaoResumo = 'resumo';
const relatorioDetalheSecaoComparativo = 'comparativo';

const relatorioDetalheSecoes = [
  (value: relatorioDetalheSecaoResumo, label: 'Resumo'),
  (value: relatorioDetalheSecaoComparativo, label: 'Versus'),
];

String relatorioAlunoHubSubtitle({
  required String alunoNome,
  required int diasAnalisados,
  String? freshness,
}) {
  final dias =
      diasAnalisados <= 0 ? alunoNome : '$alunoNome · $diasAnalisados dias';
  if (freshness == null || freshness.isEmpty) return dias;
  return '$dias · $freshness';
}

import 'plano_sucesso_model.dart';

String planoSucessoPercentLabel(int done, int total) {
  if (total <= 0) return '0%';
  return '${((done / total) * 100).round()}%';
}

String planoSucessoProgressHint(int done, int total) {
  if (total <= 0) return 'Sem etapas ainda';
  return '$done de $total etapas';
}

String planoSucessoRevisaoLabel(DateTime data) {
  final day = data.day.toString().padLeft(2, '0');
  final month = data.month.toString().padLeft(2, '0');
  return '$day/$month';
}

String planoSucessoMetricHint({
  required int done,
  required int total,
  required DateTime proximaRevisao,
}) {
  return '${planoSucessoProgressHint(done, total)} · revisão ${planoSucessoRevisaoLabel(proximaRevisao)}';
}

String planoSucessoMarcoSubtitle({
  required bool atingido,
  required bool atual,
}) {
  if (atingido) return 'Etapa concluída';
  if (atual) return 'Próxima etapa';
  return 'Pendente';
}

MarcoSucesso? planoSucessoProximoMarco(List<MarcoSucesso> marcos) {
  for (final marco in marcos) {
    if (!marco.atingido) return marco;
  }
  return null;
}

String planoSucessoRevisaoIso(DateTime data) {
  final y = data.year.toString().padLeft(4, '0');
  final m = data.month.toString().padLeft(2, '0');
  final d = data.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String planoSucessoStickyLabel({
  required bool hasPlano,
  required MarcoSucesso? proximo,
}) {
  if (!hasPlano) return 'Criar plano';
  if (proximo != null) return 'Marcar etapa';
  return 'Remarcar revisão';
}

String planoSucessoHubSubtitle({
  required String base,
  String? freshness,
}) {
  final parts = <String>[base];
  final stamp = freshness?.trim();
  if (stamp != null && stamp.isNotEmpty) parts.add(stamp);
  return parts.join(' · ');
}

String planoSucessoEtapasValue(int done, int total) => '$done/$total';

String planoSucessoEtapasHint({
  required int done,
  required int total,
  required MarcoSucesso? proximo,
}) {
  if (total <= 0) return 'Nenhuma etapa ainda';
  if (proximo == null) return 'Todas as etapas feitas';
  return '$done de $total · próxima etapa';
}

String planoSucessoRevisaoMetricValue(DateTime? data) {
  if (data == null) return '—';
  return planoSucessoRevisaoLabel(data);
}

String planoSucessoRevisaoMetricHint(DateTime? data) {
  if (data == null) return 'Sem data de revisão';
  return 'Próxima revisão';
}

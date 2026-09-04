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

String planoSucessoStickyLabel(MarcoSucesso? proximo) {
  if (proximo == null) return 'Criar plano';
  return 'Marcar etapa';
}

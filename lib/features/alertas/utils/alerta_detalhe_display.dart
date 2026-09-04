import '../../../core/utils/fx_utils.dart';

const alertaComoCalculamos =
    'Dispara se ficou sem treino além do prazo ou se a aderência caiu abaixo do limiar.';

String alertaCountLabel(int count) {
  if (count <= 0) return 'Nenhum em risco';
  if (count == 1) return '1 aluno em risco';
  return '$count alunos em risco';
}

String alertaAdiarCtaLabel() => 'Adiar 24h';

String alertaAdiarLoadingLabel() => 'Adiando…';

String alertaAdiadoSuccessMessage() => 'Alerta adiado por 24h.';

String alertaUltimoTreinoLabel(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return 'Sem treinos';
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return fxDateFull(date);
}

String alertaCheckinsLabel(int count) {
  if (count <= 0) return 'Nenhum em 30 dias';
  if (count == 1) return '1 em 30 dias';
  return '$count em 30 dias';
}

String alertaHubSubtitle({
  required String statusFinanceiro,
  String? freshness,
}) {
  final parts = <String>[alertaStatusFinanceiroLabel(statusFinanceiro)];
  final stamp = freshness?.trim();
  if (stamp != null && stamp.isNotEmpty) parts.add(stamp);
  return parts.join(' · ');
}

String alertaStatusFinanceiroLabel(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return 'Sem dado';
  final upper = value.toUpperCase();
  if (upper == 'ATIVO' ||
      upper == 'OK' ||
      upper.contains('EM DIA') ||
      upper.contains('EM_DIA')) {
    return 'Em dia';
  }
  if (upper.contains('INADIMPLENTE') || upper.contains('ATRASO')) {
    return 'Em atraso';
  }
  if (upper.contains('CANCELADO')) return 'Cancelado';
  return value;
}

bool alertaStatusFinanceiroRuim(String raw) {
  final upper = raw.trim().toUpperCase();
  return upper.contains('INADIMPLENTE') ||
      upper.contains('ATRASO') ||
      upper.contains('CANCELADO');
}

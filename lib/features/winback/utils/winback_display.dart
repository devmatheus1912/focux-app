import '../../../core/utils/fx_utils.dart';

String winbackAlunoLabel(String? nome) {
  final value = nome?.trim();
  if (value == null || value.isEmpty) return 'Aluno';
  return value;
}

String winbackTipoLabel(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'ALUNO_INATIVO_7D':
      return 'Inativo 7 dias';
    case 'ALUNO_INATIVO_30D':
      return 'Inativo 30 dias';
    case 'ALUNO_INATIVO_60D':
      return 'Inativo 60 dias';
    case '':
      return 'Envio automático';
    default:
      return tipo!.trim().replaceAll('_', ' ');
  }
}

String winbackFxIcon(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'ALUNO_INATIVO_60D':
      return 'alert-triangle';
    case 'ALUNO_INATIVO_30D':
      return 'trend';
    default:
      return 'bell';
  }
}

String winbackWhenLabel(String enviadoEm, {DateTime? now}) {
  final label = fxDateTimeLabelFromIso(enviadoEm, now: now);
  return label.isEmpty ? '—' : label;
}

/// `null` quando o push chegou ao provedor (ou log antigo sem status).
String? winbackEntregaFalhaLabel(String? status) =>
    switch ((status ?? '').trim().toUpperCase()) {
      'SEM_TOKEN' => 'Não entregue: aluno sem notificações ativas',
      'FALHOU' => 'Não entregue: o envio falhou',
      'DESLIGADO' => 'Não entregue: push desligado no servidor',
      _ => null,
    };

String winbackSubtitle({
  required String? tipo,
  required String mensagem,
  String? status,
}) {
  final tipoLabel = winbackTipoLabel(tipo);
  final falha = winbackEntregaFalhaLabel(status);
  if (falha != null) return '$tipoLabel · $falha';
  final msg = mensagem.trim();
  if (msg.isEmpty) return tipoLabel;
  return '$tipoLabel · $msg';
}

const winbackComoCalculamos =
    'Push no 30º e 60º dia sem treino, nos planos com automações. O lembrete da primeira semana sai pela rotina de engajamento, sem repetir aqui. Quem não tem o app ou desligou as notificações não recebe, e o envio aparece como não entregue.';

String winbackCountLabel(int count) {
  if (count <= 0) return 'Nenhum envio';
  if (count == 1) return '1 envio';
  return '$count envios';
}

String winbackSearchEmptyTitle(String query) =>
    query.trim().isEmpty ? 'Nenhum envio ainda' : 'Nenhum envio encontrado';

String winbackSearchEmptySubtitle(String query) => query.trim().isEmpty
    ? 'Quando a automação disparar, os registros aparecem aqui.'
    : 'Nada com esse nome neste log.';

String winbackHubSubtitle(String? freshness) {
  const base = 'Log dos pushes automáticos';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

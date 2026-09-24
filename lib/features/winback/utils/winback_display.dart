import '../../../core/utils/fx_utils.dart';

const winbackTiposConhecidos = [
  'ALUNO_INATIVO_7D',
  'ALUNO_INATIVO_30D',
  'ALUNO_INATIVO_60D',
];

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

String winbackSubtitle({
  required String? tipo,
  required String mensagem,
}) {
  final tipoLabel = winbackTipoLabel(tipo);
  final msg = mensagem.trim();
  if (msg.isEmpty) return tipoLabel;
  return '$tipoLabel · $msg';
}

const winbackComoCalculamos =
    'Tentativa de push no 7º, 30º e 60º dia sem treino. Quem não tem o app ou desligou as notificações não recebe, mas o envio aparece aqui.';

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

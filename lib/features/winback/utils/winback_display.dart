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

String winbackWhenLabel(String enviadoEm) {
  try {
    final dt = DateTime.parse(enviadoEm).toLocal();
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  } catch (_) {
    final raw = enviadoEm.trim();
    if (raw.length >= 16) return raw.substring(0, 16);
    return raw.isEmpty ? '—' : raw;
  }
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
    'Push no 7º, 30º e 60º dia sem treino. Trial do personal não entra neste log.';

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
  const base = 'Push de reengajamento';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

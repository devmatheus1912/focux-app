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

String winbackHubSubtitle(String? freshness) {
  const base = 'Push de reengajamento';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

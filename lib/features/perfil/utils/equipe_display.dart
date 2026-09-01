String equipeHubSubtitle(String? freshness) {
  const base = 'Assistentes e permissões';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String equipeRoleLabel(String? role) {
  switch ((role ?? '').trim().toUpperCase()) {
    case 'OWNER':
      return 'Dono';
    case 'CO_PERSONAL':
      return 'Co-personal';
    case 'SECRETARIA':
      return 'Secretaria';
    case 'ESTAGIARIO':
      return 'Estagiário';
    case 'SUPORTE':
      return 'Suporte';
    case 'ASSISTENTE':
      return 'Assistente';
    case '':
      return 'Sem papel';
    default:
      return role!.trim();
  }
}

String equipeStatusLabel(String? status) {
  switch ((status ?? '').trim().toUpperCase()) {
    case 'ATIVO':
      return 'Ativo';
    case 'CONVIDADO':
      return 'Convite enviado';
    case 'SUSPENSO':
      return 'Suspenso';
    case 'REMOVIDO':
      return 'Removido';
    case '':
      return 'Sem status';
    default:
      return status!.trim();
  }
}

String equipeMembroSubtitle({required String role, required String status}) =>
    '${equipeRoleLabel(role)} · ${equipeStatusLabel(status)}';

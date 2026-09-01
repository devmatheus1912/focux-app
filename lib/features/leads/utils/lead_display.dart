import '../../../core/utils/fx_utils.dart';

const leadOrigemValues = [
  'Instagram',
  'Indicação',
  'WhatsApp',
  'Google',
  'Outro',
];

const leadStatusValues = [
  'LEAD',
  'TESTE',
  'ATIVO',
  'INADIMPLENTE',
  'CANCELADO',
];

const leadInteracaoTipoValues = [
  'WHATSAPP',
  'LIGACAO',
  'EMAIL',
  'PRESENCIAL',
  'OUTRO',
];

String leadOrigemLabel(String? origem) {
  final value = origem?.trim();
  if (value == null || value.isEmpty) return 'Não informada';
  return value;
}

String leadNovoHubSubtitle() => 'Cadastre um prospect no CRM';

String leadStatusLabel(String? status) {
  switch ((status ?? '').trim().toUpperCase()) {
    case 'LEAD':
      return 'Lead';
    case 'TESTE':
      return 'Teste';
    case 'ATIVO':
      return 'Ativo';
    case 'INADIMPLENTE':
      return 'Inadimplente';
    case 'CANCELADO':
      return 'Cancelado';
    case 'CONVERTIDO':
      return 'Convertido';
    case '':
      return 'Sem status';
    default:
      return status!.trim();
  }
}

bool leadPodeConverter(String status) {
  final value = status.trim().toUpperCase();
  return value != 'CONVERTIDO' && value != 'ATIVO';
}

bool leadStatusDanger(String status) {
  final value = status.trim().toUpperCase();
  return value == 'INADIMPLENTE' || value == 'CANCELADO';
}

String leadInteracaoTipoLabel(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'WHATSAPP':
      return 'WhatsApp';
    case 'LIGACAO':
      return 'Ligação';
    case 'EMAIL':
      return 'E-mail';
    case 'PRESENCIAL':
      return 'Presencial';
    case 'OUTRO':
      return 'Outro';
    case '':
      return 'Contato';
    default:
      return tipo!.trim();
  }
}

String leadInteracaoFxIcon(String? tipo) {
  switch ((tipo ?? '').trim().toUpperCase()) {
    case 'WHATSAPP':
      return 'chat';
    case 'LIGACAO':
      return 'message-circle';
    case 'EMAIL':
      return 'article';
    case 'PRESENCIAL':
      return 'users';
    default:
      return 'spark';
  }
}

String leadFollowUpValue(String? proximoContato) {
  final raw = proximoContato?.trim();
  if (raw == null || raw.isEmpty) return 'Não definido';
  try {
    return fxDateShort(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}

String leadListSubtitle(String? freshness) {
  const base = 'Funil de prospects';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String leadCardSubtitle({String? objetivo, String? origem}) {
  final obj = objetivo?.trim();
  if (obj != null && obj.isNotEmpty) return obj;
  return leadOrigemLabel(origem);
}

String leadFreeLimitLabel(int count) {
  if (count >= 5) return 'Limite de 5 leads atingido no Free.';
  return '$count/5 leads no plano Free.';
}

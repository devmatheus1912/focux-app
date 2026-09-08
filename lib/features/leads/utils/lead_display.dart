import '../../../core/ux/fx_hub_freshness.dart';
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

const leadNomeMax = 100;
const leadTelefoneMax = 20;
const leadObjetivoMax = 300;
const leadObservacoesMax = 1000;

String leadSalvarTooltip() => 'Salvar lead';

String leadConfirmTitle() => 'Salvar este prospect?';

String leadConfirmMessage(String nome) {
  final value = nome.trim();
  if (value.isEmpty) return 'O nome entra no funil de leads.';
  return '$value entra no funil de leads.';
}

String leadConfirmLabel() => 'Salvar';

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

enum LeadStickyAction { converter, whatsapp, followUp }

LeadStickyAction leadStickyAction({
  required String status,
  required bool temTelefone,
}) {
  if (leadPodeConverter(status)) return LeadStickyAction.converter;
  if (temTelefone) return LeadStickyAction.whatsapp;
  return LeadStickyAction.followUp;
}

String leadStickyP0Label(LeadStickyAction action) {
  switch (action) {
    case LeadStickyAction.converter:
      return 'Converter em aluno';
    case LeadStickyAction.whatsapp:
      return 'WhatsApp';
    case LeadStickyAction.followUp:
      return 'Definir follow-up';
  }
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

String leadHubSubtitle({
  required String? status,
  String? freshness,
}) {
  final parts = <String>[leadStatusLabel(status)];
  final stamp = freshness?.trim();
  if (stamp != null && stamp.isNotEmpty) parts.add(stamp);
  return parts.join(' · ');
}

String leadCountLabel(int count) {
  if (count == 1) return '1 lead';
  return '$count leads';
}

String leadInteracoesMetricValue(int count) => '$count';

String leadInteracoesMetricHint(int count) {
  if (count <= 0) return 'Nenhum contato registrado';
  if (count == 1) return '1 contato no histórico';
  return '$count contatos no histórico';
}

const leadListChipStatuses = [
  'LEAD',
  'TESTE',
  'ATIVO',
  'INADIMPLENTE',
  'CANCELADO',
];

bool leadMatchesQuery({
  required String nome,
  String? objetivo,
  String? origem,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return nome.toLowerCase().contains(q) ||
      (objetivo ?? '').toLowerCase().contains(q) ||
      (origem ?? '').toLowerCase().contains(q);
}

String leadListSubtitle({required int count, String? freshness}) {
  return FxHubFreshness.joinCount(leadCountLabel(count), freshness);
}

String leadCardSubtitle({String? objetivo, String? origem}) {
  final obj = objetivo?.trim();
  if (obj != null && obj.isNotEmpty) return obj;
  return leadOrigemLabel(origem);
}

const leadFreeCap = 5;

bool leadShowsLimitBanner(int count, {int? limiteLeads}) {
  if (limiteLeads == null || limiteLeads <= 0) return false;
  final warnFrom = limiteLeads <= 1 ? 1 : limiteLeads - 1;
  return count >= warnFrom;
}

String leadLimitLabel(int count, int limite) {
  if (count >= limite) {
    return 'Limite de $limite leads atingido.';
  }
  return '$count/$limite leads neste plano.';
}

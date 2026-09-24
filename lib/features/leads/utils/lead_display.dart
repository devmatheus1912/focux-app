import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/utils/fx_utils.dart';

const leadOrigemValues = [
  'Instagram',
  'Indicação',
  'WhatsApp',
  'Google',
  'Outro',
];

/// Status que o personal escolhe à mão. "Virou aluno" só nasce do cadastro.
const leadStatusValues = ['LEAD', 'TESTE', 'CANCELADO'];

const leadStatusConvertido = 'CONVERTIDO';

/// Coluna do funil Novo → Conversei → Virou aluno (+ Arquivado).
const leadFunilColunas = ['LEAD', 'TESTE', leadStatusConvertido, 'CANCELADO'];

String leadFunilColuna(String status) {
  final value = status.trim().toUpperCase();
  if (value == 'ATIVO') return leadStatusConvertido;
  return leadFunilColunas.contains(value) ? value : 'LEAD';
}

String leadFunilHint(String coluna) {
  switch (coluna) {
    case 'TESTE':
      return 'Já conversou ou fez aula experimental.';
    case leadStatusConvertido:
      return 'Cadastrado como aluno.';
    case 'CANCELADO':
      return 'Sem interesse agora. Fica no histórico.';
    default:
      return 'Chegou agora e ainda precisa de contato.';
  }
}

String leadEmailValue(String? email) {
  final v = email?.trim() ?? '';
  return v.isEmpty ? 'Não informado' : v;
}

String? leadEmailInvalido(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return null;
  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
  return ok ? null : 'E-mail inválido';
}

String leadEmailHint(String? email) {
  final v = email?.trim() ?? '';
  return v.isEmpty ? 'Você pede no cadastro do aluno' : 'Vira o login do aluno';
}

bool leadDaPaginaPublica(String? origem) =>
    (origem ?? '').trim().toLowerCase() == 'página pública';

/// Abre o cadastro de aluno já preenchido; o backend fecha o lead no mesmo POST.
String leadConverterRoute({
  required int leadId,
  required String nome,
  String? email,
  String? telefone,
  String? objetivo,
}) {
  final params = <String, String>{'leadId': '$leadId', 'nome': nome.trim()};
  void put(String key, String? value) {
    final v = value?.trim();
    if (v != null && v.isNotEmpty) params[key] = v;
  }

  put('email', email);
  put('whatsapp', telefone);
  put('objetivo', objetivo);
  return Uri(path: '/alunos/novo', queryParameters: params).toString();
}

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
      return 'Novo';
    case 'TESTE':
      return 'Conversei';
    case 'ATIVO':
    case 'CONVERTIDO':
      return 'Virou aluno';
    case 'INADIMPLENTE':
      return 'Inadimplente';
    case 'CANCELADO':
      return 'Arquivado';
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
  return value == 'INADIMPLENTE';
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

String leadHubSubtitle({required String? status}) => leadStatusLabel(status);

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

const leadDetailSecaoResumo = 'resumo';
const leadDetailSecaoInteracoes = 'interacoes';

const leadDetailSecoes = [
  (value: leadDetailSecaoResumo, label: 'Resumo'),
  (value: leadDetailSecaoInteracoes, label: 'Interações'),
];

String leadDiasNoFunilValue(String criadoEm, {DateTime? now}) {
  final date = DateTime.tryParse(criadoEm.trim());
  if (date == null) return '—';
  final days =
      _dateOnly(now ?? DateTime.now()).difference(_dateOnly(date)).inDays;
  if (days <= 0) return 'Hoje';
  return '$days';
}

String leadDiasNoFunilHint(String criadoEm) {
  final date = DateTime.tryParse(criadoEm.trim());
  if (date == null) return 'Entrada no funil';
  return 'desde ${fxDateShort(date)}';
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

const leadListChipStatuses = leadFunilColunas;

String leadListSubtitle({required int count, String? freshness}) {
  return FxHubFreshness.joinCount(leadCountLabel(count), freshness);
}

String leadCardSubtitle({String? objetivo, String? origem}) {
  final obj = objetivo?.trim();
  final temObjetivo = obj != null && obj.isNotEmpty;
  if (leadDaPaginaPublica(origem)) {
    return temObjetivo ? 'Página pública · $obj' : 'Página pública';
  }
  if (temObjetivo) return obj;
  return leadOrigemLabel(origem);
}

/// Telefone legível no kanban/lista (evita ID cru / dígitos sem máscara).
String leadTelefoneDisplay(String? telefone) {
  final raw = telefone?.trim();
  if (raw == null || raw.isEmpty) return 'Sem telefone';
  final formatted = BrPhone.formatDisplay(raw);
  return formatted.isNotEmpty ? formatted : raw;
}

/// Título do card no funil: nome; se o "nome" for só número, mascara.
String leadKanbanTitle(String? nome, {String? telefone}) {
  final n = (nome ?? '').trim();
  if (n.isEmpty) return leadTelefoneDisplay(telefone);
  final digits = n.replaceAll(RegExp(r'\D'), '');
  final digitsOnly =
      digits.length >= 8 &&
      digits.length == n.replaceAll(RegExp(r'[\s()+-]'), '').length;
  if (digitsOnly) return leadTelefoneDisplay(n);
  return n;
}

/// Idade relativa curta no card (ex.: `2d`, `hoje`).
String leadKanbanAgeLabel(String criadoEm, {DateTime? now}) {
  final date = DateTime.tryParse(criadoEm.trim());
  if (date == null) return '';
  final days =
      _dateOnly(now ?? DateTime.now()).difference(_dateOnly(date)).inDays;
  if (days <= 0) return 'hoje';
  return '${days}d';
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

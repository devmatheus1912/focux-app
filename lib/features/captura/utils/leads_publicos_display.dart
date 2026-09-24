import '../../../core/utils/br_phone.dart';
import '../../../core/utils/fx_utils.dart';

enum LeadPublicoChip { todos, novos, convertidos }

String leadPublicoChipLabel(LeadPublicoChip chip) => switch (chip) {
  LeadPublicoChip.todos => 'Todos',
  LeadPublicoChip.novos => 'Novos',
  LeadPublicoChip.convertidos => 'Convertidos',
};

bool? leadPublicoConvertidoParam(LeadPublicoChip chip) => switch (chip) {
  LeadPublicoChip.todos => null,
  LeadPublicoChip.novos => false,
  LeadPublicoChip.convertidos => true,
};

String leadPublicoCountLabel(int count) {
  if (count <= 0) return 'Nenhum lead';
  if (count == 1) return '1 lead';
  return '$count leads';
}

String leadPublicoNome(String? nome) {
  final value = nome?.trim();
  if (value == null || value.isEmpty) return 'Lead';
  return fxTitleCaseName(value);
}

String leadPublicoSubtitle({
  String? telefone,
  String? email,
  String? objetivo,
}) {
  final parts = <String>[];
  final tel = telefone?.trim();
  if (tel != null && tel.isNotEmpty) {
    final formatted = BrPhone.formatDisplay(tel);
    parts.add(formatted.isNotEmpty ? formatted : tel);
  }
  final mail = email?.trim();
  if (mail != null && mail.isNotEmpty) parts.add(mail);
  final obj = objetivo?.trim();
  if (obj != null && obj.isNotEmpty) parts.add(obj);
  if (parts.isEmpty) return 'Sem contato extra';
  return parts.join(' · ');
}

/// Sticky da Captação: job = página pública (nunca "Criar aluno").
String leadPublicoStickyLabel() => 'Abrir página pública';

bool leadPublicoHasActiveFilter({
  required String query,
  required LeadPublicoChip chip,
}) => query.trim().isNotEmpty || chip != LeadPublicoChip.todos;

String leadPublicoValue(bool convertido) => convertido ? 'Virou aluno' : 'Novo';

String leadPublicoFxIcon(bool convertido) =>
    convertido ? 'circle-check' : 'users';

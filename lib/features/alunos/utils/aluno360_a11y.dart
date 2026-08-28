/// TalkBack / VoiceOver labels for Aluno 360 (PT-BR).
String aluno360FollowUpSemantics({
  required String subtitle,
  required bool expanded,
}) {
  final base = 'Próximo contato. $subtitle';
  if (!expanded) return '$base. Toque para expandir ações';
  return '$base. Toque para recolher ações';
}

String aluno360ModuleTileSemantics({
  required String label,
  required String sub,
  String? badge,
}) {
  final badgePart = badge != null ? ', $badge' : '';
  return '$label$badgePart. $sub';
}

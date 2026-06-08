/// TalkBack / VoiceOver labels for Aluno 360 (PT-BR).
String aluno360SectionHeaderSemantics({
  required String title,
  String? subtitle,
  String? trailing,
}) {
  final buffer = StringBuffer(title);
  if (subtitle != null && subtitle.trim().isNotEmpty) {
    buffer.write(', ${subtitle.trim()}');
  }
  if (trailing != null && trailing.trim().isNotEmpty) {
    buffer.write(', $trailing');
  }
  return buffer.toString();
}

String aluno360FollowUpSemantics({
  required String subtitle,
  required bool expanded,
}) =>
    'Próximo contato. $subtitle. ${expanded ? 'Recolher' : 'Expandir'} opções de follow-up';

String aluno360ModuleTileSemantics({
  required String label,
  required String sub,
  String? badge,
}) {
  final badgePart = badge != null ? ', $badge' : '';
  return '$label$badgePart. $sub';
}

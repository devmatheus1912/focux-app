/// TalkBack / VoiceOver labels for Aluno 360 (PT-BR).
String aluno360FollowUpSemantics({required String subtitle}) =>
    'Próximo contato. $subtitle';

String aluno360ModuleTileSemantics({
  required String label,
  required String sub,
  String? badge,
}) {
  final badgePart = badge != null ? ', $badge' : '';
  return '$label$badgePart. $sub';
}

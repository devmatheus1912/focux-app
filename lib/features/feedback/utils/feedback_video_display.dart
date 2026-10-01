import '../../../core/utils/fx_utils.dart';

String feedbackVideoLabel(String? comentario) {
  final value = comentario?.trim();
  if (value == null || value.isEmpty) return 'Feedback';
  return value;
}

String feedbackVideoSubtitle({
  required DateTime criadoEm,
  required bool respondido,
}) {
  final date = fxDateShort(criadoEm);
  return respondido ? '$date · Respondido' : '$date · Aguardando sua resposta';
}

String feedbackVideoStatusLabel({required bool respondido}) =>
    respondido ? 'Respondido' : 'Novo';

String feedbackVideoResponderLabel({required bool respondido}) =>
    respondido ? 'Editar resposta' : 'Responder';

String feedbackVideoCountLabel(int count) {
  if (count == 1) return '1 feedback';
  return '$count feedbacks';
}

const feedbackVideoHelpTip =
    'O aluno envia o vídeo do exercício e você responde com a correção. '
    'Disponível no Pro e no Enterprise.';

bool feedbackVideoMatchesQuery({
  required String comentario,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return comentario.toLowerCase().contains(q);
}

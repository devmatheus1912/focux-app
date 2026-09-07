import '../../../core/utils/fx_utils.dart';

String feedbackVideoLabel(String? comentario) {
  final value = comentario?.trim();
  if (value == null || value.isEmpty) return 'Feedback';
  return value;
}

String feedbackVideoSubtitle({
  required DateTime criadoEm,
  int? aiScore,
  String? statusAnalise,
}) {
  final date = fxDateShort(criadoEm);
  if (aiScore == null) return date;
  final status = statusAnalise?.trim();
  if (status == null || status.isEmpty) return '$date · IA $aiScore/100';
  return '$date · IA $aiScore/100 · $status';
}

String feedbackVideoValue(int? aiScore) {
  if (aiScore == null) return 'Vídeo';
  return '$aiScore';
}

String feedbackVideoFxIcon(int? aiScore) {
  if (aiScore == null) return 'spark';
  if (aiScore >= 70) return 'circle-check';
  if (aiScore >= 40) return 'trend';
  return 'alert-triangle';
}

bool feedbackVideoDanger(int? aiScore) => aiScore != null && aiScore < 40;

String feedbackVideoCountLabel(int count) {
  if (count == 1) return '1 feedback';
  return '$count feedbacks';
}

bool feedbackVideoMatchesQuery({
  required String comentario,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return comentario.toLowerCase().contains(q);
}

String feedbackVideoHubSubtitle({
  String? alunoNome,
  String? freshness,
  int? count,
}) {
  final parts = <String>[
    if (count != null) feedbackVideoCountLabel(count)
    else 'Análises técnicas de execução',
    if ((alunoNome ?? '').trim().isNotEmpty) alunoNome!.trim(),
    if ((freshness ?? '').trim().isNotEmpty) freshness!.trim(),
  ];
  return parts.join(' · ');
}

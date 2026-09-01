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

String feedbackVideoHubSubtitle({
  String? alunoNome,
  String? freshness,
}) {
  const base = 'Análises técnicas de execução';
  final nome = alunoNome?.trim();
  final stamp = freshness?.trim();
  if (nome != null && nome.isNotEmpty && stamp != null && stamp.isNotEmpty) {
    return '$base · $nome · $stamp';
  }
  if (stamp != null && stamp.isNotEmpty) return '$base · $stamp';
  return base;
}

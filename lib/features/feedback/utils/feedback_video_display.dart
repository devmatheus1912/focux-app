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

String feedbackVideoComentarioAluno(String comentario) =>
    'Aluno: "${comentario.trim()}"';

String feedbackVideoCountLabel(int count) {
  if (count == 1) return '1 feedback';
  return '$count feedbacks';
}

/// Título da linha: o exercício quando o backend manda, senão o comentário.
String feedbackVideoTitulo({String? exercicioNome, String? comentario}) {
  final nome = exercicioNome?.trim() ?? '';
  return nome.isNotEmpty ? nome : feedbackVideoLabel(comentario);
}

String feedbackVideoAlunoSubtitle({
  required DateTime criadoEm,
  required bool respondido,
}) {
  final date = fxDateShort(criadoEm);
  return respondido ? '$date · Correção pronta' : '$date · Aguardando o personal';
}

String feedbackVideoAlunoStatusLabel({required bool respondido}) =>
    respondido ? 'Respondido' : 'Enviado';

const feedbackVideoAlunoHelpTip =
    'Grave uma série do exercício e envie aqui. Seu personal assiste e '
    'responde com a correção. Você recebe um aviso quando ele responder.';

const feedbackVideoMaxBytes = 120 * 1024 * 1024;
const feedbackVideoMaxDuration = Duration(seconds: 60);
const _feedbackVideoExtensoes = {'mp4', 'mov', 'm4v', 'webm'};

/// Nome aceito pelo upload (`feedback/videos` só recebe mp4/mov/m4v/webm).
String feedbackVideoUploadFilename(String? nomeOuCaminho) {
  final raw = (nomeOuCaminho ?? '').split(RegExp(r'[\\/]')).last;
  final dot = raw.lastIndexOf('.');
  final ext = dot >= 0 ? raw.substring(dot + 1).toLowerCase() : '';
  final safeExt = _feedbackVideoExtensoes.contains(ext) ? ext : 'mp4';
  return 'feedback_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
}

/// Mensagem de erro de tamanho, ou null quando o vídeo pode subir.
String? feedbackVideoTamanhoErro(int bytes) {
  if (bytes <= 0) return 'Vídeo vazio. Grave de novo.';
  if (bytes > feedbackVideoMaxBytes) {
    return 'Vídeo acima de 120 MB. Grave um trecho mais curto.';
  }
  return null;
}

const feedbackVideoHelpTip =
    'O aluno envia o vídeo do exercício e você responde com a correção: '
    'toque no vídeo para assistir e escrever. Segure para remover. '
    'Disponível no Pro e no Enterprise.';

bool feedbackVideoMatchesQuery({
  required String comentario,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return comentario.toLowerCase().contains(q);
}

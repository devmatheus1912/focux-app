import '../widgets/conversation_media_widgets.dart';

const _extensoesDeVideo = {'mp4', 'mov', 'm4v', '3gp', 'avi', 'webm', 'mkv'};

/// Foto ou vídeo escolhido na galeria (seletor único): pelo tipo do arquivo,
/// e na falta dele pela extensão.
ConversationMediaType chatMidiaDoArquivo(String nome, String? mimeType) {
  final mime = (mimeType ?? '').toLowerCase();
  if (mime.startsWith('video/')) return ConversationMediaType.video;
  if (mime.startsWith('image/')) return ConversationMediaType.photo;
  final ponto = nome.lastIndexOf('.');
  final ext = ponto < 0 ? '' : nome.substring(ponto + 1).toLowerCase();
  return _extensoesDeVideo.contains(ext)
      ? ConversationMediaType.video
      : ConversationMediaType.photo;
}

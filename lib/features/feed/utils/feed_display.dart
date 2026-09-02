const feedTipoValues = ['TEXTO', 'IMAGEM', 'VIDEO', 'ENQUETE', 'DICA'];
const feedTituloMax = 255;
const feedConteudoMax = 4000;

String feedPublicarTileLabel() => 'Publicar';

String feedPublicarConfirmTitle() => 'Publicar no feed?';

String feedPublicarConfirmMessage() =>
    'Os alunos passam a ver esta publicação no feed deles.';

String feedPublicarConfirmLabel() => 'Publicar';

String feedTipoLabel(String? tipo) {
  switch ((tipo ?? 'TEXTO').trim().toUpperCase()) {
    case 'IMAGEM':
      return 'Imagem';
    case 'VIDEO':
      return 'Vídeo';
    case 'ENQUETE':
      return 'Enquete';
    case 'DICA':
      return 'Dica rápida';
    default:
      return 'Texto';
  }
}

String feedHubSubtitle(String? freshness) {
  const base = 'Novidades para os seus alunos';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String feedMidiaCta({required String tipo, required bool hasFile}) {
  if (hasFile) return 'Trocar arquivo';
  return tipo.toUpperCase() == 'VIDEO' ? 'Escolher vídeo' : 'Escolher imagem';
}

bool feedTipoTemMidia(String tipo) {
  final t = tipo.trim().toUpperCase();
  return t == 'IMAGEM' || t == 'VIDEO';
}

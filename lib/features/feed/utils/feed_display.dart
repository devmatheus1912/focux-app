enum FeedListChip { todos, fixados, imagem, video, dica }

String feedListChipLabel(FeedListChip chip) => switch (chip) {
  FeedListChip.todos => 'Todas',
  FeedListChip.fixados => 'Fixados',
  FeedListChip.imagem => 'Imagem',
  FeedListChip.video => 'Vídeo',
  FeedListChip.dica => 'Dica',
};

String? feedListChipTipo(FeedListChip chip) => switch (chip) {
  FeedListChip.imagem => 'IMAGEM',
  FeedListChip.video => 'VIDEO',
  FeedListChip.dica => 'DICA',
  _ => null,
};

bool? feedListChipFixado(FeedListChip chip) =>
    chip == FeedListChip.fixados ? true : null;

const feedTipoValues = ['TEXTO', 'IMAGEM', 'VIDEO', 'ENQUETE', 'DICA'];
const feedTituloMax = 255;
const feedConteudoMax = 4000;

String feedPublicarTileLabel() => 'Publicar';

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

String feedCountLabel(int count) {
  if (count <= 0) return 'Nenhuma publicação';
  if (count == 1) return '1 publicação';
  return '$count publicações';
}

String feedHubSubtitle(String? freshness, {int? count}) {
  final base =
      count == null ? 'Novidades para os seus alunos' : feedCountLabel(count);
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

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

/// Busca e filtros só ajudam com posts suficientes; ativos, ficam à vista.
bool feedMostraFiltros({
  required int total,
  required String query,
  required bool filtrando,
}) => total >= 5 || filtrando || query.trim().isNotEmpty;

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

bool feedMatchesQuery({
  required String titulo,
  required String conteudo,
  required String query,
}) {
  final q = _foldSearch(query);
  if (q.isEmpty) return true;
  return _foldSearch(titulo).contains(q) || _foldSearch(conteudo).contains(q);
}

String _foldSearch(String value) {
  var out = value.trim().toLowerCase();
  const pairs = <String, String>{
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  pairs.forEach((from, to) => out = out.replaceAll(from, to));
  return out;
}

String feedMidiaCta({required String tipo, required bool hasFile}) {
  if (hasFile) return 'Trocar arquivo';
  return tipo.toUpperCase() == 'VIDEO' ? 'Escolher vídeo' : 'Escolher imagem';
}

bool feedTipoTemMidia(String tipo) {
  final t = tipo.trim().toUpperCase();
  return t == 'IMAGEM' || t == 'VIDEO';
}

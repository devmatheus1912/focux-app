import '../data/feed_repository.dart';

enum FeedListChip { todos, fixados, imagem, video, dica }

String feedListChipLabel(FeedListChip chip) => switch (chip) {
  FeedListChip.todos => 'Todas',
  FeedListChip.fixados => 'Fixados',
  FeedListChip.imagem => 'Fotos',
  FeedListChip.video => 'Vídeos',
  FeedListChip.dica => 'Dicas',
};

String? feedListChipTipo(FeedListChip chip) => switch (chip) {
  FeedListChip.imagem => 'IMAGEM',
  FeedListChip.video => 'VIDEO',
  FeedListChip.dica => 'DICA',
  _ => null,
};

bool? feedListChipFixado(FeedListChip chip) =>
    chip == FeedListChip.fixados ? true : null;

/// Primeira linha que vira título no cartão (o resto é o texto).
const feedTituloLinhaMax = 80;
const feedConteudoMax = 4000;

/// Uma caixa só no compositor: com duas linhas ou mais, a primeira (até
/// [feedTituloLinhaMax]) vira o título. Uma linha só fica como texto.
({String titulo, String conteudo}) feedSepararTitulo(String texto) {
  final limpo = texto.trim();
  final quebra = limpo.indexOf('\n');
  if (quebra <= 0) return (titulo: '', conteudo: limpo);
  final primeira = limpo.substring(0, quebra).trim();
  final resto = limpo.substring(quebra + 1).trim();
  if (primeira.isEmpty ||
      primeira.length > feedTituloLinhaMax ||
      resto.isEmpty) {
    return (titulo: '', conteudo: limpo);
  }
  return (titulo: primeira, conteudo: resto);
}

/// Volta título + texto para a caixa única ao editar.
String feedJuntarTitulo(String titulo, String conteudo) {
  final t = titulo.trim();
  final c = conteudo.trim();
  if (t.isEmpty) return c;
  if (c.isEmpty) return t;
  return '$t\n$c';
}

/// "há 3 h", "ontem", "há 1 semana". Depois de 30 dias, a data.
String feedQuando(DateTime data, {DateTime? agora}) {
  final diff = (agora ?? DateTime.now()).difference(data);
  if (diff.inMinutes < 1) return 'agora';
  if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'há ${diff.inHours} h';
  if (diff.inDays == 1) return 'ontem';
  if (diff.inDays < 7) return 'há ${diff.inDays} dias';
  if (diff.inDays < 30) {
    final semanas = diff.inDays ~/ 7;
    return semanas == 1 ? 'há 1 semana' : 'há $semanas semanas';
  }
  final dia = data.day.toString().padLeft(2, '0');
  final mes = data.month.toString().padLeft(2, '0');
  return '$dia/$mes';
}

/// Proporção da foto no cartão: de 4:5 (retrato) a 1,91:1 (paisagem).
const feedProporcaoMin = 4 / 5;
const feedProporcaoMax = 1.91;

double feedProporcaoCartao(double proporcaoReal) =>
    proporcaoReal.clamp(feedProporcaoMin, feedProporcaoMax).toDouble();

/// Fora da faixa, a foto aparece inteira sobre o fundo desfocado.
bool feedPrecisaFundo(double proporcaoReal) =>
    proporcaoReal < feedProporcaoMin - 0.01 ||
    proporcaoReal > feedProporcaoMax + 0.01;

String feedCountLabel(int count) {
  if (count <= 0) return 'Nenhuma publicação';
  if (count == 1) return '1 publicação';
  return '$count publicações';
}

String feedCurtidasLabel(int n) => n == 1 ? '1 curtida' : '$n curtidas';

/// Bloco "Fixado" só na lista sem filtro; com filtro, a ordem do servidor.
({List<FeedPost> fixados, List<FeedPost> outros}) feedSepararFixados(
  List<FeedPost> posts, {
  required bool filtrando,
}) {
  if (filtrando) return (fixados: const <FeedPost>[], outros: posts);
  return (
    fixados: [
      for (final p in posts)
        if (p.fixado) p,
    ],
    outros: [
      for (final p in posts)
        if (!p.fixado) p,
    ],
  );
}

/// O post do aviso (push) vem primeiro: o aluno cai direto nele.
List<FeedPost> feedComDestaque(List<FeedPost> posts, int? postId) {
  if (postId == null) return posts;
  final alvo = posts.where((p) => p.id == postId).firstOrNull;
  if (alvo == null) return posts;
  return [alvo, ...posts.where((p) => p.id != postId)];
}

/// Busca e filtros só ajudam com posts suficientes; ativos, ficam à vista.
bool feedMostraFiltros({
  required int total,
  required String query,
  required bool filtrando,
}) => total >= 5 || filtrando || query.trim().isNotEmpty;

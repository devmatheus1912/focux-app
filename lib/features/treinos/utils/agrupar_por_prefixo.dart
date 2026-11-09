/// Agrupa nomes seguidos que começam igual ("Supino inclinado com barra",
/// "… com halteres", "… alto com barra"): o começo vira cabeçalho e cada linha
/// mostra só o resto. Menos de [minimo] seguidos, o nome fica inteiro.
library;

/// Um trecho da lista: [prefixo] nulo = nomes soltos (inteiros).
class GrupoDePrefixo {
  const GrupoDePrefixo({required this.prefixo, required this.itens});

  final String? prefixo;

  /// (índice na lista de entrada, texto a mostrar na linha).
  final List<(int, String)> itens;
}

// "de"/"do" ficam fora: fazem parte do nome ("Flexão de braços", "Rosca direta").
const _preposicoes = [' com ', ' no ', ' na ', ' em ', ' sem '];

/// Começo comum de um nome: até o primeiro parêntese fechado, ou até a
/// primeira preposição. Nulo quando não há onde cortar.
String? prefixoDoNome(String nome) {
  final n = nome.trim();
  final lower = n.toLowerCase();
  var corte = -1;
  for (final p in _preposicoes) {
    final i = lower.indexOf(p);
    if (i > 0 && (corte < 0 || i < corte)) corte = i;
  }
  final abre = n.indexOf('(');
  final fecha = n.indexOf(')');
  // Parêntese antes da preposição: o começo inclui o parêntese ("RDL").
  if (abre > 0 && fecha > abre && (corte < 0 || abre < corte)) {
    return n.substring(0, fecha + 1);
  }
  return corte > 0 ? n.substring(0, corte) : null;
}

/// O nome entra no grupo de [cabecalho] quando começa com ele seguido de espaço.
bool _entraNoGrupo(String nome, String cabecalho) =>
    nome.trim().toLowerCase().startsWith('${cabecalho.toLowerCase()} ');

List<GrupoDePrefixo> agruparPorPrefixo(List<String> nomes, {int minimo = 3}) {
  final grupos = <GrupoDePrefixo>[];
  final soltos = <(int, String)>[];

  void soltarPendentes() {
    if (soltos.isEmpty) return;
    grupos.add(GrupoDePrefixo(prefixo: null, itens: [...soltos]));
    soltos.clear();
  }

  var i = 0;
  while (i < nomes.length) {
    final cabecalho = _melhorCabecalho(nomes, i, minimo);
    if (cabecalho == null) {
      soltos.add((i, nomes[i]));
      i++;
      continue;
    }
    var fim = i;
    while (fim < nomes.length && _entraNoGrupo(nomes[fim], cabecalho)) {
      fim++;
    }
    soltarPendentes();
    grupos.add(
      GrupoDePrefixo(
        prefixo: cabecalho,
        itens: [
          for (var k = i; k < fim; k++) (k, _resto(nomes[k], cabecalho)),
        ],
      ),
    );
    i = fim;
  }
  soltarPendentes();
  return grupos;
}

/// Cabeçalho para o grupo que começa em [i]: o começo do nome [i] e os
/// começos mais curtos dele (palavra a palavra), o mais longo que junte
/// pelo menos [minimo] nomes seguidos.
String? _melhorCabecalho(List<String> nomes, int i, int minimo) {
  final corte = prefixoDoNome(nomes[i]);
  final base = corte ?? nomes[i].trim();
  final palavras = base.split(' ');
  // O começo inteiro (até a preposição) sempre vale, mesmo com uma palavra
  // ("Agachamento"); encurtar só até duas ("Supino inclinado", nunca "Supino").
  final candidatos = <String>[
    if (corte != null) corte,
    for (var n = palavras.length - (corte != null ? 1 : 0); n >= 2; n--)
      palavras.take(n).join(' '),
  ];
  for (final c in candidatos) {
    var fim = i;
    while (fim < nomes.length && _entraNoGrupo(nomes[fim], c)) {
      fim++;
    }
    if (fim - i >= minimo) return c;
  }
  return null;
}

/// O que sobra depois do cabeçalho.
String _resto(String nome, String prefixo) {
  final r = nome.trim().substring(prefixo.length).trim();
  return r.isEmpty ? nome.trim() : r;
}

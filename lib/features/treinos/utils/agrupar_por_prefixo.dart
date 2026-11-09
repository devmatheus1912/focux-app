/// Agrupa nomes seguidos que começam igual ("Levantamento terra romeno (RDL)
/// com halteres", "… unilateral com halter", "… no Smith"): o começo vira
/// cabeçalho e cada linha mostra só o resto. Menos de [minimo] seguidos, o
/// nome fica inteiro.
library;

/// Um trecho da lista: [prefixo] nulo = nomes soltos (inteiros).
class GrupoDePrefixo {
  const GrupoDePrefixo({required this.prefixo, required this.itens});

  final String? prefixo;

  /// (índice na lista de entrada, texto a mostrar na linha).
  final List<(int, String)> itens;
}

const _preposicoes = [' com ', ' no ', ' na ', ' em ', ' sem ', ' de '];

/// Começo comum de um nome: até o primeiro parêntese fechado, ou até a
/// primeira preposição. Nulo quando não há onde cortar.
String? prefixoDoNome(String nome) {
  final n = nome.trim();
  final fecha = n.indexOf(')');
  if (fecha > 0 && n.contains('(') && n.indexOf('(') < fecha) {
    return n.substring(0, fecha + 1);
  }
  final lower = n.toLowerCase();
  var corte = -1;
  for (final p in _preposicoes) {
    final i = lower.indexOf(p);
    if (i > 0 && (corte < 0 || i < corte)) corte = i;
  }
  return corte > 0 ? n.substring(0, corte) : null;
}

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
    final p = prefixoDoNome(nomes[i]);
    var fim = i + 1;
    if (p != null) {
      final chave = p.toLowerCase();
      while (fim < nomes.length &&
          prefixoDoNome(nomes[fim])?.toLowerCase() == chave) {
        fim++;
      }
    }
    if (p != null && fim - i >= minimo) {
      soltarPendentes();
      grupos.add(
        GrupoDePrefixo(
          prefixo: p,
          itens: [
            for (var k = i; k < fim; k++)
              (k, _resto(nomes[k], p)),
          ],
        ),
      );
    } else {
      for (var k = i; k < fim; k++) {
        soltos.add((k, nomes[k]));
      }
    }
    i = fim;
  }
  soltarPendentes();
  return grupos;
}

/// O que sobra depois do começo; vazio (o nome é só o começo) mostra inteiro.
String _resto(String nome, String prefixo) {
  final r = nome.trim().substring(prefixo.length).trim();
  return r.isEmpty ? nome.trim() : r;
}

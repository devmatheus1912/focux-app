import '../data/treino_repository.dart';
import '../models/metodo_exercicio.dart';

/// Um combinado como a API grava: os itens (na ordem) e o rótulo (nulo = pelo tamanho).
typedef Combinado = ({List<int> itens, String? rotulo});

/// Combinados atuais do treino, na ordem da lista ([itens] já ordenados).
List<Combinado> combinadosDoTreino(List<TreinoExercicioItem> itens) {
  final grupos = <int, List<int>>{};
  final rotulos = <int, String?>{};
  for (final item in itens) {
    final g = item.metodo.grupo;
    if (g == null) continue;
    grupos.putIfAbsent(g, () => []).add(item.id);
    rotulos[g] ??= item.metodo.grupoRotulo;
  }
  return [
    for (final e in grupos.entries)
      if (e.value.length >= 2) (itens: e.value, rotulo: rotulos[e.key] == 'SUPERSET' ? 'SUPERSET' : null),
  ];
}

/// Junta o item com o próximo da lista (mesmo bloco). Se um deles já está num
/// combinado, o outro entra nele; se os dois estão, os grupos se juntam.
/// Nulo quando não há próximo no mesmo bloco.
List<Combinado>? combinarComProximo(List<TreinoExercicioItem> itens, int itemId) {
  final i = itens.indexWhere((e) => e.id == itemId);
  if (i < 0 || i + 1 >= itens.length || itens[i + 1].bloco != itens[i].bloco) return null;
  final atual = combinadosDoTreino(itens);
  final proximo = itens[i + 1].id;
  final doAtual = atual.where((c) => c.itens.contains(itemId)).firstOrNull;
  final doProximo = atual.where((c) => c.itens.contains(proximo)).firstOrNull;
  if (doAtual != null && identical(doAtual, doProximo)) return null;
  final juntos = <int>{
    ...?doAtual?.itens,
    itemId,
    proximo,
    ...?doProximo?.itens,
  };
  final ordenados = [for (final e in itens) if (juntos.contains(e.id)) e.id];
  return [
    for (final c in atual)
      if (!identical(c, doAtual) && !identical(c, doProximo)) c,
    (itens: ordenados, rotulo: null),
  ];
}

/// Tira o combinado inteiro de que o item faz parte.
List<Combinado> separar(List<TreinoExercicioItem> itens, int itemId) => [
  for (final c in combinadosDoTreino(itens))
    if (!c.itens.contains(itemId)) c,
];

/// Bi-set de 2 vira "Superset" e volta (o mesmo método, o nome que a academia usa).
List<Combinado> alternarSuperset(List<TreinoExercicioItem> itens, int itemId) => [
  for (final c in combinadosDoTreino(itens))
    if (c.itens.contains(itemId))
      (itens: c.itens, rotulo: c.rotulo == 'SUPERSET' ? null : 'SUPERSET')
    else
      c,
];

/// "Bi-set · 4 voltas · descanso 90 s depois do último".
String cabecalhoDoCombinado({
  required String? rotulo,
  required int tamanho,
  required int voltas,
  required int? descansoSegundos,
}) {
  final partes = [
    rotuloDoCombinado(rotulo, tamanho),
    voltas == 1 ? '1 volta' : '$voltas voltas',
    if (descansoSegundos != null && descansoSegundos > 0) 'descanso $descansoSegundos s depois do último',
  ];
  return partes.join(' · ');
}

import '../data/treino_repository.dart';
import 'treino_detail_grouping.dart';

/// Ordem em que os blocos aparecem na tela do treino. "Ajuste" só aparece
/// quando já existe exercício salvo nele (a opção de criar saiu da interface).
const blocosDoTreino = ['AQUECIMENTO', 'TRABALHO', 'ALONGAMENTO', 'AJUSTE'];

/// Blocos que têm exercício, na ordem de [blocosDoTreino], cada um com seus itens.
List<(String, List<TreinoExercicioItem>)> blocosComExercicio(
  List<TreinoExercicioItem> exercicios,
) {
  return [
    for (final bloco in blocosDoTreino)
      if (exercicios.any((e) => e.bloco == bloco))
        (bloco, exercicios.where((e) => e.bloco == bloco).toList()),
  ];
}

/// Seções que sempre aparecem na tela, mesmo vazias, para "+ Adicionar" ficar
/// ao alcance. O legado AJUSTE só aparece quando já tem exercício.
const blocosFixos = ['AQUECIMENTO', 'TRABALHO', 'ALONGAMENTO'];

/// Uma linha da lista única: cabeçalho de seção (não arrasta) ou exercício.
sealed class LinhaTreino {
  const LinhaTreino();
}

class LinhaSecao extends LinhaTreino {
  const LinhaSecao(this.bloco);

  final String bloco;
}

class LinhaItem extends LinhaTreino {
  const LinhaItem(this.item);

  final TreinoExercicioItem item;
}

/// Seções fixas na ordem de [blocosDoTreino], cada uma seguida dos seus itens
/// (ordenados pela ordem global do treino).
List<LinhaTreino> linhasDoTreino(List<TreinoExercicioItem> exercicios) {
  final ordenados = [...exercicios]..sort((a, b) => a.ordem.compareTo(b.ordem));
  return [
    for (final bloco in blocosDoTreino)
      if (blocosFixos.contains(bloco) ||
          ordenados.any((e) => e.bloco == bloco)) ...[
        LinhaSecao(bloco),
        for (final e in ordenados)
          if (e.bloco == bloco) LinhaItem(e),
      ],
  ];
}

/// Resultado de soltar um exercício em outra posição da lista única.
class MovimentoDeTreino {
  const MovimentoDeTreino({
    required this.itens,
    required this.movido,
    required this.blocoNovo,
  });

  /// Todos os exercícios na nova ordem global (seções em sequência).
  final List<TreinoExercicioItem> itens;
  final TreinoExercicioItem movido;
  final String blocoNovo;

  bool get mudouDeBloco => blocoNovo != movido.bloco;

  List<int> get idsEmOrdem => [for (final i in itens) i.id];
}

/// Aplica o arrasto de [antes] para [depois] (índice final, como em
/// `onReorderItem`). O bloco do exercício é o da seção em que ele caiu; solto
/// acima da primeira seção, vale a primeira. Devolve nulo se o arrasto partiu
/// de um cabeçalho.
MovimentoDeTreino? moverNaLista(
  List<LinhaTreino> linhas,
  int antes,
  int depois,
) {
  if (antes < 0 || antes >= linhas.length) return null;
  final origem = linhas[antes];
  if (origem is! LinhaItem) return null;
  final lista = [...linhas];
  lista.removeAt(antes);
  lista.insert(depois.clamp(0, lista.length), origem);

  var blocoAtual = blocosDoTreino.first;
  final itens = <TreinoExercicioItem>[];
  String? blocoDoMovido;
  for (final linha in lista) {
    switch (linha) {
      case LinhaSecao(:final bloco):
        blocoAtual = bloco;
      case LinhaItem(:final item):
        itens.add(item);
        if (identical(linha, origem)) blocoDoMovido = blocoAtual;
    }
  }
  return MovimentoDeTreino(
    itens: itens,
    movido: origem.item,
    blocoNovo: blocoDoMovido ?? origem.item.bloco,
  );
}

/// Move [item] para o fim de [bloco] (menu "Mover para…").
MovimentoDeTreino moverParaBloco(
  List<TreinoExercicioItem> exercicios,
  TreinoExercicioItem item,
  String bloco,
) {
  final linhas = linhasDoTreino(exercicios);
  final antes = linhas.indexWhere((l) => l is LinhaItem && l.item.id == item.id);
  var fim = linhas.length;
  final secao = linhas.indexWhere((l) => l is LinhaSecao && l.bloco == bloco);
  if (secao >= 0) {
    fim = secao + 1;
    while (fim < linhas.length && linhas[fim] is LinhaItem) {
      fim++;
    }
  }
  // Ao remover antes, os índices depois dele sobem um.
  final destino = antes < fim ? fim - 1 : fim;
  return moverNaLista(linhas, antes, destino)!;
}

/// "~45 min": séries × (descanso + execução), arredondado para 5 min.
/// Zero quando não há nada a somar.
int duracaoEstimadaMin(
  List<TreinoExercicioItem> exercicios, {
  int execucaoSeg = 40,
}) {
  var segundos = 0;
  for (final e in exercicios) {
    segundos += e.series * ((e.descansoSegundos ?? 60) + execucaoSeg);
  }
  if (segundos <= 0) return 0;
  final minutos = (segundos / 60).round();
  final arredondado = ((minutos + 2) ~/ 5) * 5;
  return arredondado < 5 ? 5 : arredondado;
}

/// "7 exercícios · ~45 min · 5 grupos" (sem minutos quando não há o que somar).
String treinoResumoLinha(List<TreinoExercicioItem> exercicios) {
  final n = exercicios.length;
  final grupos = treinoDetailGroupCount(exercicios);
  final min = duracaoEstimadaMin(exercicios);
  return [
    n == 1 ? '1 exercício' : '$n exercícios',
    if (min > 0) '~$min min',
    if (grupos > 0) grupos == 1 ? '1 grupo' : '$grupos grupos',
  ].join(' · ');
}

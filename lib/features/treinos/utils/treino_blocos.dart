import '../data/treino_repository.dart';

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

/// Mostra o título do bloco só quando ele ajuda a entender: mais de um bloco,
/// ou um único bloco que não é o de trabalho.
bool mostrarTituloDeBloco(List<(String, List<TreinoExercicioItem>)> blocos) =>
    blocos.length > 1 || (blocos.length == 1 && blocos.first.$1 != 'TRABALHO');

/// O backend exige todos os ids do treino para reordenar. Ao reordenar só um
/// bloco, a nova ordem dele ocupa as mesmas posições que o bloco já tinha.
List<int> idsCompletosAoReordenar({
  required List<TreinoExercicioItem> todos,
  required List<TreinoExercicioItem> doBloco,
  required List<int> novaOrdemDoBloco,
}) {
  final noBloco = doBloco.map((e) => e.id).toSet();
  var proximo = 0;
  return [
    for (final item in todos)
      noBloco.contains(item.id) ? novaOrdemDoBloco[proximo++] : item.id,
  ];
}

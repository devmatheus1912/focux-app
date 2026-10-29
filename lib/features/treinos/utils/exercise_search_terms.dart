import '../../exercicios/data/enums.dart';
import '../../exercicios/data/exercicio_taxonomy_labels.dart';
import 'exercicio_texto.dart';

/// Uma palavra da busca que o app reconhece como grupo ou equipamento.
class TermoReconhecido {
  const TermoReconhecido({required this.palavra, required this.rotulo});

  /// Como o aluno digitou (para tirar da caixa de busca).
  final String palavra;

  /// Como aparece no chip ("Peito", "Halter").
  final String rotulo;
}

/// Palavras da [busca] que são exatamente um grupo muscular ou equipamento
/// (sem acento nem caixa, aceitando só o começo a partir de 4 letras).
List<TermoReconhecido> termosReconhecidos(String busca) {
  final rotulos = <String>{
    for (final g in GrupoMuscular.values)
      if (TaxonomyLabels.grupo[g] != null) TaxonomyLabels.grupo[g]!,
    for (final e in Equipamento.values)
      if (TaxonomyLabels.equipamento[e] != null) TaxonomyLabels.equipamento[e]!,
  };
  final saida = <TermoReconhecido>[];
  for (final palavra in busca.trim().split(RegExp(r'\s+'))) {
    final p = semAcento(palavra);
    if (p.length < 3) continue;
    for (final rotulo in rotulos) {
      final r = semAcento(rotulo);
      if (r == p || (p.length >= 4 && r.startsWith(p))) {
        saida.add(TermoReconhecido(palavra: palavra, rotulo: rotulo));
        break;
      }
    }
  }
  return saida;
}

/// Tira [palavra] (primeira ocorrência, sem acento nem caixa) do texto.
String removerTermoDaBusca(String texto, String palavra) {
  final partes = texto.trim().split(RegExp(r'\s+'));
  final alvo = semAcento(palavra);
  var removido = false;
  final restantes = <String>[];
  for (final parte in partes) {
    if (!removido && semAcento(parte) == alvo) {
      removido = true;
      continue;
    }
    restantes.add(parte);
  }
  return restantes.join(' ');
}

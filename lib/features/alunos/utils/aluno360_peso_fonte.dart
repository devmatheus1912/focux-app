enum PesoOrigem { avaliacao, cadastro }

/// Peso que a tela mostra: a medida mais recente das avaliações; se não
/// houver, o do cadastro (dizendo de onde veio). Nulo sem nenhum dos dois.
({double valor, PesoOrigem origem})? pesoMostrado({
  required List<double> historico,
  required double? cadastro,
}) {
  if (historico.isNotEmpty) {
    return (valor: historico.last, origem: PesoOrigem.avaliacao);
  }
  if (cadastro != null) return (valor: cadastro, origem: PesoOrigem.cadastro);
  return null;
}

/// Série para o gráfico: as avaliações. Um peso de cadastro sozinho é um
/// ponto, nunca duas cópias (isso fingia uma tendência "Estável").
List<double> serieDePeso({
  required List<double> historico,
  required double? cadastro,
}) {
  if (historico.isNotEmpty) return historico;
  if (cadastro == null) return const [];
  return [cadastro];
}

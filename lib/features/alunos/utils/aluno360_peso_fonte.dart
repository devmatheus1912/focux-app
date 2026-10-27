import 'aluno360_medida_plausivel.dart';

enum PesoOrigem { avaliacao, cadastro }

/// Peso que a tela mostra: a medida mais recente das avaliações; se não
/// houver, o do cadastro (dizendo de onde veio). Nulo sem nenhum dos dois.
({double valor, PesoOrigem origem})? pesoMostrado({
  required List<double> historico,
  required double? cadastro,
}) {
  // Peso digitado errado (458 kg) não vira "atual" se há uma medida possível.
  final plausiveis = historico
      .where((v) => medidaPlausivel(MedidaTipo.pesoKg, v))
      .toList();
  if (plausiveis.isNotEmpty) {
    return (valor: plausiveis.last, origem: PesoOrigem.avaliacao);
  }
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
  final plausiveis = historico
      .where((v) => medidaPlausivel(MedidaTipo.pesoKg, v))
      .toList();
  if (plausiveis.isNotEmpty) return plausiveis;
  if (historico.isNotEmpty) return const [];
  if (cadastro == null || !medidaPlausivel(MedidaTipo.pesoKg, cadastro)) {
    return const [];
  }
  return [cadastro];
}

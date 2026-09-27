import '../../checkin/data/checkin_repository.dart';

/// Snapshot da evolução de performance no Meu Treino (aluno).
class AlunoPerformanceEvolutionView {
  final String insight;
  final List<double> volumePorSemana;
  final List<double> forcaPorSemana;
  final String ultimoPrLabel;
  final double volumeSemanaKg;
  final double volumeMesKg;
  final EvolucaoPerformance? ultimaEvolucao;
  final bool hasChart;

  const AlunoPerformanceEvolutionView({
    required this.insight,
    required this.volumePorSemana,
    required this.forcaPorSemana,
    required this.ultimoPrLabel,
    required this.volumeSemanaKg,
    required this.volumeMesKg,
    this.ultimaEvolucao,
    required this.hasChart,
  });
}

String alunoPerformanceForcaDeltaInsight({
  required double? forcaDeltaPercent,
  List<double> volumePorSemana = const [],
  List<double> forcaPorSemana = const [],
}) {
  final delta = forcaDeltaPercent;
  if (delta != null && delta != 0) {
    final sinal = delta > 0 ? '+' : '';
    return 'Força (1RM est.) $sinal${_fmtNumero(delta)}% vs semana passada';
  }
  final hasSeries =
      volumePorSemana.any((v) => v > 0) || forcaPorSemana.any((v) => v > 0);
  if (hasSeries) return 'Volume e força nas últimas semanas';
  return 'Registre as séries para ver carga e volume.';
}

EvolucaoPerformance? alunoUltimaEvolucaoPerformance(
  List<ExecucaoTreino> historico,
) {
  for (final treino in historico) {
    if (treino.evolucoesPerformance.isNotEmpty) {
      return treino.evolucoesPerformance.first;
    }
    if (treino.evolucoesCarga.isNotEmpty) {
      final item = treino.evolucoesCarga.first;
      return EvolucaoPerformance(
        tipo: 'CARGA',
        exercicioId: item.exercicioId,
        exercicioNome: item.exercicioNome,
        valorAnterior: item.cargaAnteriorKg,
        valorAtual: item.cargaAtualKg,
        diferenca: item.diferencaKg,
        percentual: item.percentual,
        unidade: 'kg',
        mensagem: item.mensagem,
      );
    }
  }
  return null;
}

AlunoPerformanceEvolutionView buildAlunoPerformanceEvolutionView({
  required double? forcaDeltaPercent,
  required List<ExecucaoTreino> historico,
  required double volumeSemanaKg,
  required double volumeMesKg,
  required List<double> volumePorSemana,
  required List<double> forcaPorSemana,
  String? ultimoRecordeLabel,
}) {
  final ultima = alunoUltimaEvolucaoPerformance(historico);
  final volume = volumePorSemana;
  final forca = forcaPorSemana;
  final hasChart =
      volume.any((v) => v > 0) || forca.any((v) => v > 0);
  final recorde = ultimoRecordeLabel?.trim();
  final prLabel =
      recorde != null && recorde.isNotEmpty
          ? recorde
          : ultima == null
          ? '—'
          : '${_fmtNumero(ultima.valorAtual)} ${ultima.unidade}'.trim();

  return AlunoPerformanceEvolutionView(
    insight: alunoPerformanceForcaDeltaInsight(
      forcaDeltaPercent: forcaDeltaPercent,
      forcaPorSemana: forca,
      volumePorSemana: volume,
    ),
    volumePorSemana: volume,
    forcaPorSemana: forca,
    ultimoPrLabel: prLabel,
    volumeSemanaKg: volumeSemanaKg,
    volumeMesKg: volumeMesKg,
    ultimaEvolucao: ultima,
    hasChart: hasChart,
  );
}

String _fmtNumero(double value) {
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');
}

List<double> parseAlunoHomeSeries(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => (e as num?)?.toDouble() ?? 0.0)
      .toList(growable: false);
}

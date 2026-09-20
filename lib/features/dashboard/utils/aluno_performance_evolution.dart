import '../../checkin/data/checkin_repository.dart';
import '../data/aluno_autonomy_plan.dart';

/// Snapshot da evolução de performance no Meu Treino (aluno).
class AlunoPerformanceEvolutionView {
  final int score;
  final String scoreLabel;
  final String insight;
  final List<double> volumePorSemana;
  final List<double> forcaPorSemana;
  final String ultimoPrLabel;
  final double volumeSemanaKg;
  final double volumeMesKg;
  final EvolucaoPerformance? ultimaEvolucao;
  final bool hasChart;

  const AlunoPerformanceEvolutionView({
    required this.score,
    required this.scoreLabel,
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

String alunoPerformanceScoreLabel(int score) {
  if (score >= 85) return 'Excelente';
  if (score >= 70) return 'Em boa forma';
  if (score >= 50) return 'No ritmo';
  if (score >= 30) return 'Aquecendo';
  return 'Começando';
}

String alunoPerformanceForcaDeltaInsight({
  required List<double> forcaPorSemana,
  EvolucaoPerformance? ultimaEvolucao,
  required String nextSignal,
}) {
  if (ultimaEvolucao?.percentual != null && ultimaEvolucao!.percentual! != 0) {
    final pct = ultimaEvolucao.percentual!;
    final sinal = pct > 0 ? '+' : '';
    return 'Força $sinal$pct% no último PR · ${ultimaEvolucao.exercicioNome}';
  }
  final series = forcaPorSemana.where((v) => v > 0).toList();
  if (series.length >= 2) {
    final old = series.first;
    final neu = series.last;
    if (old > 0) {
      final pct = (((neu - old) / old) * 100).round();
      if (pct != 0) {
        final sinal = pct > 0 ? '+' : '';
        return 'Força $sinal$pct% nas últimas semanas';
      }
    }
  }
  final signal = nextSignal.trim();
  if (signal.isNotEmpty) return signal;
  return 'Registre as séries para o app enxergar carga, repetições e volume.';
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
  required FocuxScore score,
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
  final prLabel =
      ultima != null
          ? _labelEvolucaoTipo(ultima.tipo)
          : (ultimoRecordeLabel == null || ultimoRecordeLabel.isEmpty)
          ? '--'
          : ultimoRecordeLabel;

  return AlunoPerformanceEvolutionView(
    score: score.value,
    scoreLabel: alunoPerformanceScoreLabel(score.value),
    insight: alunoPerformanceForcaDeltaInsight(
      forcaPorSemana: forca,
      ultimaEvolucao: ultima,
      nextSignal: score.nextSignal,
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

String _labelEvolucaoTipo(String tipo) {
  switch (tipo) {
    case 'REPETICOES':
      return 'Repetições';
    case 'VOLUME':
      return 'Volume';
    default:
      return 'Carga';
  }
}

List<double> parseAlunoHomeSeries(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .map((e) => (e as num?)?.toDouble() ?? 0.0)
      .toList(growable: false);
}

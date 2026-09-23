import '../data/checkin_repository.dart';
import 'historico_display.dart';

/// Métricas da sessão derivadas do detalhe (Onda A) + opcional BFF (Onda B).
class HistoricoSessaoMetrics {
  const HistoricoSessaoMetrics({
    required this.seriesFeitas,
    required this.seriesPlanejadas,
    required this.recordes,
    this.volumeKg,
    this.volumeAnteriorKg,
    this.sinal = 'SEM_DADOS',
    this.sinalLabel = 'Sem séries registradas',
    this.destaqueExercicio,
    this.destaqueDeltaKg,
  });

  final double? volumeKg;
  final double? volumeAnteriorKg;
  final int seriesFeitas;
  final int seriesPlanejadas;
  final int recordes;
  final String sinal;
  final String sinalLabel;
  final String? destaqueExercicio;
  final double? destaqueDeltaKg;

  String get volumeLabel {
    if (volumeKg == null) return '—';
    return historicoVolumeLabel(volumeKg!);
  }

  String get seriesLabel => seriesPlanejadas > 0
      ? '$seriesFeitas/$seriesPlanejadas'
      : '$seriesFeitas';

  String get seriesHint => seriesPlanejadas > 0
      ? 'séries no plano'
      : (seriesFeitas > 0 ? 'séries feitas' : 'sem séries');
}

HistoricoSessaoMetrics historicoSessaoMetricsFromExecucao(ExecucaoTreino execucao) {
  var seriesFeitas = 0;
  var seriesPlanejadas = 0;
  var volume = 0.0;
  var hasVolume = false;

  for (final item in execucao.exercicios) {
    final feitas = historicoSeriesFeitasEfetivas(
      seriesFeitas: item.seriesFeitas,
      seriesDetalhesCount: item.seriesDetalhes.length,
    );
    seriesFeitas += feitas;
    if (item.series != null && item.series! > 0) {
      seriesPlanejadas += item.series!;
    }
    final vol = historicoVolumeExercicio(item.seriesDetalhes);
    if (vol != null) {
      volume += vol;
      hasVolume = true;
    }
  }

  final recordes = historicoRecordesCount(
    prs: execucao.evolucoesPerformance.length,
    cargas: execucao.evolucoesCarga.length,
  );

  final volumeOut = hasVolume ? volume : null;
  String sinal;
  String sinalLabel;
  if (volumeOut == null && seriesFeitas == 0) {
    sinal = 'SEM_DADOS';
    sinalLabel = historicoConcluido(execucao.status)
        ? 'Concluído sem séries registradas'
        : 'Sem séries registradas';
  } else {
    sinal = 'SESSAO';
    sinalLabel = historicoConcluido(execucao.status)
        ? 'Sessão registrada'
        : 'Sessão em andamento';
  }

  return HistoricoSessaoMetrics(
    volumeKg: volumeOut,
    seriesFeitas: seriesFeitas,
    seriesPlanejadas: seriesPlanejadas,
    recordes: recordes,
    sinal: sinal,
    sinalLabel: sinalLabel,
  );
}

HistoricoSessaoMetrics historicoSessaoMetricsFromDto(SessaoEvolucaoDto dto) {
  return HistoricoSessaoMetrics(
    volumeKg: dto.volumeKg,
    volumeAnteriorKg: dto.volumeAnteriorKg,
    seriesFeitas: dto.seriesFeitas,
    seriesPlanejadas: dto.seriesPlanejadas,
    recordes: dto.recordes,
    sinal: dto.sinal,
    sinalLabel: dto.sinalLabel,
    destaqueExercicio: dto.destaqueExercicio,
    destaqueDeltaKg: dto.destaqueDeltaKg,
  );
}

HistoricoSessaoMetrics historicoSessaoMetricsFromJson(Map<String, dynamic> j) {
  return historicoSessaoMetricsFromDto(SessaoEvolucaoDto.fromJson(j));
}

double? historicoVolumeExercicio(List<ExecucaoSerie> series) {
  var total = 0.0;
  var any = false;
  for (final s in series) {
    final carga = s.cargaKg;
    final reps = historicoPrimeiroNumero(s.repeticoes);
    if (carga == null || reps == null) continue;
    total += carga * reps;
    any = true;
  }
  return any ? total : null;
}

String historicoVolumeLabel(double kg) {
  if (kg >= 1000) {
    final mil = kg / 1000;
    final text = mil >= 10
        ? mil.toStringAsFixed(0)
        : mil.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    return '$text mil kg';
  }
  if (kg == kg.roundToDouble()) return '${kg.toStringAsFixed(0)} kg';
  return '${kg.toStringAsFixed(1)} kg';
}

String? historicoCargaDeltaLabel({
  required double? cargaAtual,
  required double? cargaAnterior,
}) {
  if (cargaAtual == null || cargaAnterior == null) return null;
  final delta = cargaAtual - cargaAnterior;
  if (delta.abs() < 0.05) return 'carga igual';
  final sign = delta > 0 ? '+' : '';
  final text = delta == delta.roundToDouble()
      ? delta.toStringAsFixed(0)
      : delta.toStringAsFixed(1);
  return '$sign$text kg vs anterior';
}

List<double> historicoCargaSparkValues(List<ExecucaoSerie> series) {
  return series
      .map((s) => s.cargaKg)
      .whereType<double>()
      .where((v) => v > 0)
      .toList(growable: false);
}

int? historicoPrimeiroNumero(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final match = RegExp(r'\d+').firstMatch(value);
  if (match == null) return null;
  return int.tryParse(match.group(0)!);
}

String historicoDeltaKgLabel(double delta) {
  final sign = delta > 0 ? '+' : '';
  final text = delta == delta.roundToDouble()
      ? delta.toStringAsFixed(0)
      : delta.toStringAsFixed(1);
  return '$sign$text kg vs anterior';
}

String historicoSinalChipLabel(String sinal) {
  return switch (sinal) {
    'MELHOROU' => 'Melhorou',
    'CAIU' => 'Caiu',
    'MANTEVE' => 'Estável',
    'PRIMEIRA' => '1ª vez',
    'SESSAO' => 'Sessão',
    _ => 'Sem dados',
  };
}

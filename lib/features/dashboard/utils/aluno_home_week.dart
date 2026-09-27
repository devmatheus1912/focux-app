import 'aluno_consistencia_display.dart';

/// Bloco "Sua semana": fatos de treino vindos do BFF, sem cálculo local.
class AlunoWeekSummary {
  /// Sessões concluídas na semana ISO; null quando o BFF não mandou.
  final int? feitos;

  /// Meta semanal; só existe junto com [feitos].
  final int? meta;
  final int streakSemanas;

  /// Volume da semana em kg; null quando zero (nada vira "0 kg").
  final double? volumeKg;

  const AlunoWeekSummary({
    required this.feitos,
    required this.meta,
    required this.streakSemanas,
    required this.volumeKg,
  });

  /// A sequência sempre aparece; sem sessões nem volume sobraria 1 métrica,
  /// abaixo do mínimo de 2 da faixa de KPI.
  bool get isEmpty => feitos == null && volumeKg == null;
}

AlunoWeekSummary buildAlunoWeekSummary({
  int? concluidosSemanaIso,
  int? frequenciaDias,
  required int streakAtual,
  required double volumeSemanaKg,
}) {
  final feitos =
      concluidosSemanaIso == null || concluidosSemanaIso < 0
          ? null
          : concluidosSemanaIso;
  return AlunoWeekSummary(
    feitos: feitos,
    meta:
        feitos == null
            ? null
            : alunoWeeklyDayGoal(frequenciaDias: frequenciaDias),
    streakSemanas: streakAtual < 0 ? 0 : streakAtual,
    volumeKg: volumeSemanaKg > 0 ? volumeSemanaKg : null,
  );
}

/// Recovery score derived from wearable / health platform signals.
class RecoveryScoreView {
  const RecoveryScoreView({
    required this.score,
    required this.label,
    required this.hint,
  });

  final int score;
  final String label;
  final String hint;

  static RecoveryScoreView compute({
    required int steps,
    required double sleepHours,
    required double avgHeartRate,
  }) {
    var score = 62;

    if (sleepHours >= 7.5) {
      score += 18;
    } else if (sleepHours >= 6.5) {
      score += 10;
    } else if (sleepHours >= 5.5) {
      score += 2;
    } else if (sleepHours > 0) {
      score -= 14;
    }

    if (steps >= 8000 && steps <= 14000) {
      score += 10;
    } else if (steps >= 5000) {
      score += 5;
    } else if (steps > 0 && steps < 3000) {
      score -= 6;
    }

    if (avgHeartRate > 0 && avgHeartRate <= 62) {
      score += 6;
    } else if (avgHeartRate >= 85) {
      score -= 4;
    }

    score = score.clamp(0, 100);

    if (score >= 80) {
      return RecoveryScoreView(
        score: score,
        label: 'Pronto para pesar',
        hint: 'Corpo recuperado — pode treinar forte hoje.',
      );
    }
    if (score >= 65) {
      return RecoveryScoreView(
        score: score,
        label: 'Treino moderado',
        hint: 'Boa base — mantenha volume controlado e aquecimento longo.',
      );
    }
    if (score >= 45) {
      return RecoveryScoreView(
        score: score,
        label: 'Recuperacao parcial',
        hint: 'Priorize mobilidade, sono e hidratacao antes de intensificar.',
      );
    }
    return RecoveryScoreView(
      score: score,
      label: 'Descanso recomendado',
      hint: 'Sono ou carga baixa — considere treino leve ou mobilidade.',
    );
  }
}

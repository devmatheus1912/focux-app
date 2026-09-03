const gamificacaoComoCalculamos =
    'Sequência conta dias seguidos com treino concluído. Recorde é o maior streak.';

String gamificacaoStreakLabel(int streak) {
  if (streak <= 0) return '0 dias';
  if (streak == 1) return '1 dia';
  return '$streak dias';
}

List<T> gamificacaoBadgePreview<T>(List<T> items) =>
    items.take(3).toList(growable: false);

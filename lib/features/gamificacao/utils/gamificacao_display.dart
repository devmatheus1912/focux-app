const gamificacaoComoCalculamos =
    'Sequência conta dias seguidos com treino concluído. Recorde é o maior streak. O servidor só concede streak, frequência e PR.';

const gamificacaoAlunoEmptyTitle = 'Sua evolução começa no treino';

const gamificacaoAlunoEmptySubtitle =
    'Conquistas e sequência aparecem depois do primeiro check-in concluído.';

const gamificacaoPersonalEmptyTitle = 'Conquistas são do aluno';

const gamificacaoPersonalEmptySubtitle =
    'O personal não tem streak neste hub. Abra o aluno para ver a sequência e os badges reais.';

String gamificacaoStreakLabel(int streak) {
  if (streak <= 0) return '0 dias';
  if (streak == 1) return '1 dia';
  return '$streak dias';
}

List<T> gamificacaoBadgePreview<T>(List<T> items) =>
    items.take(3).toList(growable: false);

String gamificacaoComoGanhar(String tipo) {
  switch (tipo.trim().toUpperCase()) {
    case 'STREAK_10':
      return 'Treine 10 dias seguidos';
    case 'FREQUENCIA_100':
      return 'Conclua todos os treinos do mês (mín. 4)';
    case 'PR_CARGA':
      return 'Bata um recorde de carga no check-in';
    default:
      return 'Conclua um treino para desbloquear';
  }
}

String gamificacaoBadgeSubtitle({required bool earned, required String tipo}) =>
    earned ? 'Conquistada' : gamificacaoComoGanhar(tipo);

String gamificacaoRotaDoBadge(String tipo, {required bool isAluno}) {
  switch (tipo.trim().toUpperCase()) {
    case 'FIRST_AI':
      return isAluno ? '/ia/aluno' : '/ia/copiloto';
    default:
      return '/checkin';
  }
}

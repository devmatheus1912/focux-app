const rankingComoCalculamos =
    'Posição pelo número de alunos ativos. O desconto do pódio vem do servidor.';

const rankingEmptyTitle = 'Ninguém no placar ainda';

const rankingEmptySubtitle =
    'A posição vem de alunos ativos. Top 3 ganham 20%, 15% ou 10% na assinatura Focux.';

String rankingDescontoLabel(int? percentual) {
  final value = percentual ?? 0;
  if (value <= 0) return '';
  return '$value% na assinatura';
}

String rankingItemSubtitle(int alunos, int? descontoPercentual) {
  final base = rankingAlunosLabel(alunos);
  final desconto = rankingDescontoLabel(descontoPercentual);
  if (desconto.isEmpty) return base;
  return '$base · $desconto';
}

String rankingCountLabel(int? total) {
  final count = total ?? 0;
  if (count <= 0) return 'Nenhum personal';
  if (count == 1) return '1 personal';
  return '$count personais';
}

String rankingAlunosLabel(int count) {
  if (count == 1) return '1 aluno ativo';
  return '$count alunos ativos';
}

String rankingPosicaoLabel(int posicao) => '$posicaoº';

String rankingSearchEmptyTitle(String query) =>
    query.trim().isEmpty ? rankingEmptyTitle : 'Nenhum personal encontrado';

String rankingSearchEmptySubtitle(String query) => query.trim().isEmpty
    ? rankingEmptySubtitle
    : 'Nada com esse nome neste ranking.';

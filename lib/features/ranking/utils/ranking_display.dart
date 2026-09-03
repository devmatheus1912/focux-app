const rankingComoCalculamos =
    'Posição pelo número de alunos ativos. O desconto do pódio vem do servidor.';

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

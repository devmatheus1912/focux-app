const rankingComoCalculamos =
    'Posição pelo número de alunos ativos. Empate: quem cadastrou antes fica na frente.';

const rankingEmptyTitle = 'Ninguém no placar ainda';

const rankingEmptySubtitle =
    'Posição por alunos ativos. Cadastre e ative alunos para subir no ranking.';

String rankingItemSubtitle(int alunos) => rankingAlunosLabel(alunos);

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

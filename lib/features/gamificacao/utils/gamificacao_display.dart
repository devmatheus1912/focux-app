const gamificacaoComoCalculamos =
    'No aluno, sequência é dias seguidos com treino. No personal, o número é quantos alunos estão em sequência e o recorde é o maior streak da base. O servidor só concede streak, frequência e PR.';

const gamificacaoAlunoEmptyTitle = 'Sua evolução começa no treino';

const gamificacaoAlunoEmptySubtitle =
    'Conquistas e sequência aparecem depois do primeiro check-in concluído.';

const gamificacaoPersonalEmptyTitle = 'Ainda sem evolução na base';

const gamificacaoPersonalEmptySubtitle =
    'Quando um aluno concluir um treino, a sequência e as conquistas da base aparecem aqui.';

String gamificacaoStreakTitle({required bool isAluno}) =>
    isAluno ? 'Sequência' : 'Alunos em sequência';

String gamificacaoStreakLabel(int streak, {bool isAluno = true}) {
  if (isAluno) {
    if (streak <= 0) return '0 dias';
    if (streak == 1) return '1 dia';
    return '$streak dias';
  }
  if (streak <= 0) return '0 alunos';
  if (streak == 1) return '1 aluno';
  return '$streak alunos';
}

String gamificacaoStreakHint({
  required bool isAluno,
  required int streak,
  required int recorde,
}) {
  if (isAluno) {
    return streak == 0
        ? 'Um treino hoje recomeça a série'
        : 'Recorde ${recorde}d';
  }
  return streak == 0
      ? 'Ninguém em sequência agora'
      : 'Recorde da base ${recorde}d';
}

List<T> gamificacaoBadgePreview<T>(List<T> items) =>
    items.take(3).toList(growable: false);

String gamificacaoComoGanhar(String tipo, {bool isAluno = true}) {
  switch (tipo.trim().toUpperCase()) {
    case 'STREAK_10':
      return isAluno
          ? 'Treine 10 dias seguidos'
          : 'Algum aluno treina 10 dias seguidos';
    case 'FREQUENCIA_100':
      return isAluno
          ? 'Conclua todos os treinos do mês (mín. 4)'
          : 'Algum aluno fecha o mês com 100%';
    case 'PR_CARGA':
      return isAluno
          ? 'Bata um recorde de carga no check-in'
          : 'Algum aluno bate um PR de carga';
    default:
      return isAluno
          ? 'Conclua um treino para desbloquear'
          : 'Aparece quando a base conquistar';
  }
}

String gamificacaoBadgeSubtitle({
  required bool earned,
  required String tipo,
  bool isAluno = true,
}) =>
    earned
        ? (isAluno ? 'Conquistada' : 'Na base')
        : gamificacaoComoGanhar(tipo, isAluno: isAluno);

String gamificacaoRotaDoBadge(String tipo, {required bool isAluno}) {
  if (!isAluno) return '/alunos';
  switch (tipo.trim().toUpperCase()) {
    case 'FIRST_AI':
      return '/chat/aluno';
    default:
      return '/checkin';
  }
}

String gamificacaoFocusLabel({required bool isAluno}) =>
    isAluno ? 'Ver check-in' : 'Ver alunos';

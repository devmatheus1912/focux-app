enum AlunoFiltro { todos, contatoHoje, ativos, inadimplentes, risco, novos }

String alunosListCountLabel(int total) {
  if (total <= 0) return 'Nenhum aluno';
  if (total == 1) return '1 aluno';
  return '$total alunos';
}

enum AlunoOrdenacao { prioridade, nome, semFoto }

String alunosSelectionTitle(int count) =>
    count == 1 ? '1 aluno selecionado' : '$count alunos selecionados';

String mensalidadesPagasMessage(int count) =>
    count == 1
        ? '1 mensalidade marcada como paga'
        : '$count mensalidades marcadas como pagas';

String alunosAtualizadosMessage(int count) =>
    count == 1 ? '1 aluno atualizado' : '$count alunos atualizados';

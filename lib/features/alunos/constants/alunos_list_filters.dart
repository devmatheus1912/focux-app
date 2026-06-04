enum AlunoFiltro { todos, contatoHoje, ativos, inadimplentes, risco, novos }

enum AlunoOrdenacao { prioridade, nome, semFoto }

String alunosSelectionTitle(int count) =>
    count == 1 ? '1 aluno selecionado' : '$count alunos selecionados';

String mensalidadesPagasMessage(int count) =>
    count == 1
        ? '1 mensalidade marcada como paga'
        : '$count mensalidades marcadas como pagas';

String alunosAtualizadosMessage(int count) =>
    count == 1 ? '1 aluno atualizado' : '$count alunos atualizados';

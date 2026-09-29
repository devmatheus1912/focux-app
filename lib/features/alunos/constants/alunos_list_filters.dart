enum AlunoFiltro { todos, contatoHoje, ativos, inadimplentes, risco, novos }

String alunosListCountLabel(int total) {
  if (total <= 0) return 'Nenhum aluno';
  if (total == 1) return '1 aluno';
  return '$total alunos';
}

enum AlunoOrdenacao { prioridade, nome, semFoto }

/// Aba Alunos já filtrada pelo termo (lido de volta em `/alunos?q=`).
String alunosBuscaLocation(String termo) {
  final q = termo.trim();
  if (q.isEmpty) return '/alunos';
  return Uri(path: '/alunos', queryParameters: {'q': q}).toString();
}

/// Mesma location sem o `q`; o filtro e demais parâmetros ficam.
String alunosLocationSemBusca(Uri location) {
  final params = Map.of(location.queryParameters)..remove('q');
  return Uri(
    path: location.path,
    queryParameters: params.isEmpty ? null : params,
  ).toString();
}

/// Termo que a busca assume quando a rota muda com a aba aberta.
/// `null` mantém o termo atual; rota nova de filtro sem `q` zera a busca.
String? alunosBuscaAposNavegacao({
  required String busca,
  required String buscaAtual,
  required bool filtroMudou,
}) {
  final atual = buscaAtual.trim();
  if (busca.isNotEmpty) return busca == atual ? null : busca;
  if (filtroMudou && atual.isNotEmpty) return '';
  return null;
}

String alunosSelectionTitle(int count) =>
    count == 1 ? '1 aluno selecionado' : '$count alunos selecionados';

String mensalidadesPagasMessage(int count) =>
    count == 1
        ? '1 mensalidade marcada como paga'
        : '$count mensalidades marcadas como pagas';

String alunosAtualizadosMessage(int count) =>
    count == 1 ? '1 aluno atualizado' : '$count alunos atualizados';

String alunosExcluidosMessage(int count) => switch (count) {
  0 => 'Nenhum aluno foi excluído.',
  1 => '1 aluno excluído.',
  _ => '$count alunos excluídos.',
};

String alunosSelectionSummary(int count) => switch (count) {
  0 => 'Selecione os alunos',
  1 => '1 selecionado',
  _ => '$count selecionados',
};

String alunoFiltroLabel(AlunoFiltro filtro) => switch (filtro) {
  AlunoFiltro.todos => 'todos',
  AlunoFiltro.contatoHoje => 'precisando de contato hoje',
  AlunoFiltro.ativos => 'ativos',
  AlunoFiltro.inadimplentes => 'em atraso',
  AlunoFiltro.risco => 'em risco',
  AlunoFiltro.novos => 'convites pendentes',
};

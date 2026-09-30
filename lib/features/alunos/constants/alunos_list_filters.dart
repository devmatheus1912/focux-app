enum AlunoFiltro { todos, contatoHoje, ativos, inadimplentes, risco, novos }

String alunosListCountLabel(int total) {
  if (total <= 0) return 'Nenhum aluno';
  if (total == 1) return '1 aluno';
  return '$total alunos';
}

enum AlunoOrdenacao { prioridade, nome, semFoto }

/// Aba Alunos filtrada pelo termo. O nome **não** vai na URL (histórico web / LGPD).
String alunosBuscaLocation(String termo) {
  AlunosPendingSearch.offer(termo.trim());
  return '/alunos';
}

/// Termo vindo da Hoje / sheet — uma leitura. Aviso se a aba já está em `/alunos`.
class AlunosPendingSearch {
  static String? _term;
  static final List<void Function()> _listeners = [];

  static void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  static void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  static void offer(String termo) {
    final t = termo.trim();
    _term = t.isEmpty ? null : t;
    if (_term == null) return;
    for (final l in List<void Function()>.of(_listeners)) {
      l();
    }
  }

  static String? consume() {
    final v = _term;
    _term = null;
    return v;
  }
}

/// Mesma location sem o `q`; o filtro e demais parâmetros ficam.
String alunosLocationSemBusca(Uri location) {
  final params = Map.of(location.queryParameters)..remove('q');
  return Uri(
    path: location.path,
    queryParameters: params.isEmpty ? null : params,
  ).toString();
}

/// Location sem `q` quando ela diverge da busca atual; `null` = não mexer.
/// Sem isso, repetir a mesma busca da Hoje não muda a rota e é ignorado.
String? alunosLocationParaBusca(Uri location, String busca) {
  final q = location.queryParameters['q'];
  if (q == null || q == busca.trim()) return null;
  return alunosLocationSemBusca(location);
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

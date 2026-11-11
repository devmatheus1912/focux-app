import '../../alunos/data/aluno_repository.dart';

List<Aluno> filterAlunoPickerAlunos(List<Aluno> alunos, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return alunos;
  return alunos
      .where(
        (a) =>
            a.nome.toLowerCase().contains(q) ||
            a.email.toLowerCase().contains(q),
      )
      .toList();
}

/// Dias sem treino a partir dos quais o aluno "precisa de você" na folha
/// (mesmo gatilho do coach proativo).
const alunoConversaDiasParado = 5;

/// Risco alto/médio (`AlertasService.calcularRisco`, já no `riscoNivel`) ou
/// parado há [alunoConversaDiasParado] dias ou mais.
bool alunoPrecisaDeVoce(Aluno a) {
  final risco = (a.riscoNivel ?? '').toUpperCase();
  if (risco == 'ALTO' || risco == 'MEDIO') return true;
  final dias = a.diasSemTreino;
  return dias != null && dias >= alunoConversaDiasParado;
}

/// Motivo curto para a linha: "Parado há 7 dias", "Risco alto".
String? alunoMotivoAtencao(Aluno a) {
  final dias = a.diasSemTreino;
  if (dias != null && dias >= alunoConversaDiasParado) {
    return 'Parado há $dias dias';
  }
  return switch ((a.riscoNivel ?? '').toUpperCase()) {
    'ALTO' => 'Risco alto',
    'MEDIO' => 'Risco médio',
    _ => null,
  };
}

int _porNome(Aluno a, Aluno b) =>
    a.nome.toLowerCase().compareTo(b.nome.toLowerCase());

bool _ativo(Aluno a) => a.status.toUpperCase() == 'ATIVO';

/// Folha "Nova conversa": quem precisa de você primeiro, depois o resto em
/// ordem alfabética. Com busca, uma lista só.
({List<Aluno> precisam, List<Aluno> todos}) gruposDaNovaConversa(
  List<Aluno> alunos,
  String query,
) {
  final filtrados = filterAlunoPickerAlunos(alunos, query);
  if (query.trim().isNotEmpty) {
    return (precisam: const [], todos: [...filtrados]..sort(_porNome));
  }
  final precisam = [
    for (final a in filtrados)
      if (_ativo(a) && alunoPrecisaDeVoce(a)) a,
  ]..sort(_porNome);
  final ids = {for (final a in precisam) a.id};
  final todos = [
    for (final a in filtrados)
      if (!ids.contains(a.id)) a,
  ]..sort(_porNome);
  return (precisam: precisam, todos: todos);
}

/// "Comece uma conversa": até [limite] alunos ativos sem conversa, quem
/// precisa de você primeiro. Só faz sentido com o inbox inteiro carregado.
List<Aluno> sugestoesDeConversa(
  List<Aluno> alunos, {
  required Set<int> comConversa,
  int limite = 3,
}) {
  final sem = [
    for (final a in alunos)
      if (_ativo(a) && !comConversa.contains(a.id)) a,
  ];
  sem.sort((a, b) {
    final pa = alunoPrecisaDeVoce(a) ? 0 : 1;
    final pb = alunoPrecisaDeVoce(b) ? 0 : 1;
    return pa != pb ? pa - pb : _porNome(a, b);
  });
  return sem.take(limite).toList();
}

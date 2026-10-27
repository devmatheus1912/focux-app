import '../data/retencao_repository.dart';

bool retencaoNomeExibivel(String nome) {
  final t = nome.trim();
  if (t.isEmpty) return false;
  // Defesa FE: BE (#46) já exclui blank/"Aluno"; mantém filtro se payload antigo.
  return t.toLowerCase() != 'aluno';
}

/// "Saúde 10 de 100": o score é de saúde, não de risco (maior = mais saudável).
String retencaoSaudeCurta(RetencaoAlunoScore score) =>
    'Saúde ${score.scoreAtual} de 100';

const retencaoEmptyTitle = 'Ainda sem leitura desta base';

const retencaoEmptySubtitle =
    'Cadastre alunos ativos. Ao abrir de novo, o score recalcula com os '
    'check-ins concluídos (dias únicos, sem duplicar o mesmo dia).';

/// Único verbo que sobrou fora da tela: levar a quem ainda não tem alunos.
enum RetencaoFocusActionId { verAlunos }

String retencaoFocusActionLabel(RetencaoFocusActionId id) => switch (id) {
  RetencaoFocusActionId.verAlunos => 'Ver alunos',
};

const retencaoComoUsar = 'Como usar a tela';

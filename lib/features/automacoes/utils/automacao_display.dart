enum AutomacaoChip { todos, templates, ativos }

String automacaoChipLabel(AutomacaoChip chip) => switch (chip) {
  AutomacaoChip.todos => 'Todos',
  AutomacaoChip.templates => 'Templates',
  AutomacaoChip.ativos => 'Ativos',
};

String automacaoCountLabel({required int templates, required int fluxos}) {
  final n = templates + fluxos;
  if (n <= 0) return 'Nenhuma automação';
  if (n == 1) return '1 automação';
  return '$n automações';
}

String automacaoTriggerLabel(String raw) {
  switch (raw.trim().toUpperCase()) {
    case 'NOVO_ALUNO':
      return 'Novo aluno';
    case 'CHECKIN':
      return 'Check-in';
    case 'INADIMPLENCIA':
      return 'Inadimplência';
    case 'ANIVERSARIO':
      return 'Aniversário';
    default:
      final t = raw.trim();
      return t.isEmpty ? 'Gatilho' : t;
  }
}

String automacaoLogStatusLabel(String status) {
  switch (status.trim().toUpperCase()) {
    case 'ATIVO':
      return 'Em andamento';
    case 'CONCLUIDO':
    case 'CONCLUÍDO':
      return 'Concluído';
    case 'PAUSADO':
      return 'Pausado';
    case 'ERRO':
      return 'Erro';
    default:
      final t = status.trim();
      return t.isEmpty ? 'Sem status' : t;
  }
}

bool automacaoMatchesQuery({
  required String nome,
  required String? descricao,
  required String triggerTipo,
  required String query,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (nome.toLowerCase().contains(q)) return true;
  if ((descricao ?? '').toLowerCase().contains(q)) return true;
  return automacaoTriggerLabel(triggerTipo).toLowerCase().contains(q);
}

String automacaoFluxoStatusLabel({required bool ativo}) =>
    ativo ? 'Ativo' : 'Pausado';

String automacaoLogSubtitle({required String status, required int passoAtual}) {
  final passo = passoAtual < 0 ? 1 : passoAtual + 1;
  return '${automacaoLogStatusLabel(status)} · passo $passo';
}

String automacaoAtivarTitle(String nome) => 'Ativar “$nome”?';

String automacaoAtivarMessage() =>
    'O fluxo começa a rodar para os alunos que baterem o gatilho.';

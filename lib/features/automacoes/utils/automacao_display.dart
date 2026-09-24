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
    case 'ALUNO_CRIADO':
      return 'Novo aluno';
    case 'DIAS_SEM_CHECKIN':
      return '4 dias sem treinar';
    case 'ALUNO_VIA_LEAD':
      return 'Interessado virou aluno';
    case 'RECORDE_PESSOAL':
      return 'Novo recorde';
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
      return 'Falhou';
    case 'CANCELADO':
      return 'Cancelado';
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

String automacaoLogSubtitle({
  required String status,
  required int passoAtual,
  int entregasOk = 0,
  int entregasFalha = 0,
}) {
  final passo = passoAtual < 0 ? 1 : passoAtual + 1;
  return [
    '${automacaoLogStatusLabel(status)} · passo $passo',
    if (entregasOk > 0) entregasOk == 1 ? '1 enviada' : '$entregasOk enviadas',
    if (entregasFalha > 0)
      entregasFalha == 1 ? '1 falhou' : '$entregasFalha falharam',
  ].join(' · ');
}

bool automacaoLogComProblema({required String status, required int entregasFalha}) =>
    status.trim().toUpperCase() == 'ERRO' || entregasFalha > 0;

String automacaoAtivarTitle(String nome) => 'Ativar “$nome”?';

String automacaoAtivarMessage() =>
    'O fluxo começa a rodar para os alunos que baterem o gatilho.';

String automacaoIniciarLabel() => 'Iniciar para um aluno';

String automacaoIniciarPickerTitle() => 'Aluno';

String automacaoIniciarConfirmTitle(String nome) => 'Iniciar para $nome?';

String automacaoIniciarConfirmMessage() =>
    'O fluxo começa agora neste aluno.';

String automacaoIniciarSuccess() => 'Fluxo iniciado';

String automacaoSemAlunos() =>
    'Cadastre um aluno para iniciar o fluxo.';

String automacaoPausarLabel() => 'Pausar fluxo';

String automacaoRetomarLabel() => 'Retomar fluxo';

String automacaoPausarConfirmTitle(String nome) => 'Pausar “$nome”?';

String automacaoPausarConfirmMessage() =>
    'O gatilho para de disparar e quem está no meio do fluxo espera até você retomar.';

String automacaoRetomarConfirmTitle(String nome) => 'Retomar “$nome”?';

String automacaoRetomarConfirmMessage() =>
    'Quem estava no meio do fluxo continua de onde parou, e novos alunos voltam a entrar.';

String automacaoPausarSuccess() => 'Fluxo pausado';

String automacaoRetomarSuccess() => 'Fluxo retomado';

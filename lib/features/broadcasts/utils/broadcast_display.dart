const broadcastPublicos = ['TODOS', 'ONLINE', 'PRESENCIAL', 'HIBRIDO'];

String broadcastPublicoLabel(String? raw) =>
    switch ((raw ?? 'TODOS').trim().toUpperCase()) {
      'ONLINE' => 'Online',
      'PRESENCIAL' => 'Presencial',
      'HIBRIDO' => 'Híbrido',
      _ => 'Todos',
    };

String broadcastPublicoFxIcon(String raw) => switch (raw.trim().toUpperCase()) {
  'ONLINE' => 'sun',
  'PRESENCIAL' => 'home',
  'HIBRIDO' => 'users',
  _ => 'message-circle',
};

String broadcastChoiceValue(bool selected) => selected ? 'Ativo' : '';

String? broadcastTipoApi(String publico) =>
    publico == 'TODOS' ? null : publico;

String broadcastRequiredTitulo() => 'Informe o título';

String broadcastRequiredMensagem() => 'Informe a mensagem';

String broadcastSendSuccess(int count) {
  if (count <= 0) return 'Nenhum aluno no público escolhido.';
  if (count == 1) return 'Enviado para 1 aluno.';
  return 'Enviado para $count alunos.';
}

String broadcastAlunosValue(int count) {
  if (count == 1) return '1 aluno';
  return '$count alunos';
}

String broadcastConfirmTitle(String publico) {
  if (publico == 'TODOS') return 'Enviar para toda a base?';
  return 'Enviar para ${broadcastPublicoLabel(publico).toLowerCase()}?';
}

String broadcastConfirmMessage() =>
    'A notificação chega de uma vez nos apps dos alunos deste público.';

String broadcastConfirmLabel() => 'Enviar';

String broadcastEnviosCaption(int count) {
  if (count <= 0) return 'Nenhum envio ainda';
  if (count == 1) return '1 envio';
  return '$count envios';
}

String broadcastHistoricoHeader() => 'Histórico';

String broadcastEmptyTitle() => 'Nenhum broadcast enviado';

String broadcastEmptySubtitle() =>
    'Escreva a primeira mensagem acima para avisar sua base de uma vez.';

String broadcastFormatDate(DateTime dt) {
  final dia = dt.day.toString().padLeft(2, '0');
  final mes = dt.month.toString().padLeft(2, '0');
  final hora = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$dia/$mes · $hora:$min';
}

String broadcastTileSubtitle(String mensagem, DateTime enviadoEm) {
  final compact = mensagem.trim().replaceAll(RegExp(r'\s+'), ' ');
  final preview = compact.length > 80 ? '${compact.substring(0, 80)}…' : compact;
  return '$preview\n${broadcastFormatDate(enviadoEm)}';
}

const broadcastPublicos = ['TODOS', 'ONLINE', 'PRESENCIAL', 'HIBRIDO'];

String broadcastPublicoLabel(String? raw) =>
    switch ((raw ?? 'TODOS').trim().toUpperCase()) {
      'ONLINE' => 'Online',
      'PRESENCIAL' => 'Presencial',
      'HIBRIDO' => 'Híbrido',
      _ => 'Todos',
    };

String broadcastPublicoFxIcon(String raw) => switch (raw.trim().toUpperCase()) {
  'ONLINE' => 'message-circle',
  'PRESENCIAL' => 'home',
  'HIBRIDO' => 'users',
  _ => 'users',
};

/// Rótulo do público com o alcance, quando já chegou.
String broadcastPublicoChip(String publico, int? total) {
  final label = broadcastPublicoLabel(publico);
  return total == null ? label : '$label $total';
}

/// "Todos" inclui quem ainda está sem tipo de consultoria.
String? broadcastSemTipoAviso(Map<String, int> totais) {
  final todos = totais['TODOS'];
  if (todos == null) return null;
  final comTipo = totais.entries
      .where((e) => e.key != 'TODOS')
      .fold<int>(0, (soma, e) => soma + e.value);
  final semTipo = todos - comTipo;
  if (semTipo <= 0) return null;
  return semTipo == 1
      ? '1 aluno está sem tipo de consultoria e só recebe em Todos.'
      : '$semTipo alunos estão sem tipo de consultoria e só recebem em Todos.';
}

const broadcastAtalhos = <({String nome, String titulo, String mensagem})>[
  (
    nome: 'Lembrete de treino',
    titulo: 'Lembrete de treino',
    mensagem: 'Seu treino de hoje já está no app. Bora?',
  ),
  (
    nome: 'Feriado',
    titulo: 'Atendimento no feriado',
    mensagem: 'No feriado não terei atendimento. Volto no dia seguinte.',
  ),
  (
    nome: 'Mudança de horário',
    titulo: 'Mudança de horário',
    mensagem: 'Meus horários mudaram. Confira a agenda no app.',
  ),
];

String? broadcastTipoApi(String publico) =>
    publico == 'TODOS' ? null : publico;

String broadcastRequiredTitulo() => 'Informe o título';

String broadcastRequiredMensagem() => 'Informe a mensagem';

String broadcastSendSuccess(int count, {int? comPush}) {
  if (count <= 0) return 'Nenhum aluno no público escolhido.';
  final base = count == 1 ? 'Enviado para 1 aluno' : 'Enviado para $count alunos';
  if (comPush == null) return '$base.';
  if (comPush >= count) return '$base, com notificação no celular.';
  if (comPush <= 0) {
    return '$base. Nenhum tem notificação ativa; eles veem ao abrir o app.';
  }
  return '$base. ${broadcastComPushLabel(comPush)}; os demais veem ao abrir o app.';
}

String broadcastComPushLabel(int comPush) =>
    comPush == 1 ? '1 com notificação' : '$comPush com notificação';

String broadcastAlunosValue(int count, {int? comPush}) {
  final base = count == 1 ? '1 aluno' : '$count alunos';
  if (comPush == null) return base;
  return '$base · ${broadcastComPushLabel(comPush)}';
}

String broadcastAlunosLabel(int total) =>
    total == 1 ? '1 aluno' : '$total alunos';

String broadcastConfirmTitle(String publico, {int? total}) {
  if (total != null) return 'Enviar para ${broadcastAlunosLabel(total)}?';
  if (publico == 'TODOS') return 'Enviar para todos os alunos?';
  return 'Enviar para ${broadcastPublicoLabel(publico).toLowerCase()}?';
}

String broadcastConfirmMessage({int? total, int? comPush}) {
  if (total == null || comPush == null) {
    return 'O aviso chega de uma vez no app dos alunos deste público.';
  }
  if (comPush >= total) return 'Todos recebem no celular.';
  if (comPush <= 0) return 'Eles veem ao abrir o app.';
  return '$comPush recebem no celular; os outros veem ao abrir o app.';
}

String broadcastConfirmLabel() => 'Enviar';

String broadcastEnviosCaption(int count) {
  if (count <= 0) return 'Nenhum envio ainda';
  if (count == 1) return '1 envio';
  return '$count envios';
}

String broadcastHistoricoHeader() => 'Histórico';

String broadcastEmptyTitle() => 'Nenhum aviso enviado';

String broadcastEmptySubtitle() =>
    'Escreva o primeiro aviso acima para falar com seus alunos de uma vez.';

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

enum ChatInboxHubView { todas, naoLidas, arquivadas }

String chatInboxHubViewLabel(ChatInboxHubView view) => switch (view) {
  ChatInboxHubView.todas => 'Todas',
  ChatInboxHubView.naoLidas => 'Não lidas',
  ChatInboxHubView.arquivadas => 'Arquivadas',
};

String chatInboxHubSubtitle({
  required ChatInboxHubView view,
  String? freshness,
}) {
  final label = chatInboxHubViewLabel(view);
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return label;
  return '$label · $stamp';
}

String chatInboxEmptyTitle(ChatInboxHubView view) => switch (view) {
  ChatInboxHubView.todas => 'Nenhuma conversa ainda',
  ChatInboxHubView.naoLidas => 'Nenhuma mensagem não lida',
  ChatInboxHubView.arquivadas => 'Nenhuma conversa arquivada',
};

String chatInboxEmptySubtitle(ChatInboxHubView view) => switch (view) {
  ChatInboxHubView.todas => 'Escolha um aluno para começar uma conversa.',
  ChatInboxHubView.naoLidas => 'Quando chegar algo novo, aparece aqui.',
  ChatInboxHubView.arquivadas =>
    'Arraste conversas para a esquerda para arquivar.',
};

String chatInboxSelectionTitle(int count) {
  if (count <= 0) return 'Selecione mensagens';
  if (count == 1) return '1 selecionada';
  return '$count selecionadas';
}

String chatInboxDeleteConfirmTitle(int count) =>
    count == 1 ? 'Excluir mensagens?' : 'Excluir conversas?';

String chatInboxDeleteConfirmMessage(int count) {
  if (count == 1) {
    return 'As mensagens desta conversa serão limpas da sua caixa.';
  }
  return 'As mensagens das $count conversas selecionadas serão limpas da sua caixa.';
}

String chatInboxDeleteDoneLabel(int count) =>
    count == 1 ? 'Mensagens excluídas' : 'Conversas excluídas';

String chatInboxActionLabel(String action) => switch (action) {
  'pin' => 'Fixada',
  'unpin' => 'Desafixada',
  'archive' => 'Arquivada',
  'unarchive' => 'Desarquivada',
  'mute' => 'Silenciada',
  'unmute' => 'Notificações ativadas',
  'clear' => 'Conversa limpa',
  _ => 'Ação aplicada',
};

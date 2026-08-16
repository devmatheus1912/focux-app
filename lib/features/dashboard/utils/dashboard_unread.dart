/// Chat unread SSOT da Home: campo BFF `pulse.mensagensNaoLidas`.
/// Não misturar com notificações de app (`notificacoesNaoLidas`).
int dashboardChatUnreadCount(int? pulseMensagensNaoLidas) {
  final n = pulseMensagensNaoLidas ?? 0;
  return n < 0 ? 0 : n;
}

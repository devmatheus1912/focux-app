/// Subtítulo do atalho Mensagens — prioriza não-lidas do BFF pulse.
String dashboardChatShortcutSubtitle({
  required int unreadCount,
  required int conversationCount,
}) {
  if (unreadCount > 0) {
    return '$unreadCount não lida${unreadCount == 1 ? '' : 's'}';
  }
  if (conversationCount > 0) {
    return '$conversationCount conversa${conversationCount == 1 ? '' : 's'}';
  }
  return 'Abrir mensagens';
}

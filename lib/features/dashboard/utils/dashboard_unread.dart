/// Resolve não-lidas da Home: inbox vivo quando carregado; pulse no first paint.
int dashboardResolveUnreadCount({
  required int? pulseUnread,
  required bool inboxReady,
  required int inboxUnread,
}) {
  if (inboxReady) return inboxUnread < 0 ? 0 : inboxUnread;
  final pulse = pulseUnread ?? 0;
  return pulse < 0 ? 0 : pulse;
}

part of 'chat_inbox_screen.dart';

extension on _ChatInboxScreenState {
  Future<void> _loadMoreInbox() async {
    if (_loadingMoreInbox || !_inboxHasMore) return;
    final home = ref.read(chatInboxHomeProvider).value;
    if (home == null || home.inboxSize <= 0) return;
    setState(() => _loadingMoreInbox = true);
    try {
      final loaded = home.inbox.length + _extraInbox.length;
      final nextPage = loaded ~/ home.inboxSize;
      final page = await ChatRepository(
        ref.read(apiClientProvider),
      ).inboxPage(
        page: nextPage,
        size: home.inboxSize,
        q: ref.read(chatInboxQueryProvider),
      );
      final seen = <int>{
        ...home.inbox.map((item) => item.alunoId),
        ..._extraInbox.map((item) => item.alunoId),
      };
      if (!mounted) return;
      setState(() {
        _extraInbox.addAll(
          page.items.where((item) => seen.add(item.alunoId)),
        );
        _inboxHasMore = page.hasMore;
        _loadingMoreInbox = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMoreInbox = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _loadMoreUnread() async {
    if (_loadingMoreUnread || !_unreadHasMore) return;
    final home = ref.read(chatInboxHomeProvider).value;
    if (home == null || home.inboxSize <= 0) return;
    setState(() => _loadingMoreUnread = true);
    try {
      final loaded = home.unread.length + _extraUnread.length;
      final nextPage = loaded ~/ home.inboxSize;
      final page = await ChatRepository(
        ref.read(apiClientProvider),
      ).inboxUnreadPage(
        page: nextPage,
        size: home.inboxSize,
        q: ref.read(chatInboxQueryProvider),
      );
      final seen = <int>{
        ...home.unread.map((item) => item.alunoId),
        ..._extraUnread.map((item) => item.alunoId),
      };
      if (!mounted) return;
      setState(() {
        _extraUnread.addAll(
          page.content.where((item) => seen.add(item.alunoId)),
        );
        _unreadHasMore = page.hasNext;
        _loadingMoreUnread = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMoreUnread = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _loadMoreArchived() async {
    if (_loadingMoreArchived || !_archivedHasMore) return;
    final home = ref.read(chatInboxHomeProvider).value;
    if (home == null || home.inboxSize <= 0) return;
    setState(() => _loadingMoreArchived = true);
    try {
      final loaded = home.archived.length + _extraArchived.length;
      final nextPage = loaded ~/ home.inboxSize;
      final page = await ChatRepository(
        ref.read(apiClientProvider),
      ).inboxArchivedPage(
        page: nextPage,
        size: home.inboxSize,
        q: ref.read(chatInboxQueryProvider),
      );
      final seen = <int>{
        ...home.archived.map((item) => item.alunoId),
        ..._extraArchived.map((item) => item.alunoId),
      };
      if (!mounted) return;
      setState(() {
        _extraArchived.addAll(
          page.content.where((item) => seen.add(item.alunoId)),
        );
        _archivedHasMore = page.hasNext;
        _loadingMoreArchived = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMoreArchived = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }
}

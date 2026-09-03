part of 'chat_inbox_screen.dart';

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen> {
  ChatInboxHubView _view = ChatInboxHubView.todas;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;
  List<ChatMsg>? _searchResults;
  final Set<int> _selectedAlunoIds = <int>{};
  DateTime? _fetchedAt;
  final DateTime _openedAt = DateTime.now();
  bool _viewTracked = false;
  bool _ttvTracked = false;
  final _extraInbox = <ChatInboxItem>[];
  var _inboxHasMore = false;
  var _loadingMoreInbox = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _abrirVista() async {
    HapticFeedback.selectionClick();
    final picked = await showFxInsetPickerSheet<ChatInboxHubView>(
      context,
      title: 'Ver',
      selected: _view,
      items: [
        for (final v in ChatInboxHubView.values)
          FxInsetPickerSheetItem(
            value: v,
            label: chatInboxHubViewLabel(v),
          ),
      ],
    );
    if (!mounted || picked == null || picked == _view) return;
    setState(() => _view = picked);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    try {
      final results = await ChatRepository(
        ref.read(apiClientProvider),
      ).globalSearch(query.trim());
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      _selectedAlunoIds.clear();
      if (!_isSearching) {
        _searchCtrl.clear();
        _searchResults = null;
      }
    });
  }

  bool get _selectionActive => _selectedAlunoIds.isNotEmpty;

  void _toggleSelection(int alunoId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedAlunoIds.contains(alunoId)) {
        _selectedAlunoIds.remove(alunoId);
      } else {
        _selectedAlunoIds.add(alunoId);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedAlunoIds.clear());
  }

  Future<void> _deleteSelectedConversations() async {
    final ids = _selectedAlunoIds.toList();
    if (ids.isEmpty) return;

    final confirm = await showFxConfirmSheet(
      context,
      title: chatInboxDeleteConfirmTitle(ids.length),
      message: chatInboxDeleteConfirmMessage(ids.length),
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (!confirm) return;

    HapticFeedback.mediumImpact();
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      for (final alunoId in ids) {
        await repo.conversationAction(alunoId, 'clear');
      }
      _clearSelection();
      invalidateChatInboxCaches(ref);
      if (!mounted) return;
      FeedbackHelper.showInfo(
        context,
        chatInboxDeleteDoneLabel(ids.length),
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _conversationAction(int alunoId, String action) async {
    HapticFeedback.mediumImpact();
    try {
      await ChatRepository(
        ref.read(apiClientProvider),
      ).conversationAction(alunoId, action);
      invalidateChatInboxCaches(ref);
      if (mounted) {
        FeedbackHelper.showInfo(context, chatInboxActionLabel(action));
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  PreferredSizeWidget _buildAppBar({
    required Color ink,
    required Color mute,
    required String? freshnessLabel,
  }) {
    if (_selectionActive) {
      return FxShellAppBar(
        title: chatInboxSelectionTitle(_selectedAlunoIds.length),
        leading: IconButton(
          onPressed: _clearSelection,
          icon: Container(
            width: 38,
            height: 38,
            decoration: ShellChrome.of(context).headerAction(radius: 12),
            child: Icon(Icons.close_rounded, color: ink, size: 18),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Excluir mensagens',
            icon: const Icon(Icons.delete_outline_rounded),
            color:
                _selectedAlunoIds.isEmpty
                    ? mute.withValues(alpha: 0.45)
                    : EagleTokens.bad,
            onPressed:
                _selectedAlunoIds.isEmpty
                    ? null
                    : _deleteSelectedConversations,
          ),
        ],
      );
    }
    if (_isSearching) {
      return FxShellAppBar(
        title: 'Buscar',
        onBack: _toggleSearch,
      );
    }
    return FxShellAppBar(
      title: 'Mensagens',
      subtitle: chatInboxHubSubtitle(
        view: _view,
        freshness: freshnessLabel,
      ),
      onBack: () => safePopOrGo(context, '/dashboard/personal'),
      actions: [
        FxHelpIconButton(
          tooltip: 'Como usar as mensagens',
          onTap: () {
            AnalyticsService.instance.track(
              ProductEvents.chatInboxHelpOpened,
            );
            showChatInboxHelpSheet(context);
          },
        ),
        const SizedBox(width: FxHelpChrome.gap),
        ShellHeaderIconButton(
          icon: 'search',
          tooltip: 'Buscar conversas',
          onTap: _toggleSearch,
        ),
        ShellHeaderIconButton(
          icon: 'chat',
          tooltip: 'Trocar visão',
          onTap: _abrirVista,
        ),
        ShellHeaderIconButton(
          icon: 'plus',
          tooltip: 'Nova mensagem',
          onTap: _showAlunoPicker,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = chrome.ink;
    final mute = chrome.mute;
    ref.listen<AsyncValue<ChatInboxHomeBundle>>(chatInboxHomeProvider, (
      _,
      next,
    ) {
      if (!next.isLoading && next.hasValue) {
        final home = next.requireValue;
        setState(() {
          _fetchedAt = DateTime.now();
          _extraInbox.clear();
          _inboxHasMore = home.inboxHasMore;
          _loadingMoreInbox = false;
        });
      }
    });
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);

    final inboxAsync = ref.watch(chatInboxProvider);
    if (inboxAsync.hasValue && !_viewTracked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _viewTracked) return;
        _viewTracked = true;
        final items = inboxAsync.valueOrNull ?? const <ChatInboxItem>[];
        AnalyticsService.instance.track(
          ProductEvents.chatInboxViewed,
          props: {'count': items.length},
        );
        if (!_ttvTracked) {
          _ttvTracked = true;
          AnalyticsService.instance.track(
            ProductEvents.chatInboxTtv,
            props: {
              'ms': DateTime.now().difference(_openedAt).inMilliseconds,
              'count': items.length,
            },
          );
        }
      });
    }

    return fxScreenA11yScope(
      label: 'Mensagens',
      child: FxShellScaffold(
        useMesh: true,
        appBar: _buildAppBar(
          ink: ink,
          mute: mute,
          freshnessLabel: freshnessLabel,
        ),
        body: _isSearching
            ? _buildSearchBody(isDark, ink, mute)
            : FxContentWidthLimiter(child: _buildHubBody(isDark, primary)),
      ),
    );
  }

  Widget _buildHubBody(bool isDark, Color primary) {
    return IndexedStack(
      index: _view.index,
      children: [
        _InboxTabPane(
          async: ref.watch(chatInboxProvider).whenData(
            (items) => [...items, ..._extraInbox],
          ),
          isDark: isDark,
          primary: primary,
          view: ChatInboxHubView.todas,
          selectionActive: _selectionActive,
          selectedAlunoIds: _selectedAlunoIds,
          showLoadMore: _inboxHasMore,
          loadingMore: _loadingMoreInbox,
          onLoadMore: _loadMoreInbox,
          onRetry: () => invalidateChatInboxCaches(ref),
          onRefresh: _refreshInbox,
          onNovaConversa: _showAlunoPicker,
          onConversationAction: _conversationAction,
          onOpenThread: _openThread,
          onToggleSelection: _toggleSelection,
        ),
        _InboxTabPane(
          async: ref.watch(chatInboxUnreadProvider),
          isDark: isDark,
          primary: primary,
          view: ChatInboxHubView.naoLidas,
          selectionActive: _selectionActive,
          selectedAlunoIds: _selectedAlunoIds,
          onRetry: () => invalidateChatInboxCaches(ref),
          onRefresh: _refreshInbox,
          onNovaConversa: _showAlunoPicker,
          onConversationAction: _conversationAction,
          onOpenThread: _openThread,
          onToggleSelection: _toggleSelection,
        ),
        _InboxTabPane(
          async: ref.watch(chatInboxArchivedProvider),
          isDark: isDark,
          primary: primary,
          view: ChatInboxHubView.arquivadas,
          selectionActive: _selectionActive,
          selectedAlunoIds: _selectedAlunoIds,
          onRetry: () => invalidateChatInboxCaches(ref),
          onRefresh: _refreshInbox,
          onNovaConversa: _showAlunoPicker,
          onConversationAction: _conversationAction,
          onOpenThread: _openThread,
          onToggleSelection: _toggleSelection,
        ),
      ],
    );
  }

  Widget _buildSearchBody(bool isDark, Color ink, Color mute) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            FxSettingsLayout.pageInset,
            8,
            FxSettingsLayout.pageInset,
            8,
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: TextStyle(color: ink, fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Buscar em todas as conversas…',
              hintStyle: TextStyle(color: mute),
              prefixIcon: Icon(Icons.search_rounded, color: mute),
              filled: true,
              fillColor: ShellChrome.of(context).cardFill,
              border: FxInputDeco.outlineBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ShellChrome.of(context).line),
              ),
            ),
            onChanged: _performSearch,
          ),
        ),
        Expanded(
          child:
              _searchResults != null
                  ? _buildSearchResults(isDark, ink, mute)
                  : const FxEmptyState(
                    icon: 'search',
                    title: 'Buscar conversas',
                    subtitle: 'Digite um termo para procurar nas mensagens.',
                  ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(bool isDark, Color ink, Color mute) {
    if (_searchResults!.isEmpty) {
      return const FxEmptyState(
        icon: 'search',
        title: 'Nenhum resultado encontrado',
        subtitle: 'Tente outro termo ou revise a grafia.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s2,
        FxSettingsLayout.pageInset,
        TokensStrip.s6,
      ),
      itemCount: _searchResults!.length,
      itemBuilder: (context, i) => _SearchResultTile(
        msg: _searchResults![i],
        isDark: isDark,
        ink: ink,
        mute: mute,
      ),
    );
  }

  void _openThread(int alunoId, {Object? extra}) {
    AnalyticsService.instance.track(
      ProductEvents.chatThreadOpened,
      props: {'feature': 'chat', 'aluno_id': alunoId},
    );
    context.push('/alunos/$alunoId/chat', extra: extra);
  }

  void _showAlunoPicker() {
    HapticFeedback.selectionClick();
    showFxHomeSheet<void>(
      context,
      builder:
          (ctx) => _AlunoPickerSheet(
            onSelect: (aluno) {
              Navigator.pop(ctx);
              _openThread(aluno.id, extra: aluno.nome);
            },
          ),
    );
  }

  Future<void> _refreshInbox() async {
    AnalyticsService.instance.track(ProductEvents.chatInboxRefreshed);
    invalidateChatInboxCaches(ref);
  }

  Future<void> _loadMoreInbox() async {
    if (_loadingMoreInbox || !_inboxHasMore) return;
    final home = ref.read(chatInboxHomeProvider).valueOrNull;
    if (home == null || home.inboxSize <= 0) return;
    setState(() => _loadingMoreInbox = true);
    try {
      final loaded = home.inbox.length + _extraInbox.length;
      final nextPage = loaded ~/ home.inboxSize;
      final page = await ChatRepository(
        ref.read(apiClientProvider),
      ).inboxPage(page: nextPage, size: home.inboxSize);
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
}

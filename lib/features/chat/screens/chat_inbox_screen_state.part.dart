part of 'chat_inbox_screen.dart';

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen> {
  ChatInboxHubView _view = ChatInboxHubView.todas;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<ChatMsg> _searchResults = const [];
  var _query = '';
  var _searchHasMore = false;
  var _searchPage = 0;
  var _searchLoading = false;
  final Set<int> _selectedAlunoIds = <int>{};
  DateTime? _fetchedAt;
  final DateTime _openedAt = DateTime.now();
  bool _viewTracked = false;
  bool _ttvTracked = false;
  final _extraInbox = <ChatInboxItem>[];
  final _extraUnread = <ChatInboxItem>[];
  final _extraArchived = <ChatInboxItem>[];
  var _inboxHasMore = false;
  var _unreadHasMore = false;
  var _archivedHasMore = false;
  var _loadingMoreInbox = false;
  var _loadingMoreUnread = false;
  var _loadingMoreArchived = false;

  bool get _isSearching => _query.isNotEmpty;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    if (ref.exists(chatInboxQueryProvider) &&
        ref.read(chatInboxQueryProvider).isNotEmpty) {
      ref.read(chatInboxQueryProvider.notifier).state = '';
    }
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final next = value.trim();
      if (next == _query) return;
      setState(() {
        _query = next;
        _searchResults = const [];
        _searchHasMore = false;
        _searchPage = 0;
        _selectedAlunoIds.clear();
      });
      ref.read(chatInboxQueryProvider.notifier).state = next;
      if (next.isEmpty) return;
      _performSearch(reset: true);
    });
  }

  Future<void> _performSearch({required bool reset}) async {
    if (_query.isEmpty) return;
    if (_searchLoading) return;
    setState(() => _searchLoading = true);
    try {
      final page = await ChatRepository(
        ref.read(apiClientProvider),
      ).globalSearchPage(_query, page: reset ? 0 : _searchPage + 1);
      if (!mounted) return;
      setState(() {
        _searchResults = reset ? page.content : [..._searchResults, ...page.content];
        _searchHasMore = page.hasNext;
        _searchPage = page.page ?? (reset ? 0 : _searchPage + 1);
        _searchLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _searchLoading = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
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
    required int hubCount,
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
    return FxShellAppBar(
      title: 'Mensagens',
      subtitle: chatInboxHubSubtitle(
        view: _view,
        count: hubCount,
        freshness: freshnessLabel,
      ),
      onBack: () {
        FxKeyboardDismissScope.dismiss();
        safePopOrGo(context, '/dashboard/personal');
      },
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
          _extraUnread.clear();
          _extraArchived.clear();
          _inboxHasMore = home.inboxHasMore;
          _unreadHasMore = home.unreadHasMore;
          _archivedHasMore = home.archivedHasMore;
          _loadingMoreInbox = false;
          _loadingMoreUnread = false;
          _loadingMoreArchived = false;
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

    final home = ref.watch(chatInboxHomeProvider).valueOrNull;
    final hubCount = switch (_view) {
      ChatInboxHubView.todas =>
        home?.inboxTotal ??
            ((ref.watch(chatInboxProvider).valueOrNull?.length ?? 0) +
                _extraInbox.length),
      ChatInboxHubView.naoLidas =>
        home?.unreadTotal ??
            ((ref.watch(chatInboxUnreadProvider).valueOrNull?.length ?? 0) +
                _extraUnread.length),
      ChatInboxHubView.arquivadas =>
        home?.archivedTotal ??
            ((ref.watch(chatInboxArchivedProvider).valueOrNull?.length ?? 0) +
                _extraArchived.length),
    };
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return fxScreenA11yScope(
      label: 'Mensagens',
      child: PopScope(
        canPop: !keyboardOpen && !_selectionActive && !_searchFocus.hasFocus,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (keyboardOpen || _searchFocus.hasFocus) {
            FxKeyboardDismissScope.dismiss();
            return;
          }
          if (_selectionActive) {
            _clearSelection();
            return;
          }
          safePopOrGo(context, '/dashboard/personal');
        },
        child: FxShellScaffold(
        useMesh: true,
        appBar: _buildAppBar(
          ink: ink,
          mute: mute,
          freshnessLabel: freshnessLabel,
          hubCount: hubCount,
        ),
        body: Column(
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
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onChanged: _onQueryChanged,
                onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                style: TextStyle(color: ink, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Buscar conversas',
                  hintStyle: TextStyle(color: mute),
                  prefixIcon: Icon(Icons.search_rounded, color: mute),
                  filled: true,
                  fillColor: chrome.cardFill,
                  border: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: chrome.line),
                  ),
                ),
              ),
            ),
            if (!_isSearching)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  0,
                  FxSettingsLayout.pageInset,
                  8,
                ),
                child: Wrap(
                  spacing: TokensStrip.s2,
                  runSpacing: TokensStrip.s2,
                  children: [
                    for (final view in ChatInboxHubView.values)
                      FxToggleChip(
                        label: chatInboxHubViewLabel(view),
                        selected: _view == view,
                        isDark: isDark,
                        onTap: () {
                          if (_view == view) return;
                          setState(() => _view = view);
                        },
                      ),
                  ],
                ),
              ),
            Expanded(
              child:
                  _isSearching
                      ? _buildSearchBody(isDark, ink, mute)
                      : FxContentWidthLimiter(
                        child: _buildHubBody(isDark, primary),
                      ),
            ),
            if (!_isSearching && !_selectionActive)
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    TokensStrip.s2,
                    FxSettingsLayout.pageInset,
                    TokensStrip.s3 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: FxLiquidPrimaryButton(
                    label: 'Nova mensagem',
                    onPressed: _showAlunoPicker,
                  ),
                ),
              ),
          ],
        ),
      ),
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
          async: ref.watch(chatInboxUnreadProvider).whenData(
            (items) => [...items, ..._extraUnread],
          ),
          isDark: isDark,
          primary: primary,
          view: ChatInboxHubView.naoLidas,
          selectionActive: _selectionActive,
          selectedAlunoIds: _selectedAlunoIds,
          showLoadMore: _unreadHasMore,
          loadingMore: _loadingMoreUnread,
          onLoadMore: _loadMoreUnread,
          onRetry: () => invalidateChatInboxCaches(ref),
          onRefresh: _refreshInbox,
          onNovaConversa: _showAlunoPicker,
          onConversationAction: _conversationAction,
          onOpenThread: _openThread,
          onToggleSelection: _toggleSelection,
        ),
        _InboxTabPane(
          async: ref.watch(chatInboxArchivedProvider).whenData(
            (items) => [...items, ..._extraArchived],
          ),
          isDark: isDark,
          primary: primary,
          view: ChatInboxHubView.arquivadas,
          selectionActive: _selectionActive,
          selectedAlunoIds: _selectedAlunoIds,
          showLoadMore: _archivedHasMore,
          loadingMore: _loadingMoreArchived,
          onLoadMore: _loadMoreArchived,
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
    final home = ref.watch(chatInboxHomeProvider);
    final conversations = home.valueOrNull?.inbox ?? const <ChatInboxItem>[];
    final waiting =
        (_searchLoading && _searchResults.isEmpty) ||
        (home.isLoading && conversations.isEmpty && _searchResults.isEmpty);
    if (waiting) {
      return const Padding(
        padding: EdgeInsets.all(FxSettingsLayout.pageInset),
        child: SkeletonList(count: 5),
      );
    }
    if (conversations.isEmpty && _searchResults.isEmpty) {
      return const FxEmptyState(
        icon: 'search',
        title: 'Nenhum resultado encontrado',
        subtitle: 'Tente o nome do aluno ou um trecho da mensagem.',
      );
    }
    final extra = _searchHasMore ? 1 : 0;
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s2,
        FxSettingsLayout.pageInset,
        TokensStrip.s6,
      ),
      itemCount: conversations.length + _searchResults.length + extra,
      itemBuilder: (context, i) {
        if (i < conversations.length) {
          final item = conversations[i];
          return _InboxTile(
            item: item,
            isDark: isDark,
            onTap: () => _openThread(item.alunoId, extra: item.alunoNome),
          );
        }
        final msgIndex = i - conversations.length;
        if (msgIndex >= _searchResults.length) {
          return FxSatelliteListTile(
            title: _searchLoading ? 'Carregando…' : 'Carregar mais',
            onTap: _searchLoading
                ? null
                : () => _performSearch(reset: false),
          );
        }
        return _SearchResultTile(
          msg: _searchResults[msgIndex],
          alunoNome: _alunoNomeFor(_searchResults[msgIndex].alunoId),
          isDark: isDark,
          ink: ink,
          mute: mute,
        );
      },
    );
  }

  String? _alunoNomeFor(int? alunoId) {
    if (alunoId == null) return null;
    final home = ref.read(chatInboxHomeProvider).valueOrNull;
    for (final item in [
      ...?home?.inbox,
      ..._extraInbox,
      ...?home?.unread,
      ..._extraUnread,
      ...?home?.archived,
      ..._extraArchived,
    ]) {
      if (item.alunoId == alunoId) return item.alunoNome;
    }
    return null;
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
}

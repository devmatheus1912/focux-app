part of 'chat_inbox_screen.dart';

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
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
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
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
      title: ids.length == 1 ? 'Excluir mensagens?' : 'Excluir conversas?',
      message:
          ids.length == 1
              ? 'As mensagens desta conversa serao limpas da sua caixa.'
              : 'As mensagens das ${ids.length} conversas selecionadas serao limpas da sua caixa.',
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
        ids.length == 1 ? 'Mensagens excluidas' : 'Conversas excluidas',
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
        final labels = {
          'pin': 'Fixada',
          'unpin': 'Desafixada',
          'archive': 'Arquivada',
          'unarchive': 'Desarquivada',
          'mute': 'Silenciada',
          'unmute': 'Notificações ativadas',
          'clear': 'Conversa limpa',
        };
        FeedbackHelper.showInfo(context, labels[action] ?? 'Ação aplicada');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
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
    final showFreshness =
        !_isSearching && !_selectionActive && freshnessLabel != null;

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
        floatingActionButton:
            _isSearching || _selectionActive
                ? null
                : FloatingActionButton(
                  tooltip: 'Nova mensagem',
                  onPressed: _showAlunoPicker,
                  child: const Icon(Icons.edit_outlined),
                ),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(
            _isSearching || _selectionActive ? 56 : (showFreshness ? 112 : 104),
          ),
          child:
              _selectionActive || _isSearching
                  ? AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    foregroundColor: ink,
                    automaticallyImplyLeading: !_selectionActive,
                    leading:
                        _selectionActive
                            ? IconButton(
                              icon: Icon(Icons.close_rounded, color: ink),
                              onPressed: _clearSelection,
                            )
                            : IconButton(
                              onPressed:
                                  () => safePopOrGo(
                                    context,
                                    '/dashboard/personal',
                                  ),
                              icon: Container(
                                width: 38,
                                height: 38,
                                decoration: chrome.headerAction(radius: 12),
                                child: Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 16,
                                  color: ink,
                                ),
                              ),
                            ),
                    title:
                        _selectionActive
                            ? Text(
                              _selectedAlunoIds.isEmpty
                                  ? 'Selecione mensagens'
                                  : '${_selectedAlunoIds.length} selecionada(s)',
                              style: TextStyle(
                                color: ink,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                            : TextField(
                              controller: _searchCtrl,
                              autofocus: true,
                              style: TextStyle(color: ink, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'Buscar em todas as conversas...',
                                hintStyle: TextStyle(color: mute),
                                border: InputBorder.none,
                              ),
                              onChanged: _performSearch,
                            ),
                    actions: [
                      if (_selectionActive)
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
                        )
                      else
                        IconButton(
                          icon: Icon(Icons.close, color: ink),
                          onPressed: _toggleSearch,
                        ),
                    ],
                  )
                  : Column(
                    children: [
                      FxShellAppBar(
                        title: 'Mensagens',
                        subtitle: freshnessLabel,
                        onBack:
                            () => safePopOrGo(context, '/dashboard/personal'),
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
                          SizedBox(width: FxHelpChrome.gap),
                          IconButton(
                            icon: Icon(Icons.search_rounded, color: ink),
                            onPressed: _toggleSearch,
                          ),
                        ],
                      ),
                      TabBar(
                        controller: _tabCtrl,
                        labelColor: primary,
                        unselectedLabelColor: mute,
                        indicatorColor: primary,
                        indicatorSize: TabBarIndicatorSize.label,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Todas'),
                          Tab(text: 'Não lidas'),
                          Tab(text: 'Arquivadas'),
                        ],
                      ),
                    ],
                  ),
        ),
        body:
            _isSearching && _searchResults != null
                ? _buildSearchResults(isDark, ink, mute)
                : _isSearching
                ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search, size: 48, color: mute),
                      const SizedBox(height: 12),
                      Text(
                        'Digite para buscar...',
                        style: TextStyle(color: mute),
                      ),
                    ],
                  ),
                )
                : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildInboxTab(
                      ref.watch(chatInboxProvider).whenData(
                        (items) => [...items, ..._extraInbox],
                      ),
                      isDark,
                      primary,
                      showLoadMore: _inboxHasMore,
                      loadingMore: _loadingMoreInbox,
                      onLoadMore: _loadMoreInbox,
                    ),
                    _buildInboxTab(
                      ref.watch(chatInboxUnreadProvider),
                      isDark,
                      primary,
                      emptyMsg: 'Nenhuma mensagem não lida',
                    ),
                    _buildInboxTab(
                      ref.watch(chatInboxArchivedProvider),
                      isDark,
                      primary,
                      emptyMsg: 'Nenhuma conversa arquivada',
                      isArchived: true,
                    ),
                  ],
                ),
      ),
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
    return FxSettingsGroupedList(
      itemCount: _searchResults!.length,
      itemBuilder: (context, i) => _SearchResultTile(
        msg: _searchResults![i],
        isDark: isDark,
        ink: ink,
        mute: mute,
        showDivider: i < _searchResults!.length - 1,
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

  Widget _buildInboxTab(
    AsyncValue<List<ChatInboxItem>> async,
    bool isDark,
    Color primary, {
    String emptyMsg = 'Nenhuma conversa ainda',
    bool isArchived = false,
    bool showLoadMore = false,
    bool loadingMore = false,
    VoidCallback? onLoadMore,
  }) {
    return async.when(
      loading:
          () => const Padding(
            padding: EdgeInsets.all(TokensStrip.s4),
            child: SkeletonList(count: 6),
          ),
      error:
          (e, _) => FxErrorState(
            chromeOnDark: isDark,
            primary: primary,
            message: friendlyError(e),
            onRetry: () => invalidateChatInboxCaches(ref),
          ),
      data: (items) {
        if (items.isEmpty) {
          return FxEmptyState(
            icon: isArchived ? 'article' : 'chat',
            title: emptyMsg,
            subtitle:
                isArchived
                    ? 'Arraste conversas para a esquerda para arquivar.'
                    : 'Escolha um aluno para começar uma conversa.',
            action:
                isArchived
                    ? null
                    : FxEmptyAction(
                      label: 'Nova conversa',
                      onTap: _showAlunoPicker,
                    ),
          );
        }
        return RefreshIndicator(
          color: primary,
          onRefresh: () async {
            AnalyticsService.instance.track(ProductEvents.chatInboxRefreshed);
            invalidateChatInboxCaches(ref);
          },
          child: FxSettingsGroupedList(
            itemCount: items.length + (showLoadMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (showLoadMore && i >= items.length) {
                return FxSettingsTile(
                  fxIcon: 'chat',
                  label: loadingMore ? 'Carregando…' : 'Carregar mais',
                  value: '',
                  showDivider: false,
                  onTap: loadingMore || onLoadMore == null
                      ? () {}
                      : onLoadMore,
                );
              }
              return Dismissible(
              key: Key('inbox-${items[i].alunoId}'),
              direction: _selectionActive
                  ? DismissDirection.none
                  : DismissDirection.horizontal,
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.endToStart) {
                  await _conversationAction(
                    items[i].alunoId,
                    isArchived ? 'unarchive' : 'archive',
                  );
                  return false;
                }
                await _conversationAction(items[i].alunoId, 'pin');
                return false;
              },
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 24),
                color: primary.withValues(alpha: 0.12),
                child: Icon(Icons.push_pin, color: primary),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                color: EagleTokens.warn.withValues(alpha: 0.12),
                child: Icon(
                  isArchived ? Icons.unarchive : Icons.archive,
                  color: EagleTokens.warn,
                ),
              ),
              child: _InboxTile(
                item: items[i],
                isDark: isDark,
                selected: _selectedAlunoIds.contains(items[i].alunoId),
                selecting: _selectionActive,
                showDivider: i < items.length - 1 || showLoadMore,
                onTap: () {
                  if (_selectionActive) {
                    _toggleSelection(items[i].alunoId);
                    return;
                  }
                  _openThread(
                    items[i].alunoId,
                    extra: items[i].alunoNome,
                  );
                },
                onLongPress: () => _toggleSelection(items[i].alunoId),
              ),
            );
            },
          ),
        );
      },
    );
  }
}

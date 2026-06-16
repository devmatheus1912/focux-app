part of 'chat_inbox_screen.dart';


class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;
  List<ChatMsg>? _searchResults;
  final Set<int> _selectedAlunoIds = <int>{};

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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final ink = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
        return AlertDialog(
          title: Text(
            ids.length == 1 ? 'Excluir mensagens?' : 'Excluir conversas?',
            style: TextStyle(color: ink),
          ),
          content: Text(
            ids.length == 1
                ? 'As mensagens desta conversa serao limpas da sua caixa.'
                : 'As mensagens das ${ids.length} conversas selecionadas serao limpas da sua caixa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: EagleTokens.bad),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    HapticFeedback.mediumImpact();
    try {
      final repo = ChatRepository(ref.read(apiClientProvider));
      for (final alunoId in ids) {
        await repo.conversationAction(alunoId, 'clear');
      }
      _clearSelection();
      ref.invalidate(chatInboxProvider);
      ref.invalidate(chatInboxUnreadProvider);
      ref.invalidate(chatInboxArchivedProvider);
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
      ref.invalidate(chatInboxProvider);
      ref.invalidate(chatInboxUnreadProvider);
      ref.invalidate(chatInboxArchivedProvider);
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
            _isSearching || _selectionActive ? 56 : 104,
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
                        onBack:
                            () => safePopOrGo(context, '/dashboard/personal'),
                        actions: [
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
                ? _buildSearchResults(isDark, primary, ink, mute)
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
                      ref.watch(chatInboxProvider),
                      chatInboxProvider,
                      isDark,
                      primary,
                      ink,
                      mute,
                    ),
                    _buildInboxTab(
                      ref.watch(chatInboxUnreadProvider),
                      chatInboxUnreadProvider,
                      isDark,
                      primary,
                      ink,
                      mute,
                      emptyMsg: 'Nenhuma mensagem não lida',
                    ),
                    _buildInboxTab(
                      ref.watch(chatInboxArchivedProvider),
                      chatInboxArchivedProvider,
                      isDark,
                      primary,
                      ink,
                      mute,
                      emptyMsg: 'Nenhuma conversa arquivada',
                      isArchived: true,
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildSearchResults(
    bool isDark,
    Color primary,
    Color ink,
    Color mute,
  ) {
    if (_searchResults!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 48, color: mute),
            const SizedBox(height: 12),
            Text('Nenhum resultado encontrado', style: TextStyle(color: mute)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 8, 16, 110),
      itemCount: _searchResults!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final msg = _searchResults![index];
        return _SearchResultTile(
          msg: msg,
          isDark: isDark,
          ink: ink,
          mute: mute,
        );
      },
    );
  }

  void _showAlunoPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(ctx).padding.bottom,
            ),
            child: ShellSurface(
              radius: 28,
              child: _AlunoPickerSheet(
                onSelect: (aluno) {
                  Navigator.pop(ctx);
                  context.push('/alunos/${aluno.id}/chat', extra: aluno.nome);
                },
              ),
            ),
          ),
    );
  }

  Widget _buildInboxTab(
    AsyncValue<List<ChatInboxItem>> async,
    FutureProvider<List<ChatInboxItem>> provider,
    bool isDark,
    Color primary,
    Color ink,
    Color mute, {
    String emptyMsg = 'Nenhuma conversa ainda',
    bool isArchived = false,
  }) {
    return async.when(
      loading: () => Center(child: FxLoading(color: primary)),
      error:
          (e, _) => _InboxState(
            icon: Icons.wifi_off_rounded,
            title: 'Não foi possível carregar',
            message: friendlyError(e),
            color: mute,
            onTap: () => ref.invalidate(provider),
          ),
      data: (items) {
        if (items.isEmpty) {
          return _InboxState(
            icon:
                isArchived ? Icons.archive_outlined : Icons.chat_bubble_outline,
            title: emptyMsg,
            message:
                isArchived
                    ? 'Arraste conversas para a esquerda para arquivar.'
                    : 'Toque no botao de escrever para escolher um aluno.',
            color: mute,
          );
        }
        return RefreshIndicator(
          color: primary,
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s4, 8, 16, 110),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = _selectedAlunoIds.contains(item.alunoId);
              return FxStaggerItem(
                index: index,
                child: Dismissible(
                  key: Key('inbox-${item.alunoId}'),
                  direction:
                      _selectionActive
                          ? DismissDirection.none
                          : DismissDirection.horizontal,
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.endToStart) {
                      // Swipe left → archive/unarchive
                      await _conversationAction(
                        item.alunoId,
                        isArchived ? 'unarchive' : 'archive',
                      );
                      return false;
                    } else {
                      // Swipe right → pin/unpin
                      await _conversationAction(item.alunoId, 'pin');
                      return false;
                    }
                  },
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.push_pin, color: primary),
                  ),
                  secondaryBackground: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: EagleTokens.warn.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isArchived ? Icons.unarchive : Icons.archive,
                      color: EagleTokens.warn,
                    ),
                  ),
                  child: _InboxTile(
                    item: item,
                    isDark: isDark,
                    selected: selected,
                    selecting: _selectionActive,
                    onTap: () {
                      if (_selectionActive) {
                        _toggleSelection(item.alunoId);
                        return;
                      }
                      context.push(
                        '/alunos/${item.alunoId}/chat',
                        extra: item.alunoNome,
                      );
                    },
                    onLongPress: () => _toggleSelection(item.alunoId),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

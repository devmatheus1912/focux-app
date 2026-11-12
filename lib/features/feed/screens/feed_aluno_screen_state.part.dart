part of 'feed_aluno_screen.dart';

class _FeedAlunoScreenState extends ConsumerState<FeedAlunoScreen> {
  final Map<int, int> _curtidasLocais = {};
  final Map<int, bool> _curtidosLocais = {};
  final Map<int, int> _comentariosLocais = {};
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _searchDebounce;
  List<FeedPost> _posts = [];
  var _query = '';
  var _chip = FeedListChip.todos;
  var _hasMore = false;
  var _loadingMore = false;
  String? _nextCursor;
  var _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final trimmed = value.trim();
      if (trimmed != _query) {
        setState(() => _query = trimmed);
      }
      _load();
    });
  }

  Future<void> _denunciarPost(FeedPost p) async {
    final enviada = await showDenunciarSheet(
      context,
      repo: ModeracaoRepository(ref.read(apiClientProvider)),
      tipo: DenunciaTipo.feedPost,
      alvoId: '${p.id}',
      conteudo: '${p.titulo}\n${p.conteudo}',
    );
    if (enviada && mounted) {
      setState(() => _posts = _posts.where((x) => x.id != p.id).toList());
    }
  }

  Future<void> _bloquearAutor() async {
    final l10n = S.of(context);
    final ok = await showFxConfirmSheet(
      context,
      title: l10n.chatBloquearConfirmaTitulo,
      message: l10n.chatBloquearConfirmaAluno,
      confirmLabel: l10n.feedBloquearAutor,
      destructive: true,
      icon: FxIcons.bloquear,
    );
    if (!ok || !mounted) return;
    try {
      await ChatRepository(
        ref.read(apiClientProvider),
      ).definirBloqueio(bloquear: true);
      if (!mounted) return;
      setState(() => _posts = []);
      FeedbackHelper.showSuccess(context, l10n.feedAutorBloqueado);
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  void _clearQuery() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() => _query = '');
    _load();
  }

  void _clearFilters() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {
      _query = '';
      _chip = FeedListChip.todos;
    });
    _load();
  }

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/dashboard/aluno');
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final pagina = await FeedRepository(
        ref.read(apiClientProvider),
      ).listarAlunoPagina(
        q: _query,
        tipo: feedListChipTipo(_chip),
        fixado: feedListChipFixado(_chip),
      );
      if (!mounted) return;
      setState(() {
        _posts = feedComDestaque(pagina.content, widget.postId);
        _hasMore = pagina.hasNext;
        _nextCursor = pagina.nextCursor;
        for (final p in pagina.content) {
          _curtidasLocais[p.id] = p.totalCurtidas;
          _comentariosLocais[p.id] = p.totalComentarios;
        }
        _loading = false;
        _fetchedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _erro = friendlyError(e);
      });
    }
  }

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final pagina = await FeedRepository(
        ref.read(apiClientProvider),
      ).listarAlunoPagina(
        cursor: _nextCursor,
        q: _query,
        tipo: feedListChipTipo(_chip),
        fixado: feedListChipFixado(_chip),
      );
      if (!mounted) return;
      setState(() {
        final seen = _posts.map((p) => p.id).toSet();
        for (final p in pagina.content) {
          if (seen.add(p.id)) {
            _posts.add(p);
            _curtidasLocais[p.id] = p.totalCurtidas;
            _comentariosLocais[p.id] = p.totalComentarios;
          }
        }
        _hasMore = pagina.hasNext;
        _nextCursor = pagina.nextCursor;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  /// Coração e número mudam na hora; o servidor confirma o total depois.
  Future<void> _curtir(int postId) async {
    final post = _posts.where((p) => p.id == postId).firstOrNull;
    final antes = _curtidosLocais[postId] ?? post?.curtidoPorMim ?? false;
    final totalAntes = _curtidasLocais[postId] ?? post?.totalCurtidas ?? 0;
    HapticFeedback.lightImpact();
    setState(() {
      _curtidosLocais[postId] = !antes;
      _curtidasLocais[postId] = (totalAntes + (antes ? -1 : 1)).clamp(
        0,
        1 << 30,
      );
    });
    try {
      final novoTotal = await FeedRepository(
        ref.read(apiClientProvider),
      ).toggleCurtida(postId);
      if (mounted) {
        setState(() => _curtidasLocais[postId] = novoTotal);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _curtidosLocais[postId] = antes;
          _curtidasLocais[postId] = totalAntes;
        });
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _abrirComentarios(int postId) {
    final aluno = ref.read(alunoMeProvider).value;
    showFxHomeSheet<void>(
      context,
      builder:
          (ctx) => FeedCommentsSheet(
            postId: postId,
            repo: FeedRepository(ref.read(apiClientProvider)),
            currentAlunoId: aluno?.id,
            currentAlunoFotoUrl: aluno?.fotoUrl,
            onComentou:
                (novoTotal) =>
                    setState(() => _comentariosLocais[postId] = novoTotal),
          ),
    );
  }

  bool get _filtrando =>
      _query.trim().isNotEmpty || _chip != FeedListChip.todos;

  /// O post do aviso vem primeiro, antes do bloco Fixado.
  bool get _comDestaque =>
      widget.postId != null &&
      _posts.isNotEmpty &&
      _posts.first.id == widget.postId;

  Future<void> _maisOpcoes(FeedPost p) async {
    final l10n = S.of(context);
    final acao = await showFxGroupedActionSheet<String>(
      context,
      titulo: 'Publicação',
      grupos: [
        FxActionGroup<String>(null, [
          FxActionItem(
            valor: 'denunciar',
            rotulo: l10n.moderacaoDenunciarPost,
            icone: FxIcons.meta,
          ),
          FxActionItem(
            valor: 'bloquear',
            rotulo: l10n.feedBloquearAutor,
            icone: FxIcons.bloquear,
            perigo: true,
          ),
        ]),
      ],
    );
    if (!mounted) return;
    switch (acao) {
      case 'denunciar':
        await _denunciarPost(p);
      case 'bloquear':
        await _bloquearAutor();
    }
  }

  Widget _buildBody(Color primary) {
    final searching = _filtrando;
    if (_posts.isEmpty) {
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.zero,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: FxEmptyState(
                      icon: searching ? FxIcons.buscar : FxIcons.feed,
                      title:
                          searching
                              ? 'Nada encontrado'
                              : 'Nenhuma publicação ainda',
                      subtitle:
                          searching
                              ? 'Ajuste a busca ou o filtro para achar outra publicação.'
                              : 'Quando seu personal publicar um aviso, uma dica ou uma foto, aparece aqui.',
                      action:
                          searching
                              ? FxEmptyAction(
                                label: 'Limpar filtros',
                                secondary: true,
                                onTap: _clearFilters,
                              )
                              : FxEmptyAction(
                                label: 'Voltar ao início',
                                onTap: _leave,
                              ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }
    return FeedLista(
      posts: _posts,
      filtrando: searching || _comDestaque,
      onRefresh: _load,
      hasMore: _hasMore,
      loadingMore: _loadingMore,
      onCarregarMais: _carregarMais,
      cartao:
          (p, i) => FeedPostCard(
            post: p,
            index: i,
            primary: primary,
            curtidas: _curtidasLocais[p.id] ?? p.totalCurtidas,
            comentarios: _comentariosLocais[p.id] ?? p.totalComentarios,
            onCurtir: () => _curtir(p.id),
            curtido: _curtidosLocais[p.id] ?? p.curtidoPorMim,
            onComentar: () => _abrirComentarios(p.id),
            onMais: () => _maisOpcoes(p),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Feed',
      child: FxKeyboardDismissScope(
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (keyboardOpen || _searchFocus.hasFocus) {
              FxKeyboardDismissScope.dismiss();
              return;
            }
            _leave();
          },
          child: FxShellScaffold(
            useMesh: false,
            constrainWidth: false,
            appBar: FxShellAppBar(
              title: 'Feed',
              subtitle: FxHubFreshness.joinCount(
                '${feedCountLabel(_posts.length)}${_hasMore && !_loading ? '+' : ''}',
                _loading ? null : freshnessLabel,
              ),
              onBack: _leave,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como usar o feed',
                  onTap:
                      () => showFxHelpSheet(
                        context,
                        title: 'Feed',
                        subtitle:
                            'Novidades que seu personal publica para você.',
                        tips: const [
                          FxHelpTip(
                            'Curtir e comentar',
                            'Toque no coração para curtir e no balão para comentar.',
                          ),
                          FxHelpTip('Vídeo', 'O vídeo toca no próprio post.'),
                          FxHelpTip(
                            'Fixado',
                            'O que seu personal fixou fica no topo.',
                          ),
                        ],
                      ),
                ),
              ],
            ),
            body:
                _loading
                    ? const Padding(
                      padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                      child: SkeletonList(count: 4),
                    )
                    : _erro != null
                    ? FxErrorState(
                      chromeOnDark: isDark,
                      primary: primary,
                      title: FocuxMicrocopy.naoFoiPossivelCarregar,
                      message: _erro!,
                      onRetry: _load,
                    )
                    : Column(
                      children: [
                        if (feedMostraFiltros(
                          total: _posts.length,
                          query: _query,
                          filtrando: _chip != FeedListChip.todos,
                        )) ...[
                          FeedFiltros(
                            controller: _searchController,
                            focusNode: _searchFocus,
                            query: _query,
                            chip: _chip,
                            onQuery: _onQueryChanged,
                            onLimparBusca: _clearQuery,
                            onChip: (c) {
                              setState(() => _chip = c);
                              _load();
                            },
                          ),
                        ],
                        Expanded(
                          child: FxContentWidthLimiter(
                            child: _buildBody(primary),
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

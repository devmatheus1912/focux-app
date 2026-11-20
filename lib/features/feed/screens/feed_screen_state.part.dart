part of 'feed_screen.dart';

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final Map<int, int> _curtidasLocais = {};
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
  bool _loading = true;
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

  void _leave() {
    FxKeyboardDismissScope.dismiss();
    safePopOrGo(context, '/dashboard/personal');
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (mounted) _load();
    });
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final pagina = await FeedRepository(
        ref.read(apiClientProvider),
      ).listarPersonalPagina(
        q: _query,
        tipo: feedListChipTipo(_chip),
        fixado: feedListChipFixado(_chip),
      );
      if (!mounted) return;
      setState(() {
        _posts = pagina.content;
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
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = friendlyError(e);
        });
      }
    }
  }

  Future<void> _carregarMais() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final pagina = await FeedRepository(
        ref.read(apiClientProvider),
      ).listarPersonalPagina(
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

  Future<void> _deletar(int id) async {
    try {
      await FeedRepository(ref.read(apiClientProvider)).deletar(id);
      await _load();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _toggleFixar(int id) async {
    try {
      await FeedRepository(ref.read(apiClientProvider)).toggleFixar(id);
      await _load();
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _abrirComentarios(int postId) {
    showFxHomeSheet<void>(
      context,
      builder:
          (ctx) => FeedCommentsSheet(
            postId: postId,
            repo: FeedRepository(ref.read(apiClientProvider)),
            canCompose: false,
            onComentou:
                (novoTotal) =>
                    setState(() => _comentariosLocais[postId] = novoTotal),
          ),
    );
  }

  void _abrirFormulario({FeedPost? post}) {
    showFxHomeSheet<bool>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final accent = Theme.of(ctx).colorScheme.primary;
        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight:
              MediaQuery.sizeOf(ctx).height * FxHomeSheetChrome.maxHeightFactor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  TokensStrip.s3,
                  FxSettingsLayout.pageInset,
                  0,
                ),
                child: FxHomeSheetHeader(
                  isDark: isDark,
                  title: post == null ? 'Nova publicação' : 'Editar publicação',
                  subtitle: 'Os alunos veem no feed deles.',
                  leading: Icon(FxIcons.artigo, color: accent, size: 18),
                ),
              ),
              Flexible(child: FeedComposerSheet(ref: ref, post: post)),
            ],
          ),
        );
      },
    ).then((created) async {
      if (created != true || !mounted) return;
      await _load();
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        post == null
            ? 'Publicação criada com sucesso!'
            : 'Publicação atualizada.',
      );
    });
  }

  bool get _filtrando =>
      _query.trim().isNotEmpty || _chip != FeedListChip.todos;

  Future<void> _maisOpcoes(FeedPost p) async {
    final acao = await showFxGroupedActionSheet<String>(
      context,
      titulo: 'Publicação',
      grupos: [
        FxActionGroup<String>(null, [
          const FxActionItem(
            valor: 'editar',
            rotulo: 'Editar',
            icone: FxIcons.editar,
          ),
          FxActionItem(
            valor: 'fixar',
            rotulo: p.fixado ? 'Desafixar' : 'Fixar no topo',
            descricao: p.fixado ? null : 'Fica no topo do feed dos alunos.',
            icone: FxIcons.fixado,
          ),
        ]),
      ],
      destrutiva: const FxActionItem(
        valor: 'excluir',
        rotulo: 'Excluir',
        icone: FxIcons.excluir,
      ),
      confirmarTitulo: 'Excluir publicação?',
      confirmarMensagem: 'Os alunos deixam de ver. Não dá para desfazer.',
    );
    if (!mounted) return;
    switch (acao) {
      case 'editar':
        _abrirFormulario(post: p);
      case 'fixar':
        await _toggleFixar(p.id);
      case 'excluir':
        await _deletar(p.id);
    }
  }

  Widget _buildBody(Color primary, List<FeedPost> visible) {
    if (visible.isEmpty) {
      final searching = _filtrando;
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
                              ? 'Ajuste a busca para achar outra publicação.'
                              : 'O feed é o mural dos seus alunos: avisos, dicas e fotos. Eles curtem e comentam.',
                      action:
                          searching
                              ? FxEmptyAction(
                                label: 'Limpar filtros',
                                secondary: true,
                                onTap: _clearFilters,
                              )
                              : FxEmptyAction(
                                label: 'Nova publicação',
                                onTap: _abrirFormulario,
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

    final repo = FeedRepository(ref.read(apiClientProvider));
    return FeedLista(
      posts: visible,
      filtrando: _filtrando,
      onRefresh: _load,
      hasMore: _hasMore,
      loadingMore: _loadingMore,
      onCarregarMais: _carregarMais,
      bottomPad: feedListBottomPad(stickyVisible: true),
      cartao:
          (p, i) => FeedPostCard(
            post: p,
            index: i,
            primary: primary,
            curtidas: _curtidasLocais[p.id] ?? p.totalCurtidas,
            comentarios: _comentariosLocais[p.id] ?? p.totalComentarios,
            onComentar: () => _abrirComentarios(p.id),
            onQuemCurtiu:
                () =>
                    showFeedQuemCurtiuSheet(context, postId: p.id, repo: repo),
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
    final visible = _posts;
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
            comFundo: false,
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
                            'Publicações que os alunos veem no app deles.',
                        tips: const [
                          FxHelpTip(
                            'Publicar',
                            'Nova publicação abre texto, foto ou vídeo. A primeira linha vira o título.',
                          ),
                          FxHelpTip(
                            'Retorno',
                            'Toque no número de curtidas para ver quem curtiu, e no balão para ler os comentários.',
                          ),
                          FxHelpTip(
                            'Fixar',
                            'No ⋯ do post. Fixado fica no topo do feed dos alunos.',
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
                            child: _buildBody(primary, visible),
                          ),
                        ),
                        if (!_loading &&
                            _erro == null &&
                            (_posts.isNotEmpty || _filtrando))
                          SafeArea(
                            top: false,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                FxSettingsLayout.pageInset,
                                TokensStrip.s2,
                                FxSettingsLayout.pageInset,
                                TokensStrip.s2 +
                                    MediaQuery.viewInsetsOf(context).bottom,
                              ),
                              child: FxLiquidPrimaryButton(
                                label: 'Nova publicação',
                                onPressed: _abrirFormulario,
                              ),
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

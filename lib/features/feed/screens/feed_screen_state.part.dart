part of 'feed_screen.dart';

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final Map<int, int> _curtidasLocais = {};
  final Map<int, int> _comentariosLocais = {};
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<FeedPost> _posts = [];
  var _query = '';
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
    super.dispose();
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final pagina = await FeedRepository(
        ref.read(apiClientProvider),
      ).listarPersonalPagina(q: _query);
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
      ).listarPersonalPagina(cursor: _nextCursor, q: _query);
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

  void _abrirFormulario() {
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
                  title: 'Nova publicação',
                  subtitle: 'Os alunos veem no feed deles.',
                  leading: FxIcon(name: 'article', color: accent, size: 18),
                ),
              ),
              FeedComposerSheet(ref: ref),
            ],
          ),
        );
      },
    ).then((created) async {
      if (created != true || !mounted) return;
      await _load();
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Publicação criada com sucesso!');
    });
  }

  Widget _buildBody(Color primary, List<FeedPost> visible) {
    if (visible.isEmpty) {
      final searching = _query.trim().isNotEmpty;
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: searching ? 'search' : 'rss',
              title:
                  searching
                      ? 'Nada encontrado'
                      : 'Nenhuma publicação ainda',
              subtitle:
                  searching
                      ? 'Ajuste a busca para achar outra publicação.'
                      : 'Compartilhe novidades, vídeos e conquistas com seus alunos.',
              action: FxEmptyAction(
                label: searching ? 'Limpar busca' : 'Criar publicação',
                onTap: searching ? _clearQuery : _abrirFormulario,
              ),
            ),
          ],
        ),
      );
    }

    final showMore = _hasMore;
    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        itemCount: visible.length + (showMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (showMore && i == visible.length) {
            return FxSatelliteListTile(
              title: _loadingMore ? 'Carregando…' : 'Carregar mais',
              onTap: _loadingMore ? null : _carregarMais,
            );
          }
          final p = visible[i];
          return _FeedPostCard(
            post: p,
            index: i,
            primary: primary,
            curtidas: _curtidasLocais[p.id] ?? p.totalCurtidas,
            comentarios: _comentariosLocais[p.id] ?? p.totalComentarios,
            onCurtir: null,
            onComentar: () => _abrirComentarios(p.id),
            onFixar: () => _toggleFixar(p.id),
            onExcluir: () => _confirmarExclusao(p.id),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final mute = chrome.mute;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final visible = _posts;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return fxScreenA11yScope(
      label: 'Feed',
      child: PopScope(
        canPop: !keyboardOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          FxKeyboardDismissScope.dismiss();
        },
        child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Feed',
          subtitle: FxHubFreshness.joinCount(
            feedCountLabel(_posts.length),
            freshnessLabel,
          ),
          onBack: () {
            FxKeyboardDismissScope.dismiss();
            safePopOrGo(context, '/dashboard/personal');
          },
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar o feed',
              onTap: () => showFxHelpSheet(
                context,
                title: 'Feed',
                subtitle: 'Publicações que os alunos veem no app deles.',
                tips: const [
                  FxHelpTip(
                    'Publicar',
                    'O criar no rodapé abre texto, imagem ou vídeo.',
                  ),
                  FxHelpTip(
                    'Comentários',
                    'Você lê o que os alunos escreveram. Curtir e comentar é no app deles.',
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        TokensStrip.s2,
                        TokensStrip.s4,
                        TokensStrip.s2,
                      ),
                      child: DecoratedBox(
                        decoration: fxStripCardDecoration(
                          context,
                          accent: primary,
                          radius: TokensStrip.rCard,
                          glowStrength: 0.03,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onQueryChanged,
                          onTapOutside:
                              (_) =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Buscar publicação',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: primary,
                              size: 20,
                            ),
                            suffixIcon:
                                _query.trim().isEmpty
                                    ? null
                                    : IconButton(
                                      tooltip: 'Limpar busca',
                                      onPressed: _clearQuery,
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: mute,
                                        size: 18,
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: FxContentWidthLimiter(
                        child: _buildBody(primary, visible),
                      ),
                    ),
                    if (!_loading && _erro == null)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            TokensStrip.s2,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s3 +
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
    );
  }

  Future<void> _confirmarExclusao(int id) async {
    final ok = await showFxConfirmSheet(
      context,
      title: 'Excluir publicação?',
      message: 'Esta ação não pode ser desfeita.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Excluir',
      destructive: true,
    );
    if (ok) _deletar(id);
  }
}

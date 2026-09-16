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
          expand: true,
          child: Column(
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
                  title: 'Nova publicação',
                  subtitle: 'Os alunos veem no feed deles.',
                  leading: FxIcon(name: 'article', color: accent, size: 18),
                ),
              ),
              Expanded(child: FeedComposerSheet(ref: ref)),
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
      final searching = _query.trim().isNotEmpty || _chip != FeedListChip.todos;
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
                label: searching ? 'Limpar filtros' : 'Criar publicação',
                onTap: searching ? _clearFilters : _abrirFormulario,
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
          return FeedPostCard(
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
            body: _loading
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
                            focusNode: _searchFocus,
                            onChanged: _onQueryChanged,
                            onTapOutside: (_) =>
                                FxKeyboardDismissScope.dismiss(),
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
                              suffixIcon: _query.trim().isEmpty
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          0,
                          TokensStrip.s4,
                          TokensStrip.s2,
                        ),
                        child: Wrap(
                          spacing: TokensStrip.s2,
                          runSpacing: TokensStrip.s2,
                          children: [
                            for (final chip in FeedListChip.values)
                              FxToggleChip(
                                label: feedListChipLabel(chip),
                                selected: _chip == chip,
                                isDark: isDark,
                                onTap: () {
                                  if (_chip == chip) return;
                                  setState(() => _chip = chip);
                                  _load();
                                },
                              ),
                          ],
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

part of 'feed_aluno_screen.dart';

class _FeedAlunoScreenState extends ConsumerState<FeedAlunoScreen> {
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

  Future<void> _curtir(int postId) async {
    try {
      final novoTotal = await FeedRepository(
        ref.read(apiClientProvider),
      ).toggleCurtida(postId);
      if (mounted) {
        setState(() => _curtidasLocais[postId] = novoTotal);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  void _abrirComentarios(int postId) {
    final aluno = ref.read(alunoMeProvider).valueOrNull;
    showFxHomeSheet<void>(
      context,
      builder: (ctx) => FeedCommentsSheet(
        postId: postId,
        repo: FeedRepository(ref.read(apiClientProvider)),
        currentAlunoId: aluno?.id,
        currentAlunoFotoUrl: aluno?.fotoUrl,
        onComentou: (novoTotal) =>
            setState(() => _comentariosLocais[postId] = novoTotal),
      ),
    );
  }

  Widget _buildBody(Color primary) {
    final searching =
        _query.trim().isNotEmpty || _chip != FeedListChip.todos;
    if (_posts.isEmpty) {
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            FxEmptyState(
              icon: searching ? 'search' : 'rss',
              title: searching
                  ? 'Nada encontrado'
                  : 'Nenhuma publicação ainda',
              subtitle: searching
                  ? 'Ajuste a busca ou o filtro para achar outra publicação.'
                  : 'Quando seu personal publicar no feed, as novidades aparecem aqui.',
              action: searching
                  ? FxEmptyAction(label: 'Limpar filtros', onTap: _clearFilters)
                  : FxEmptyAction(
                      label: 'Voltar ao início',
                      onTap: _leave,
                    ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: primary,
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          TokensStrip.s2,
          FxSettingsLayout.pageInset,
          TokensStrip.s6 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        itemCount: _posts.length + (_hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= _posts.length) {
            return FxSatelliteListTile(
              title: _loadingMore ? 'Carregando…' : 'Carregar mais',
              onTap: _loadingMore ? null : _carregarMais,
            );
          }
          final p = _posts[i];
          return FeedPostCard(
            post: p,
            index: i,
            primary: primary,
            curtidas: _curtidasLocais[p.id] ?? p.totalCurtidas,
            comentarios: _comentariosLocais[p.id] ?? p.totalComentarios,
            onCurtir: () => _curtir(p.id),
            onComentar: () => _abrirComentarios(p.id),
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
                    subtitle: 'Novidades que seu personal publica para você.',
                    tips: const [
                      FxHelpTip(
                        'Curtir e comentar',
                        'Toque em Curtir ou Comentários em qualquer publicação.',
                      ),
                      FxHelpTip(
                        'Vídeo',
                        'Toque no preview para abrir o vídeo em tela cheia.',
                      ),
                      FxHelpTip(
                        'Filtros',
                        'Busque por texto ou filtre por tipo e fixados.',
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
                    title: FocuxMicrocopy.naoFoiPossivelCarregar,
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

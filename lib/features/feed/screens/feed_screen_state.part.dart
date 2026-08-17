part of 'feed_screen.dart';

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final Map<int, int> _curtidasLocais = {};
  final Map<int, int> _comentariosLocais = {};
  List<FeedPost> _posts = [];
  bool _loading = true;
  String? _erro;
  DateTime? _fetchedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final posts =
          await FeedRepository(ref.read(apiClientProvider)).listarPersonal();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        for (final p in posts) {
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder:
          (ctx) => FeedCommentsSheet(
            postId: postId,
            repo: FeedRepository(ref.read(apiClientProvider)),
            onComentou:
                (novoTotal) =>
                    setState(() => _comentariosLocais[postId] = novoTotal),
          ),
    );
  }

  void _abrirFormulario() {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _FeedComposerSheet(ref: ref),
    ).then((created) async {
      if (created != true || !mounted) return;
      await _load();
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Publicação criada com sucesso!');
    });
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final primaryDeep = BrandPalette.deep(primary);
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    return fxScreenA11yScope(
      label: 'Feed',
      child: FxShellScaffold(
        useMesh: true,
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primary, primaryDeep]),
            borderRadius: BorderRadius.circular(44),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: _abrirFormulario,
            tooltip: 'Nova Publicação',
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: EagleTokens.darkInk),
          ),
        ),
        body: SafeArea(
          child:
              _loading
                  ? const Padding(
                    padding: EdgeInsets.all(TokensStrip.s4),
                    child: SkeletonList(count: 4),
                  )
                  : _erro != null
                  ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    message: _erro!,
                    onRetry: _load,
                  )
                  : _posts.isEmpty
                  ? FxEmptyState(
                    icon: 'rss',
                    title: 'Nenhuma publicacao ainda',
                    subtitle:
                        'Compartilhe novidades, videos e conquistas com seus alunos.',
                    action: FxEmptyAction(
                      label: 'Criar publicacao',
                      onTap: _abrirFormulario,
                    ),
                  )
                  : RefreshIndicator(
                    color: primary,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        10,
                        16,
                        110,
                      ),
                      itemCount: _posts.length + 1,
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return _FeedListHeader(
                            freshnessLabel: freshnessLabel,
                            chrome: chrome,
                            primary: primary,
                            primaryDeep: primaryDeep,
                            onNovaPublicacao: _abrirFormulario,
                          );
                        }
                        final p = _posts[i - 1];
                        return _FeedPostCard(
                          post: p,
                          index: i,
                          primary: primary,
                          curtidas: _curtidasLocais[p.id] ?? p.totalCurtidas,
                          comentarios:
                              _comentariosLocais[p.id] ?? p.totalComentarios,
                          onCurtir: () => _curtir(p.id),
                          onComentar: () => _abrirComentarios(p.id),
                          onFixar: () => _toggleFixar(p.id),
                          onExcluir: () => _confirmarExclusao(p.id),
                        );
                      },
                    ),
                  ),
        ),
      ),
    );
  }

  void _confirmarExclusao(int id) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Excluir publicação?'),
            content: const Text('Esta ação não pode ser desfeita.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _deletar(id);
                },
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: EagleTokens.bad),
                ),
              ),
            ],
          ),
    );
  }
}

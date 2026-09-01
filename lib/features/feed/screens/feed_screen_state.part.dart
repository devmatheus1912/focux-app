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
    showFxHomeSheet<void>(
      context,
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
                  leading: Icon(Icons.rss_feed_outlined, color: accent, size: 18),
                ),
              ),
              _FeedComposerSheet(ref: ref),
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

  Widget _buildBody(Color primary) {
    if (_posts.isEmpty) {
      return RefreshIndicator(
        color: primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            FxEmptyState(
              icon: 'rss',
              title: 'Nenhuma publicação ainda',
              subtitle:
                  'Compartilhe novidades, vídeos e conquistas com seus alunos.',
              action: FxEmptyAction(
                label: 'Criar publicação',
                onTap: _abrirFormulario,
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
        padding: const EdgeInsets.fromLTRB(
          FxSettingsLayout.pageInset,
          8,
          FxSettingsLayout.pageInset,
          32,
        ),
        itemCount: _posts.length,
        itemBuilder: (_, i) {
          final p = _posts[i];
          return _FeedPostCard(
            post: p,
            index: i,
            primary: primary,
            curtidas: _curtidasLocais[p.id] ?? p.totalCurtidas,
            comentarios: _comentariosLocais[p.id] ?? p.totalComentarios,
            onCurtir: () => _curtir(p.id),
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
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    return fxScreenA11yScope(
      label: 'Feed',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Feed',
          subtitle: feedHubSubtitle(freshnessLabel),
          actions: [
            ShellHeaderIconButton(
              icon: 'plus',
              tooltip: 'Nova publicação',
              onTap: _abrirFormulario,
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
                : FxContentWidthLimiter(child: _buildBody(primary)),
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

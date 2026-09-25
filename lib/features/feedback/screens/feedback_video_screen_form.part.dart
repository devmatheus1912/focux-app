part of 'feedback_video_screen.dart';

extension on _FeedbackVideoScreenState {
  Future<void> _novoFeedback() async {
    HapticFeedback.selectionClick();
    final features = ref.read(planoFeaturesProvider).value;
    if (features == null || !PlanoCapability.has(features, 'poseCoach')) {
      if (!mounted) return;
      await UpgradePromptSheet.show(
        context: context,
        featureName: 'Pose Coach — feedback de vídeo',
        capability: 'poseCoach',
      );
      return;
    }
    var alunoId = widget.alunoId;
    var alunoNome = widget.alunoNome?.trim() ?? '';
    if (alunoId == null) {
      try {
        final home = await ref.read(alunosHomeProvider.future);
        if (!mounted) return;
        final alunos = filterAlunoPickerAlunos(home.alunos, '');
        if (alunos.isEmpty) {
          FeedbackHelper.showError(context, 'Cadastre um aluno primeiro.');
          return;
        }
        final picked = await showFxInsetPickerSheet<int>(
          context,
          title: 'Aluno',
          items: [
            for (final a in alunos)
              FxInsetPickerSheetItem(
                value: a.id,
                label: a.nome,
                subtitle: a.email.trim().isEmpty ? null : a.email,
              ),
          ],
        );
        if (picked == null || !mounted) return;
        for (final a in alunos) {
          if (a.id == picked) {
            alunoId = a.id;
            alunoNome = a.nome;
            break;
          }
        }
      } catch (e) {
        if (!mounted) return;
        FeedbackHelper.showError(context, friendlyError(e));
        return;
      }
    }
    final selectedAlunoId = alunoId;
    if (selectedAlunoId == null) return;

    late final int selectedExercicioId;
    var exercicioNome = 'Exercício';
    try {
      final pickedEx = await showFxHomeSheet<_FeedbackExercicioPick>(
        context,
        builder:
            (ctx) => _FeedbackExercicioPickerSheet(alunoId: selectedAlunoId),
      );
      if (pickedEx == null || !mounted) return;
      selectedExercicioId = pickedEx.id;
      exercicioNome = pickedEx.nome;
    } catch (e) {
      if (!mounted) return;
      if (isPlanGateError(e)) {
        await UpgradePromptSheet.show(
          context: context,
          featureName: 'Pose Coach — feedback de vídeo',
          capability: 'poseCoach',
        );
        return;
      }
      FeedbackHelper.showError(context, friendlyError(e));
      return;
    }

    final videoUrlCtrl = TextEditingController();
    final comentarioCtrl = TextEditingController();
    var created = false;

    try {
      if (!mounted) return;
      final ok = await showFxFormSheet(
        context,
        title: 'Novo feedback de vídeo',
        subtitle: alunoNome.isEmpty
            ? exercicioNome
            : 'Para ${satelliteFirstName(alunoNome)} · $exercicioNome',
        icon: Icons.videocam_outlined,
        confirmLabel: 'Salvar',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AlunoInsetFormField(
              controller: videoUrlCtrl,
              label: 'URL do vídeo',
              icon: Icons.link_outlined,
              hint: 'Cloudinary, YouTube…',
            ),
            AlunoInsetFormField(
              controller: comentarioCtrl,
              label: 'Comentário técnico',
              icon: Icons.notes_outlined,
              maxLines: 3,
              showDivider: false,
            ),
          ],
        ),
      );
      if (ok != true) return;
      final video = videoUrlCtrl.text.trim();
      final com = comentarioCtrl.text.trim();
      if (video.isEmpty || com.isEmpty) {
        if (mounted) {
          FeedbackHelper.showError(context, 'Preencha todos os campos');
        }
        return;
      }
      await FeedbackVideoRepository(ref.read(apiClientProvider)).registrar(
        alunoId: selectedAlunoId,
        exercicioId: selectedExercicioId,
        videoUrl: video,
        comentario: com,
      );
      created = true;
    } catch (e) {
      if (!mounted) return;
      if (isPlanGateError(e)) {
        await UpgradePromptSheet.show(
          context: context,
          featureName: 'Pose Coach — feedback de vídeo',
          capability: 'poseCoach',
        );
        return;
      }
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      videoUrlCtrl.dispose();
      comentarioCtrl.dispose();
    }
    if (created) await _load(reset: true);
  }
}

typedef _FeedbackExercicioPick = ({int id, String nome});

class _FeedbackExercicioPickerSheet extends ConsumerStatefulWidget {
  const _FeedbackExercicioPickerSheet({required this.alunoId});

  final int alunoId;

  @override
  ConsumerState<_FeedbackExercicioPickerSheet> createState() =>
      _FeedbackExercicioPickerSheetState();
}

class _FeedbackExercicioPickerSheetState
    extends ConsumerState<_FeedbackExercicioPickerSheet> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  var _query = '';
  var _hasNext = false;
  var _loading = true;
  var _loadingMore = false;
  String? _error;
  final _items = <({int id, String nome})>[];

  @override
  void initState() {
    super.initState();
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 320), () {
      final next = value.trim();
      if (next == _query) return;
      _query = next;
      _fetch(reset: true);
    });
  }

  Future<void> _fetch({required bool reset}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
      });
    } else {
      if (_loadingMore || !_hasNext) return;
      setState(() => _loadingMore = true);
    }
    try {
      final repo = FeedbackVideoRepository(ref.read(apiClientProvider));
      final all = await repo.exerciciosDisponiveisParaAluno(widget.alunoId);
      final q = _query.toLowerCase();
      final filtered =
          q.isEmpty
              ? all
              : all
                  .where((e) => e.nome.toLowerCase().contains(q))
                  .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(filtered.map((e) => (id: e.id, nome: e.nome)));
        _hasNext = false;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    return FxHomeSheetSurface(
      isDark: isDark,
      expand: true,
      maxHeight:
          MediaQuery.sizeOf(context).height * FxHomeSheetChrome.expandHeightFactor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FxHomeSheetHandle(isDark: isDark),
          FxHomeSheetHeader(
            isDark: isDark,
            title: 'Exercício do feedback',
            subtitle: 'Lista dos exercícios disponíveis para feedback de vídeo.',
            leading: Icon(Icons.videocam_outlined, color: primary, size: 20),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s2,
              FxSettingsLayout.pageInset,
              TokensStrip.s2,
            ),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onChanged: _onQueryChanged,
              onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
              decoration: InputDecoration(
                hintText: 'Buscar exercício',
                prefixIcon: const Icon(Icons.search_rounded),
                border: FxInputDeco.outlineBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(FxSettingsLayout.pageInset),
                    child: SkeletonList(count: 6),
                  )
                : _error != null
                ? FxErrorState(
                    chromeOnDark: isDark,
                    primary: primary,
                    message: _error!,
                    onRetry: () => _fetch(reset: true),
                  )
                : _items.isEmpty
                ? FxEmptyState(
                    icon: 'search',
                    title: _query.isEmpty
                        ? 'Cadastre um exercício primeiro'
                        : 'Nenhum exercício encontrado',
                    subtitle: _query.isEmpty
                        ? 'O catálogo aparece aqui para o feedback de vídeo.'
                        : 'Tente outro nome ou carregue o catálogo sem busca.',
                  )
                : ListView.builder(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      0,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s6,
                    ),
                    itemCount: _items.length + (_hasNext ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _items.length) {
                        return FxSatelliteListTile(
                          title: _loadingMore ? 'Carregando…' : 'Carregar mais',
                          onTap: _loadingMore ? null : () => _fetch(reset: false),
                        );
                      }
                      final item = _items[index];
                      return FxSatelliteListTile(
                        title: item.nome,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop(item);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

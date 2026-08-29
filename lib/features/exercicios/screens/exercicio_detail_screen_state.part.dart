part of 'exercicio_detail_screen.dart';

class _ExercicioDetailScreenState extends ConsumerState<ExercicioDetailScreen> {
  bool _uploadingVideo = false;

  Future<void> _toggleFavorito(BuildContext context, bool favoritado) async {
    final repo = ref.read(exercicioRepositoryProvider);
    try {
      if (favoritado) {
        await repo.desfavoritarExercicio(widget.exercicioId);
      } else {
        await repo.favoritarExercicio(widget.exercicioId);
      }
      ref.invalidate(exercicioProvider(widget.exercicioId));
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  Future<void> _pickAndUploadVideo(BuildContext context) async {
    setState(() => _uploadingVideo = true);
    try {
      final uploaded = await ref
          .read(exercicioVideoUploaderProvider)
          .pickAndUpload(widget.exercicioId);
      if (uploaded == null) return;
      AnalyticsService.instance.track(
        'video_personal_upload',
        props: {'exId': widget.exercicioId},
      );
      ref.invalidate(exercicioProvider(widget.exercicioId));
      ref.invalidate(exerciciosFilteredProvider);
      if (!context.mounted) return;
      FeedbackHelper.showSuccess(
        context,
        'Video proprio adicionado ao exercicio.',
      );
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
    }
  }

  Future<void> _updateEditorialReview(
    BuildContext context,
    String status,
    String? currentNotes,
  ) async {
    final notesCtrl = TextEditingController(text: currentNotes ?? '');
    final saved = await showFxFormSheet(
      context,
      title: _editorialActionTitle(status),
      icon: Icons.rate_review_outlined,
      confirmLabel: 'Salvar',
      child: TextField(
        controller: notesCtrl,
        minLines: 3,
        maxLines: 6,
        decoration: InputDecoration(
          border: FxInputDeco.outlineBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          hintText: 'Notas tecnicas, fonte do video ou motivo da decisao',
        ),
      ),
    );
    final notes = saved ? notesCtrl.text.trim() : null;
    notesCtrl.dispose();
    if (notes == null) return;

    try {
      await ref
          .read(exercicioRepositoryProvider)
          .atualizarCuradoriaEditorial(
            id: widget.exercicioId,
            status: status,
            notes: notes.isEmpty ? null : notes,
          );
      ref.invalidate(exercicioProvider(widget.exercicioId));
      ref.invalidate(exerciciosFilteredProvider);
      ref.invalidate(exerciciosCuradoriaProvider);
      if (!context.mounted) return;
      FeedbackHelper.showSuccess(
        context,
        'Curadoria marcada como ${_formatEditorialStatus(status)}.',
      );
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercicioAsync = ref.watch(exercicioProvider(widget.exercicioId));

    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;

    return fxScreenA11yScope(
      label: 'Exercicio',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Exercicio',
          subtitle: 'DETALHES',
          onBack: () => safePopOrGo(context, '/exercicios'),
          actions: exercicioAsync.maybeWhen(
            data:
                (ex) => [
                  IconButton(
                    tooltip: 'Editar exercício',
                    onPressed: () async {
                      final saved = await context.push<bool>(
                        '/exercicios/${widget.exercicioId}/editar',
                      );
                      if (saved == true && context.mounted) {
                        ref.invalidate(exercicioProvider(widget.exercicioId));
                      }
                    },
                    icon: Icon(Icons.edit_outlined, color: mute),
                  ),
                  IconButton(
                    tooltip:
                        ex.favoritado
                            ? 'Remover dos favoritos'
                            : 'Adicionar aos favoritos',
                    onPressed: () => _toggleFavorito(context, ex.favoritado),
                    icon: Icon(
                      ex.favoritado
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: ex.favoritado ? EagleTokens.warn : mute,
                    ),
                  ),
                ],
            orElse: () => const <Widget>[],
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: exercicioAsync.when(
            loading: () => const SkeletonList(count: 5),
            error:
                (e, _) => FxErrorState(
                  chromeOnDark: isDark,
                  primary: primary,
                  message: friendlyError(e),
                  onRetry:
                      () =>
                          ref.invalidate(exercicioProvider(widget.exercicioId)),
                  title: 'Não conseguimos carregar o exercício',
                ),
            data:
                (ex) => SingleChildScrollView(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        ex.nome,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900, color: ink),
                      ),
                      const SizedBox(height: 10),
                      _ExerciseEssentials(exercicio: ex),
                      const SizedBox(height: 14),
                      _OwnVideoPanel(
                        hasVideo: ex.videoUrl?.isNotEmpty == true,
                        uploading: _uploadingVideo,
                        onUpload: () => _pickAndUploadVideo(context),
                      ),
                      if (ex.videoUrl?.isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _VideoPlayer(url: ex.videoUrl!),
                      ] else if (ex.gifUrl != null ||
                          ex.thumbnailUrl != null) ...[
                        const SizedBox(height: 12),
                        _ExercisePreviewImage(
                          url: ex.gifUrl ?? ex.thumbnailUrl!,
                        ),
                      ],
                      if (ex.descricao?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 14),
                        _SimpleInfoCard(
                          icon: Icons.menu_book_rounded,
                          title: 'Como orientar',
                          text: ex.descricao!.trim(),
                        ),
                      ],
                      if (ex.errosComuns?.trim().isNotEmpty == true ||
                          ex.contraindicacoes?.trim().isNotEmpty == true ||
                          ex.substitutos?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 12),
                        _GuidanceExpansion(exercicio: ex),
                      ],
                      const SizedBox(height: 12),
                      _TechnicalDataExpansion(
                        exercicio: ex,
                        onChangeEditorial:
                            (status) => _updateEditorialReview(
                              context,
                              status,
                              ex.editorialNotes,
                            ),
                      ),
                    ],
                  ),
                ),
          ),
        ),
      ),
    );
  }
}

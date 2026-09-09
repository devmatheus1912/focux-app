part of 'exercicio_detail_screen.dart';

class _ExercicioDetailScreenState extends ConsumerState<ExercicioDetailScreen> {
  bool _uploadingVideo = false;
  DateTime? _fetchedAt;

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

  Future<void> _pickAndUploadVideo(
    BuildContext context, {
    required bool hasVideo,
  }) async {
    final ok = await showFxConfirmSheet(
      context,
      title: exerciseVideoUploadConfirmTitle(hasVideo: hasVideo),
      message: exerciseVideoUploadConfirmMessage(),
      confirmLabel: exerciseVideoUploadLabel(hasVideo: hasVideo),
    );
    if (!ok || !context.mounted) return;
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
      FeedbackHelper.showSuccess(context, exerciseVideoUploadSuccess());
    } catch (e) {
      if (context.mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
    }
  }

  Future<void> _removeOwnVideo(BuildContext context) async {
    final ok = await showFxConfirmSheet(
      context,
      title: exerciseVideoRemoveConfirmTitle(),
      message: exerciseVideoRemoveConfirmMessage(),
      confirmLabel: exerciseVideoRemoveLabel(),
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    setState(() => _uploadingVideo = true);
    try {
      await ref
          .read(exercicioRepositoryProvider)
          .removerVideo(id: widget.exercicioId);
      ref.invalidate(exercicioProvider(widget.exercicioId));
      ref.invalidate(exerciciosFilteredProvider);
      if (!context.mounted) return;
      FeedbackHelper.showSuccess(context, exerciseVideoRemoveSuccess());
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
          hintText: 'Notas técnicas, fonte do vídeo ou motivo da decisão',
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

  Future<void> _refresh() async {
    ref.invalidate(exercicioProvider(widget.exercicioId));
    await ref.read(exercicioProvider(widget.exercicioId).future);
    if (mounted) setState(() => _fetchedAt = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final exercicioAsync = ref.watch(exercicioProvider(widget.exercicioId));
    if (exercicioAsync.hasValue) {
      _fetchedAt ??= DateTime.now();
    }

    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;

    void leave() => safePopOrGo(context, '/exercicios');

    return fxScreenA11yScope(
      label: 'Exercício',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          leave();
        },
        child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Exercício',
          subtitle: FxHubFreshness.fromFetchedAt(_fetchedAt),
          onBack: leave,
          actions: [
            FxHelpIconButton(
              tooltip: 'Como usar este exercício',
              onTap: () => showExercicioDetailHelpSheet(context),
            ),
            ...exercicioAsync.maybeWhen(
              data:
                  (ex) => [
                    IconButton(
                      tooltip:
                          ex.favoritado
                              ? 'Remover dos favoritos'
                              : 'Adicionar aos favoritos',
                      onPressed: () => _toggleFavorito(context, ex.favoritado),
                      icon: FxIcon(
                        name: 'star',
                        size: 22,
                        color: ex.favoritado ? EagleTokens.warn : mute,
                      ),
                    ),
                  ],
              orElse: () => const <Widget>[],
            ),
          ],
        ),
        body: exercicioAsync.when(
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
                (ex) {
                  final grupo = _grupoLabel(ex);
                  return Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: FxContentWidthLimiter(
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              FxSettingsLayout.pageInset,
                              8,
                              FxSettingsLayout.pageInset,
                              32,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                FxHubHeader(
                                  title: ex.nome,
                                  subtitle: exercicioHubSubtitle(grupo: grupo),
                                ),
                              const SizedBox(height: TokensStrip.s4),
                              OperationalMetricTile(
                                label: 'Grupo',
                                value: grupo ?? '—',
                                hint: 'Musculação / grupo',
                                color: primary,
                                isDark: isDark,
                              ),
                              const SizedBox(height: TokensStrip.s2),
                              OperationalMetricTile(
                                label: 'Modalidade',
                                value: _modalidadeLabel(ex) ?? '—',
                                hint: 'Cadastro',
                                color: primary,
                                isDark: isDark,
                              ),
                              const SizedBox(height: TokensStrip.s2),
                              OperationalMetricTile(
                                label: 'Vídeo',
                                value: exercicioVideoMetric(
                                  hasVideo: ex.videoUrl?.isNotEmpty == true,
                                ),
                                hint: 'Demo do exercício',
                                color: primary,
                                isDark: isDark,
                              ),
                              const SizedBox(height: TokensStrip.s2),
                              OperationalMetricTile(
                                label: 'Dificuldade',
                                value: _dificuldadeLabel(ex) ?? '—',
                                hint: exercicioDificuldadeHint(
                                  _dificuldadeLabel(ex),
                                ),
                                color: primary,
                                isDark: isDark,
                              ),
                              const SizedBox(height: TokensStrip.s3),
                              Wrap(
                                spacing: TokensStrip.s2,
                                runSpacing: TokensStrip.s2,
                                children: [
                                  DashboardHomeActionChip(
                                    label: 'Lista',
                                    accent: primary,
                                    isDark: isDark,
                                    onPressed: leave,
                                  ),
                                  DashboardHomeActionChip(
                                    label: 'Biblioteca',
                                    accent: primary,
                                    isDark: isDark,
                                    onPressed: () => context.push('/exercicios'),
                                  ),
                                  DashboardHomeActionChip(
                                    label: 'Treinos',
                                    accent: primary,
                                    isDark: isDark,
                                    onPressed: () => context.push('/treinos'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _ExerciseEssentials(exercicio: ex),
                              const SizedBox(height: 14),
                              _OwnVideoPanel(
                                hasVideo: ex.videoUrl?.isNotEmpty == true,
                                uploading: _uploadingVideo,
                                onUpload:
                                    () => _pickAndUploadVideo(
                                      context,
                                      hasVideo:
                                          ex.videoUrl?.isNotEmpty == true,
                                    ),
                                onRemove: () => _removeOwnVideo(context),
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
                                  ex.contraindicacoes?.trim().isNotEmpty ==
                                      true ||
                                  ex.substitutos?.trim().isNotEmpty ==
                                      true) ...[
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
                          label: 'Editar exercício',
                          onPressed: () async {
                            final saved = await context.push<bool>(
                              '/exercicios/${widget.exercicioId}/editar',
                            );
                            if (saved == true && context.mounted) {
                              ref.invalidate(
                                exercicioProvider(widget.exercicioId),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                );
                },
        ),
      ),
      ),
    );
  }
}

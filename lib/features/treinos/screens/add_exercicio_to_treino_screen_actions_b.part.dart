part of 'add_exercicio_to_treino_screen.dart';

extension AddExercicioToTreinoScreenActionsB
    on _AddExercicioToTreinoScreenState {
  Future<void> _submit() async {
    if (_selecionado == null) {
      setState(() {
        _error = 'Selecione um exercício.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final exercicioId = _selecionado!.id;
      await ref
          .read(treinoRepositoryProvider)
          .adicionarExercicio(
            widget.treinoId,
            exercicioId,
            series: int.tryParse(_seriesCtrl.text) ?? 3,
            repeticoes: _repCtrl.text,
            descanso: int.tryParse(_descansoCtrl.text) ?? 60,
            cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
            observacoes: _observacoesCtrl.text,
            tipoSerie: _tipoSerie,
            grupoSuperset:
                _tipoSerie == 'SUPERSET'
                    ? int.tryParse(_grupoSupersetCtrl.text)
                    : null,
          );
      await _persistAfterAdd(exercicioId);
      if (mounted) {
        HapticFeedback.mediumImpact();
        FeedbackHelper.showSuccess(
          context,
          '${_selecionado!.nomeDisplay} adicionado ao treino.',
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
        _error = friendlyError(e, fallback: 'Erro ao adicionar exercício.');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _submitAndContinue() async {
    if (_selecionado == null) {
      setState(() => _error = 'Selecione um exercício.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final nome = _selecionado!.nomeDisplay;
      final exercicioId = _selecionado!.id;
      await ref
          .read(treinoRepositoryProvider)
          .adicionarExercicio(
            widget.treinoId,
            exercicioId,
            series: int.tryParse(_seriesCtrl.text) ?? 3,
            repeticoes: _repCtrl.text,
            descanso: int.tryParse(_descansoCtrl.text) ?? 60,
            cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
            observacoes: _observacoesCtrl.text,
            tipoSerie: _tipoSerie,
            grupoSuperset:
                _tipoSerie == 'SUPERSET'
                    ? int.tryParse(_grupoSupersetCtrl.text)
                    : null,
          );
      await _persistAfterAdd(exercicioId);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ref.invalidate(treinoProvider(widget.treinoId));
      setState(() {
        _selecionado = null;
        _buscaCtrl.clear();
        _loading = false;
      });
      FeedbackHelper.showSuccess(
        context,
        '$nome adicionado. Escolha o próximo.',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e, fallback: 'Erro ao adicionar exercício.');
          _loading = false;
        });
      }
    }
  }

  Future<void> _adicionarRapido(Exercicio exercicio) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final exercicioId = exercicio.id;
      await ref
          .read(treinoRepositoryProvider)
          .adicionarExercicio(
            widget.treinoId,
            exercicioId,
            series: int.tryParse(_seriesCtrl.text) ?? 3,
            repeticoes: _repCtrl.text,
            descanso: int.tryParse(_descansoCtrl.text) ?? 60,
            cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
            observacoes: _observacoesCtrl.text,
            tipoSerie: _tipoSerie,
            grupoSuperset:
                _tipoSerie == 'SUPERSET'
                    ? int.tryParse(_grupoSupersetCtrl.text)
                    : null,
          );
      await _persistAfterAdd(exercicioId);
      AnalyticsService.instance.track(
        'quick_add_padrao',
        props: {'exId': exercicio.id, 'treinoId': widget.treinoId},
      );
      if (mounted) {
        ref.invalidate(treinoProvider(widget.treinoId));
        FeedbackHelper.showSuccess(
          context,
          '${exercicio.nomeDisplay} adicionado.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e, fallback: 'Erro ao adicionar exercício.');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openSimilarPicker(List<Exercicio> exercicios) async {
    final alvo = _selecionado;
    if (alvo == null) return;
    Exercicio? replacement;
    setState(() => _bottomBarHidden = true);
    try {
      await showFxBottomSheet<void>(
        context: context,
        builder:
            (_) => SubstituirExercicioBottomSheet(
              alvo: alvo,
              equipamentosAluno:
                  _pickerFilter.filtrarPorAluno &&
                          _pickerFilter.equipamentosAluno.isNotEmpty
                      ? _pickerFilter.equipamentosAluno
                      : _pickerFilter.equipamento == null
                      ? null
                      : {_pickerFilter.equipamento!},
              onEscolher: (exercicio) => replacement = exercicio,
            ),
      );
    } finally {
      if (mounted) setState(() => _bottomBarHidden = false);
    }
    if (replacement != null && mounted) {
      _selectExercise(replacement!);
    }
  }

  List<Exercicio> _visibleExercicios(List<Exercicio> exercicios) {
    return applyExercisePickerFilter(exercicios, _pickerFilter);
  }

  Future<void> _openExercisePicker(
    List<Exercicio> exercicios, {
    required Set<int> alreadyInTreinoIds,
  }) async {
    HapticFeedback.selectionClick();
    setState(() => _bottomBarHidden = true);
    Exercicio? selected;
    try {
      selected = await showFxBottomSheet<Exercicio>(
        context: context,
        builder:
            (sheetContext) => _ExercisePickerSheet(
              exercicios: exercicios,
              selected: _selecionado,
              alreadyInTreinoIds: alreadyInTreinoIds,
              initialQuery: _buscaQuery,
              onUploadVideo:
                  (exercicio) => _uploadExerciseVideo(
                    exercicio,
                    origin: 'treino_library_sheet',
                  ),
            ),
      );
    } finally {
      if (mounted) setState(() => _bottomBarHidden = false);
    }
    if (selected != null && mounted) {
      _selectExercise(selected);
    }
  }

  Future<Exercicio?> _freshExercicio(int exercicioId) async {
    final list = await ref.read(exerciciosProvider.future);
    for (final exercicio in list) {
      if (exercicio.id == exercicioId) return exercicio;
    }
    return null;
  }

  Future<void> _scheduleMediaRefresh(int exercicioId) async {
    for (final delay in [
      const Duration(seconds: 2),
      const Duration(seconds: 5),
    ]) {
      await Future<void>.delayed(delay);
      if (!mounted) return;
      ref.invalidate(exerciciosProvider);
      final fresh = await _freshExercicio(exercicioId);
      if (fresh == null || !mounted) continue;
      if (_selecionado?.id == exercicioId) {
        setState(() => _selecionado = fresh);
      }
      final poster = exercisePreviewMediaUrlFor(fresh);
      if (poster != null && poster.isNotEmpty) return;
    }
  }

  Future<void> _uploadSelectedExerciseVideo() async {
    final exercicio = _selecionado;
    if (exercicio == null) return;
    final updated = await _uploadExerciseVideo(
      exercicio,
      origin: 'treino_add_exercise',
    );
    if (updated != null && mounted) {
      setState(() => _selecionado = updated);
    }
  }

  Future<Exercicio?> _uploadExerciseVideo(
    Exercicio exercicio, {
    String origin = 'treino_add_exercise',
  }) async {
    if (_mediaLoading) return null;
    final file = await _videoPicker.pickVideo(source: ImageSource.gallery);
    if (file == null || !mounted) return null;
    final messenger = FeedbackHelper.messengerOf(context);
    setState(() => _mediaLoading = true);
    FeedbackHelper.showSuccess(
      context,
      'Enviando vídeo de ${exercicio.nomeDisplay}...',
    );
    try {
      final updated = await ref
          .read(exercicioRepositoryProvider)
          .uploadVideo(
            id: exercicio.id,
            bytes: await file.readAsBytes(),
            filename: file.name,
          );
      AnalyticsService.instance.track(
        'video_personal_upload',
        props: {'exId': exercicio.id, 'origin': origin},
      );
      ref.invalidate(exerciciosProvider);
      if (!mounted) return null;
      final fresh = await _freshExercicio(updated.id) ?? updated;
      if (_selecionado?.id == fresh.id) {
        setState(() => _selecionado = fresh);
      }
      messenger.clearSnackBars();
      if (!mounted) return fresh;
      HapticFeedback.mediumImpact();
      _triggerVideoUploadCelebration();
      FeedbackHelper.showSuccess(
        context,
        'Vídeo enviado! Miniatura e prévia atualizadas.',
      );
      unawaited(_scheduleMediaRefresh(fresh.id));
      return fresh;
    } catch (e) {
      if (!mounted) return null;
      messenger.clearSnackBars();
      FeedbackHelper.showError(
        context,
        friendlyError(
          e,
          fallback:
              'Não foi possível enviar o vídeo. Verifique a conexão e a configuração de mídia no servidor.',
        ),
      );
      return null;
    } finally {
      if (mounted) {
        setState(() => _mediaLoading = false);
      }
    }
  }

  Future<void> _removeSelectedExerciseVideo() async {
    final exercicio = _selecionado;
    if (exercicio == null || _mediaLoading) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.34),
      builder:
          (sheetContext) => _RemoveExerciseVideoSheet(exercicio: exercicio),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _mediaLoading = true);
    try {
      final updated = await ref
          .read(exercicioRepositoryProvider)
          .removerVideo(id: exercicio.id);
      AnalyticsService.instance.track(
        'video_personal_remove',
        props: {'exId': exercicio.id, 'origin': 'treino_add_exercise'},
      );
      ref.invalidate(exerciciosProvider);
      if (!mounted) return;
      setState(() => _selecionado = updated);
      FeedbackHelper.showSuccess(context, 'Vídeo removido do exercício.');
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(
        context,
        friendlyError(
          e,
          fallback:
              'Não foi possível enviar o vídeo. Verifique a conexão e a configuração de mídia no servidor.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _mediaLoading = false);
      }
    }
  }

  Future<void> _previewSelectedExerciseVideo() async {
    final exercicio = _selecionado;
    if (exercicio == null || !canPreviewExerciseMedia(exercicio)) return;
    HapticFeedback.selectionClick();
    await showExerciseMediaPreview(context, exercicio: exercicio);
  }

  Widget _buildTabContent({
    required BuildContext context,
    required List<Exercicio> exercicios,
    required List<Exercicio> allExercicios,
    required int totalLibraryCount,
    required bool isDark,
    required Color primary,
    required Set<int> alreadyInTreinoIds,
  }) {
    final browseHeight =
        (MediaQuery.sizeOf(context).height - 280)
            .clamp(430.0, 620.0)
            .toDouble();
    switch (_tabIndex) {
      case 1:
        return SizedBox(
          height: browseHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MontarComModeloCard(
                onTap: _openTemplateBuilder,
                isDark: isDark,
                primary: primary,
                templateCount: templateSplits.length,
              ),
              const SizedBox(height: 8),
              _CreateExerciseButton(
                primary: primary,
                expand: true,
                onPressed: _openCreateExercise,
              ),
              const SizedBox(height: 10),
              if (_alunoFilterNome != null && _pickerFilter.filtrarPorAluno)
                _AlunoEquipmentFilterBanner(
                  alunoNome: _alunoFilterNome!,
                  equipamentos: _pickerFilter.equipamentosAluno,
                  isDark: isDark,
                  primary: primary,
                  onClear:
                      () => setState(
                        () =>
                            _pickerFilter = _pickerFilter.copyWith(
                              clearAluno: true,
                            ),
                      ),
                ),
              ExercisePickerFilterBar(
                filter: _pickerFilter,
                isDark: isDark,
                primary: primary,
                onChanged:
                    (ExercisePickerFilter next) =>
                        setState(() => _pickerFilter = next),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: PadraoMovimentoGrid(
                  alreadyInTreinoIds: alreadyInTreinoIds,
                  pickerFilter: _pickerFilter,
                  onAdicionar: _selectExercise,
                  onClearFilters:
                      () => setState(
                        () => _pickerFilter = const ExercisePickerFilter(),
                      ),
                ),
              ),
            ],
          ),
        );
      default:
        final compact = _selecionado != null;
        final query = _buscaQuery.trim().toLowerCase();
        final libraryLines = exercisePickerLibraryLines(
          filteredCount: exercicios.length,
          totalCount: totalLibraryCount,
          filter: _pickerFilter,
        );
        final showFilterEmpty =
            !compact &&
            exercicios.isEmpty &&
            (_pickerFilter.isActive || _buscaQuery.trim().length >= 2);
        final favoriteShortcuts =
            query.length >= 2 || _pickerFilter.somenteFavoritos
                ? const <Exercicio>[]
                : sortExerciciosForPicker(
                  favoriteExercises(exercicios),
                  alreadyInTreinoIds: alreadyInTreinoIds,
                ).take(4).toList();
        final quickMatches =
            query.length < 2
                ? const <Exercicio>[]
                : sortExerciciosForPicker(
                  exercicios.where((exercicio) {
                    final haystack =
                        '${exercicio.nome} ${exercicio.musculoAlvo ?? ''} '
                                '${exercicio.equipamento ?? ''}'
                            .toLowerCase();
                    return haystack.contains(query);
                  }),
                  alreadyInTreinoIds: alreadyInTreinoIds,
                ).take(6).toList();
        final curatedSuggestions =
            !compact && query.isEmpty && favoriteShortcuts.isEmpty
                ? curatedPickerSuggestions(
                  exercicios,
                  alreadyInTreinoIds: alreadyInTreinoIds,
                  recentIds: _recentIds,
                )
                : const <Exercicio>[];
        final hasBrowseShortcuts =
            !showFilterEmpty &&
            !compact &&
            (curatedSuggestions.isNotEmpty ||
                favoriteShortcuts.isNotEmpty ||
                quickMatches.isNotEmpty);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact && _selecionado != null) ...[
              _CompactSelectedExerciseBar(
                exercicio: _selecionado!,
                isDark: isDark,
                primary: primary,
                celebrateVideoSuccess: _celebrateVideoSuccess,
                onChange:
                    () => _openExercisePicker(
                      allExercicios,
                      alreadyInTreinoIds: alreadyInTreinoIds,
                    ),
                onPreview:
                    canPreviewExerciseMedia(_selecionado!)
                        ? _previewSelectedExerciseVideo
                        : null,
              ),
              const SizedBox(height: 8),
              ExerciseVideoUploadStrip(
                exercicio: _selecionado!,
                isDark: isDark,
                primary: primary,
                mediaLoading: _mediaLoading,
                dense: true,
                onPreview: _previewSelectedExerciseVideo,
                onUpload: _uploadSelectedExerciseVideo,
                onRemove: _removeSelectedExerciseVideo,
              ),
              const SizedBox(height: 10),
            ],
            if (!compact) ...[
              TextField(
                controller: _buscaCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar supino, agachamento, remada...',
                  prefixIcon: Icon(Icons.search_rounded, color: primary),
                  suffixIcon:
                      _buscaQuery.isEmpty
                          ? null
                          : IconButton(
                            onPressed: () => _buscaCtrl.clear(),
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Limpar busca',
                          ),
                  filled: true,
                  fillColor:
                      isDark ? EagleTokens.darkCardHi : TokensStrip.cardBg,
                  border: FxInputDeco.outlineBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_alunoFilterNome != null && _pickerFilter.filtrarPorAluno)
                _AlunoEquipmentFilterBanner(
                  alunoNome: _alunoFilterNome!,
                  equipamentos: _pickerFilter.equipamentosAluno,
                  isDark: isDark,
                  primary: primary,
                  onClear:
                      () => setState(
                        () =>
                            _pickerFilter = _pickerFilter.copyWith(
                              clearAluno: true,
                            ),
                      ),
                ),
              ExercisePickerFilterBar(
                filter: _pickerFilter,
                isDark: isDark,
                primary: primary,
                onChanged:
                    (ExercisePickerFilter next) =>
                        setState(() => _pickerFilter = next),
              ),
            ],
            if (showFilterEmpty) ...[
              const SizedBox(height: 16),
              FxEmptyState(
                icon: 'search',
                title: buscarTabEmptyTitle(
                  filter: _pickerFilter,
                  query: _buscaQuery,
                ),
                subtitle: buscarTabEmptyMessage(filter: _pickerFilter),
                action: FxEmptyAction(
                  label:
                      _pickerFilter.somenteFavoritos
                          ? 'Ver biblioteca completa'
                          : 'Limpar filtros e busca',
                  onTap:
                      _pickerFilter.somenteFavoritos
                          ? () => _openExercisePicker(
                            allExercicios,
                            alreadyInTreinoIds: alreadyInTreinoIds,
                          )
                          : () => setState(() {
                            _pickerFilter = const ExercisePickerFilter();
                            _buscaCtrl.clear();
                          }),
                ),
              ),
            ],
            if (!showFilterEmpty && curatedSuggestions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _recentIds.isNotEmpty
                    ? 'Seus recentes e mais usados'
                    : 'Mais usados pelos personais',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark
                          ? EagleTokens.darkInkMute
                          : TokensStrip.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _SuggestionList(
                exercicios: curatedSuggestions,
                query: query,
                isDark: isDark,
                primary: primary,
                alreadyInTreinoIds: alreadyInTreinoIds,
                onSelect: _selectExercise,
                onPreview: (ex) {
                  if (!canPreviewExerciseMedia(ex)) return;
                  showExerciseMediaPreview(context, exercicio: ex);
                },
              ),
            ],
            if (!showFilterEmpty &&
                !compact &&
                favoriteShortcuts.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Seus favoritos',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark
                          ? EagleTokens.darkInkMute
                          : TokensStrip.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _SuggestionList(
                exercicios: favoriteShortcuts,
                query: query,
                isDark: isDark,
                primary: primary,
                alreadyInTreinoIds: alreadyInTreinoIds,
                onSelect: _selectExercise,
                onPreview: (ex) {
                  if (!canPreviewExerciseMedia(ex)) return;
                  showExerciseMediaPreview(context, exercicio: ex);
                },
              ),
            ],
            if (!showFilterEmpty && !compact && quickMatches.isNotEmpty) ...[
              const SizedBox(height: 10),
              _SuggestionList(
                exercicios: quickMatches,
                query: query,
                isDark: isDark,
                primary: primary,
                alreadyInTreinoIds: alreadyInTreinoIds,
                onSelect: _selectExercise,
                onPreview: (ex) {
                  if (!canPreviewExerciseMedia(ex)) return;
                  showExerciseMediaPreview(context, exercicio: ex);
                },
              ),
              const SizedBox(height: 8),
            ],
            if (!compact && hasBrowseShortcuts) ...[
              const SizedBox(height: 12),
              _BrowseLibraryCta(
                totalCount: totalLibraryCount,
                libraryLines: libraryLines,
                isDark: isDark,
                primary: primary,
                onOpenPicker:
                    () => _openExercisePicker(
                      allExercicios,
                      alreadyInTreinoIds: alreadyInTreinoIds,
                    ),
                onCreate: _openCreateExercise,
              ),
            ] else if (!compact)
              _ExercisePickerCard(
                exercicio: _selecionado,
                isDark: isDark,
                primary: primary,
                libraryLines: libraryLines,
                compactMode: false,
                showPrescriptionHint: !_prescriptionInView,
                showBrowseHint: !hasBrowseShortcuts,
                onTap:
                    () => _openExercisePicker(
                      allExercicios,
                      alreadyInTreinoIds: alreadyInTreinoIds,
                    ),
                mediaLoading: _mediaLoading,
                videoExpanded: _videoExpanded,
                onToggleVideo:
                    () => setState(() => _videoExpanded = !_videoExpanded),
                onPreviewVideo: _previewSelectedExerciseVideo,
                onUploadVideo: _uploadSelectedExerciseVideo,
                onRemoveVideo: _removeSelectedExerciseVideo,
                onCreate: _openCreateExercise,
              ),
            if (_selecionado != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _openSimilarPicker(allExercicios),
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: primary,
                    size: 18,
                  ),
                  label: Text(
                    'Trocar por similar',
                    style: AppTypography.inter(
                      color: primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }
}

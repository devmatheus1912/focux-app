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
      ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
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
        ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
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

  Future<void> _openSimilarPicker() async {
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

  bool _usesPickerApi() {
    return _buscaQuery.trim().length >= 2 ||
        _pickerFilter.somenteFavoritos ||
        _pickerFilter.somenteComVideo ||
        _pickerFilter.espaco != null ||
        _pickerFilter.equipamento != null;
  }

  ExercicioPickerQuery _buildPickerApiQuery() {
    return ExercicioPickerQuery(
      busca: _buscaQuery.trim().isEmpty ? null : _buscaQuery.trim(),
      espaco: _pickerFilter.espaco,
      equipamento: _pickerFilter.equipamento,
      somenteFavoritos: _pickerFilter.somenteFavoritos,
      somenteComVideo: _pickerFilter.somenteComVideo,
    );
  }

  List<Exercicio> _resolveVisibleExercicios({
    required TreinoPickerHomeBundle home,
    ExercicioPickerPage? pickerPage,
  }) {
    final usesApi = _usesPickerApi() && pickerPage != null;
    final base = usesApi ? pickerPage.content : home.shortcuts;
    return applyExercisePickerFilter(
      base,
      _pickerFilter,
      serverFiltered: usesApi,
    );
  }

  Future<ExercicioPickerPage> _loadPickerPage(String busca, int page) {
    return ref.read(exercicioRepositoryProvider).listarPickerPagina(
      busca: busca.trim().isEmpty ? null : busca.trim(),
      espaco: enumQueryParam(_pickerFilter.espaco),
      equipamento: enumQueryParam(_pickerFilter.equipamento),
      favoritos: _pickerFilter.somenteFavoritos ? true : null,
      hasVideo: _pickerFilter.somenteComVideo ? true : null,
      page: page,
    );
  }

  Future<void> _openExercisePicker({
    required Set<int> alreadyInTreinoIds,
    String? searchPlaceholder,
  }) async {
    HapticFeedback.selectionClick();
    setState(() => _bottomBarHidden = true);
    Exercicio? selected;
    try {
      selected = await showFxBottomSheet<Exercicio>(
        context: context,
        builder:
            (sheetContext) => _ExercisePickerSheet(
              selected: _selecionado,
              alreadyInTreinoIds: alreadyInTreinoIds,
              initialQuery: _buscaQuery,
              searchPlaceholder:
                  searchPlaceholder ?? 'Buscar por nome, músculo ou equipamento',
              onLoadPage: _loadPickerPage,
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
    try {
      return await ref.read(exercicioRepositoryProvider).buscar(exercicioId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _scheduleMediaRefresh(int exercicioId) async {
    for (final delay in [
      const Duration(seconds: 2),
      const Duration(seconds: 5),
    ]) {
      await Future<void>.delayed(delay);
      if (!mounted) return;
      ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
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
      ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
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
    final confirmed = await showFxBottomSheet<bool>(
      context: context,
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
      ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
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
    required int libraryCount,
    int? filteredPickerCount,
    required TreinoPickerUiHints uiHints,
    required bool isDark,
    required Color primary,
    required Set<int> alreadyInTreinoIds,
  }) {
    final libraryLines = exercisePickerLibraryLines(
      filteredCount: libraryCount,
      totalCount: libraryCount,
      filter: _pickerFilter,
    );
    switch (_tabIndex) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
              FxSettingsGroup(
                accent: primary,
                header: 'Atalhos',
                helpTooltip: 'Ajuda sobre explorar exercícios',
                onHelpTap: () => showAddExercicioHelpSheet(context),
                caption: uiHints.libraryCaption,
                children: [
                  FxSettingsTile(
                    icon: Icons.view_agenda_outlined,
                    accent: primary,
                    label: uiHints.templateCtaLabel,
                    subtitle:
                        'Full body, PPL, upper/lower — ${templateSplits.length} modelos prontos.',
                    value: '',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _openTemplateBuilder();
                    },
                  ),
                  if (libraryCount > 0)
                    FxSettingsTile(
                      icon: Icons.library_books_outlined,
                      accent: primary,
                      label: 'Biblioteca completa ($libraryCount)',
                      subtitle: libraryLines.primary,
                      value: '',
                      onTap:
                          () => _openExercisePicker(
                            alreadyInTreinoIds: alreadyInTreinoIds,
                            searchPlaceholder: uiHints.searchPlaceholder,
                          ),
                    ),
                  FxSettingsTile(
                    icon: Icons.add_rounded,
                    accent: primary,
                    label: uiHints.createCtaLabel,
                    subtitle: 'Grave o vídeo de execução para o aluno',
                    value: '',
                    highlight: true,
                    showDivider: false,
                    onTap: _openCreateExercise,
                  ),
                ],
              ),
              const SizedBox(height: FxSettingsLayout.groupGap),
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
              PadraoMovimentoGrid(
                alreadyInTreinoIds: alreadyInTreinoIds,
                pickerFilter: _pickerFilter,
                onAdicionar: _selectExercise,
                onClearFilters:
                    () => setState(
                      () => _pickerFilter = const ExercisePickerFilter(),
                    ),
              ),
            ],
        );
      default:
        final compact = _selecionado != null;
        final query = _buscaQuery.trim().toLowerCase();
        final pickerFiltered =
            _pickerFilter.isActive || query.length >= 2 || _usesPickerApi();
        final filteredCount =
            filteredPickerCount ??
            (pickerFiltered ? exercicios.length : libraryCount);
        final libraryLines = exercisePickerLibraryLines(
          filteredCount: filteredCount,
          totalCount: libraryCount,
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
                quietCta: true,
                onPreview: _previewSelectedExerciseVideo,
                onUpload: _uploadSelectedExerciseVideo,
                onRemove: _removeSelectedExerciseVideo,
                footer: ExerciseVideoSpecTips(isDark: isDark, embedded: true),
              ),
              const SizedBox(height: 10),
            ],
            if (!compact) ...[
              _AddExerciseSectionHeader(
                title: 'Buscar na biblioteca',
                subtitle: 'Digite 2+ letras ou use favoritos e filtros.',
                onHelp: () => showAddExercicioHelpSheet(context),
              ),
              TextField(
                controller: _buscaCtrl,
                decoration: InputDecoration(
                  hintText: uiHints.searchPlaceholder,
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
              if (_pickerFilter.isActive || query.length >= 2) ...[
                const SizedBox(height: 8),
                Text(
                  libraryLines.secondary == null
                      ? libraryLines.primary
                      : '${libraryLines.primary} · ${libraryLines.secondary}',
                  style: FocuxHubTypography.bodyMuted(
                    color:
                        isDark
                            ? EagleTokens.darkInkMute
                            : TokensStrip.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
            if (showFilterEmpty) ...[
              const SizedBox(height: 16),
              FxEmptyState(
                icon: 'search',
                title: buscarTabEmptyTitle(
                  filter: _pickerFilter,
                  query: _buscaQuery,
                ),
                subtitle: buscarTabEmptyMessage(
                  filter: _pickerFilter,
                  totalCount: libraryCount,
                ),
                action: FxEmptyAction(
                  label:
                      _pickerFilter.somenteFavoritos
                          ? 'Ver biblioteca completa'
                          : 'Limpar filtros e busca',
                  onTap:
                      _pickerFilter.somenteFavoritos
                          ? () => _openExercisePicker(
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
                    ? 'Recentes e mais prescritos'
                    : 'Populares na biblioteca',
                style: FocuxHubTypography.bodyMuted(
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
                'Favoritos',
                style: FocuxHubTypography.bodyMuted(
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
            if (!showFilterEmpty && !compact && libraryCount > 0) ...[
              const SizedBox(height: 12),
              _BrowseLibraryCta(
                totalCount: libraryCount,
                libraryLines: libraryLines,
                libraryCaption: uiHints.libraryCaption,
                createLabel: uiHints.createCtaLabel,
                isDark: isDark,
                primary: primary,
                onOpenPicker:
                    () => _openExercisePicker(
                      alreadyInTreinoIds: alreadyInTreinoIds,
                      searchPlaceholder: uiHints.searchPlaceholder,
                    ),
                onCreate: _openCreateExercise,
              ),
            ],
            if (_selecionado != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openSimilarPicker,
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    color: primary,
                    size: 18,
                  ),
                  label: Text(
                    'Trocar por similar',
                    style: FocuxHubTypography.bodyMuted(
                      color: primary,
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

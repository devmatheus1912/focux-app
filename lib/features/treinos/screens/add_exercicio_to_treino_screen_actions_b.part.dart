part of 'add_exercicio_to_treino_screen.dart';

extension AddExercicioToTreinoScreenActionsB
    on _AddExercicioToTreinoScreenState {
  AddExercisePrescriptionInput? _resolvePrescriptionOrSetError() {
    final resolved = resolveAddExercisePrescription(
      seriesText: _seriesCtrl.text,
      repeticoesText: _repCtrl.text,
      descansoText: _descansoCtrl.text,
      cargaText: _cargaCtrl.text,
      observacoesText: _observacoesCtrl.text,
      tipoSerie: _tipoSerie,
      grupoSupersetText: _grupoSupersetCtrl.text,
    );
    if (resolved.error != null) {
      setState(() => _error = resolved.error);
      return null;
    }
    return resolved.values;
  }

  Future<void> _submit() async {
    if (_selecionado == null) {
      setState(() {
        _error = 'Selecione um exercício.';
      });
      return;
    }
    final prescription = _resolvePrescriptionOrSetError();
    if (prescription == null) return;
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
            series: prescription.series,
            repeticoes: prescription.repeticoes,
            descanso: prescription.descansoSegundos,
            cargaKg: prescription.cargaKg,
            observacoes: prescription.observacoes,
            tipoSerie: prescription.tipoSerie,
            grupoSuperset: prescription.grupoSuperset,
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
    final prescription = _resolvePrescriptionOrSetError();
    if (prescription == null) return;
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
            series: prescription.series,
            repeticoes: prescription.repeticoes,
            descanso: prescription.descansoSegundos,
            cargaKg: prescription.cargaKg,
            observacoes: prescription.observacoes,
            tipoSerie: prescription.tipoSerie,
            grupoSuperset: prescription.grupoSuperset,
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
    final prescription = _resolvePrescriptionOrSetError();
    if (prescription == null) return;
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
            series: prescription.series,
            repeticoes: prescription.repeticoes,
            descanso: prescription.descansoSegundos,
            cargaKg: prescription.cargaKg,
            observacoes: prescription.observacoes,
            tipoSerie: prescription.tipoSerie,
            grupoSuperset: prescription.grupoSuperset,
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

  bool _usesPickerApi() => true;

  ExercicioPickerQuery _buildPickerApiQuery() {
    return ExercicioPickerQuery(
      busca: _buscaQuery.trim().isEmpty ? null : _buscaQuery.trim(),
      espaco: _pickerFilter.espaco,
      equipamento: _pickerFilter.equipamento,
      equipamentosAluno:
          _pickerFilter.filtrarPorAluno ? _pickerFilter.equipamentosAluno : const {},
      somenteFavoritos: _pickerFilter.somenteFavoritos,
      somenteComVideo: _pickerFilter.somenteComVideo,
    );
  }

  List<Exercicio> _resolveVisibleExercicios({
    required TreinoPickerHomeBundle home,
    ExercicioPickerPage? pickerPage,
  }) {
    if (pickerPage == null) return const [];
    return applyExercisePickerFilter(
      pickerPage.content,
      _pickerFilter,
      serverFiltered: true,
    );
  }

  Future<ExercicioPickerPage> _loadPickerPage(String busca, int page) {
    return ref.read(exercicioRepositoryProvider).listarPickerPagina(
      busca: busca.trim().isEmpty ? null : busca.trim(),
      espaco: enumQueryParam(_pickerFilter.espaco),
      equipamento: enumQueryParam(_pickerFilter.equipamento),
      equipamentos:
          _pickerFilter.filtrarPorAluno
              ? enumSetQueryParam(_pickerFilter.equipamentosAluno)
              : null,
      favoritos: _pickerFilter.somenteFavoritos ? true : null,
      hasVideo: _pickerFilter.somenteComVideo ? true : null,
      page: page,
    );
  }

  Future<void> _openExercisePicker({
    required Set<int> alreadyInTreinoIds,
    String? searchPlaceholder,
    int? libraryTotalCount,
  }) async {
    HapticFeedback.selectionClick();
    setState(() => _bottomBarHidden = true);
    final homeAsync = ref.read(treinoPickerHomeProvider(widget.treinoId));
    final int total =
        libraryTotalCount ??
        homeAsync.when(
          data: (home) => home.libraryCount,
          loading: () => 0,
          error: (_, __) => 0,
        );
    Exercicio? selected;
    try {
      selected = await showExerciseLibrarySheet(
        context,
        selected: _selecionado,
        alreadyInTreinoIds: alreadyInTreinoIds,
        initialQuery: _buscaQuery,
        searchPlaceholder:
            searchPlaceholder ?? 'Buscar por nome, músculo ou equipamento',
        filter: _pickerFilter,
        libraryTotalCount: total,
        onFilterChanged:
            (ExercisePickerFilter next) =>
                setState(() => _pickerFilter = next),
        onLoadPage: _loadPickerPage,
        onUploadVideo:
            (exercicio) => _uploadExerciseVideo(
              exercicio,
              origin: 'treino_library_sheet',
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

  List<Exercicio> _buscarDisplayExercicios({
    required List<Exercicio> exercicios,
    required String query,
    required Set<int> alreadyInTreinoIds,
  }) {
    final normalized = query.trim().toLowerCase();

    if (normalized.length >= 2) {
      return sortExerciciosForPicker(
        exercicios.where((exercicio) {
          final haystack =
              '${exercicio.nome} ${exercicio.musculoAlvo ?? ''} '
                      '${exercicio.equipamento ?? ''}'
                  .toLowerCase();
          return haystack.contains(normalized);
        }),
        alreadyInTreinoIds: alreadyInTreinoIds,
      ).take(8).toList();
    }

    if (_pickerFilter.isActive) {
      return sortExerciciosForPicker(
        exercicios,
        alreadyInTreinoIds: alreadyInTreinoIds,
      ).take(12).toList();
    }

    final curated = curatedPickerSuggestions(
      exercicios,
      alreadyInTreinoIds: alreadyInTreinoIds,
      recentIds: _recentIds,
    );
    final favorites = sortExerciciosForPicker(
      favoriteExercises(exercicios),
      alreadyInTreinoIds: alreadyInTreinoIds,
    );
    final seen = <int>{};
    final merged = <Exercicio>[];
    for (final exercicio in [...curated, ...favorites]) {
      if (seen.add(exercicio.id)) merged.add(exercicio);
      if (merged.length >= 4) break;
    }
    return merged;
  }

  String? _buscarListTitle({
    required String query,
    required List<Exercicio> displayItems,
  }) {
    if (displayItems.isEmpty) return null;
    final normalized = query.trim();
    if (normalized.length >= 2) return 'Resultados';
    if (_pickerFilter.isActive) return null;
    return _recentIds.isNotEmpty
        ? 'Recentes e mais prescritos'
        : 'Sugestões';
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
              caption:
                  libraryCount > 0
                      ? '$libraryCount exercícios na biblioteca'
                      : uiHints.libraryCaption,
              children: [
                FxSettingsTile(
                  icon: Icons.account_tree_outlined,
                  accent: BrandPalette.softened(primary),
                  label: 'Por movimento',
                  subtitle: 'Empurrar, puxar, agachar, core…',
                  value: '',
                  onTap:
                      () => _openPadraoMovimentoExplorer(alreadyInTreinoIds),
                ),
                FxSettingsTile(
                  icon: Icons.view_agenda_outlined,
                  accent: BrandPalette.softened(primary),
                  label: uiHints.templateCtaLabel,
                  subtitle:
                      'Full body, PPL, upper/lower — ${templateSplits.length} modelos.',
                  value: '',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _openTemplateBuilder();
                  },
                ),
                if (libraryCount > 0)
                  FxSettingsTile(
                    icon: Icons.library_books_outlined,
                    accent: BrandPalette.softened(primary),
                    label: 'Biblioteca completa',
                    subtitle: libraryLines.primary,
                    value: '',
                    onTap:
                        () => _openExercisePicker(
                          alreadyInTreinoIds: alreadyInTreinoIds,
                          searchPlaceholder: uiHints.searchPlaceholder,
                          libraryTotalCount: libraryCount,
                        ),
                  ),
                FxSettingsTile(
                  icon: Icons.add_rounded,
                  accent: BrandPalette.softened(primary),
                  label: uiHints.createCtaLabel,
                  value: '',
                  showDivider: false,
                  onTap: _openCreateExercise,
                ),
              ],
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
        final displayItems = compact
            ? const <Exercicio>[]
            : _buscarDisplayExercicios(
              exercicios: exercicios,
              query: query,
              alreadyInTreinoIds: alreadyInTreinoIds,
            );
        final listTitle = _buscarListTitle(
          query: query,
          displayItems: displayItems,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (compact && _selecionado != null) ...[
              _SelectedExerciseInsetGroup(
                exercicio: _selecionado!,
                primary: primary,
                mediaLoading: _mediaLoading,
                celebrateVideoSuccess: _celebrateVideoSuccess,
                onChange:
                    () => _openExercisePicker(
                      alreadyInTreinoIds: alreadyInTreinoIds,
                      libraryTotalCount: libraryCount,
                    ),
                onPreview: _previewSelectedExerciseVideo,
                onUpload: _uploadSelectedExerciseVideo,
                onRemove: _removeSelectedExerciseVideo,
                onSimilar: _openSimilarPicker,
              ),
            ],
            if (!compact) ...[
              TextField(
                controller: _buscaCtrl,
                decoration: FxInputDeco.build(
                  context,
                  'Buscar exercício',
                  icon: Icons.search_rounded,
                  hint: uiHints.searchPlaceholder,
                ).copyWith(
                  suffixIcon:
                      _buscaQuery.isEmpty
                          ? null
                          : IconButton(
                            onPressed: () => _buscaCtrl.clear(),
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Limpar busca',
                          ),
                ),
              ),
              const SizedBox(height: 10),
              if (_alunoFilterWarning != null) ...[
                _InlineWarningBanner(
                  message: _alunoFilterWarning!,
                  isDark: isDark,
                  primary: primary,
                  onDismiss:
                      () => setState(() => _alunoFilterWarning = null),
                ),
                const SizedBox(height: 8),
              ],
              if (_alunoFilterNome != null &&
                  _pickerFilter.filtrarPorAluno) ...[
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
                const SizedBox(height: 8),
              ],
              ExercisePickerFilterBar(
                filter: _pickerFilter,
                isDark: isDark,
                primary: primary,
                resultCaption:
                    _pickerFilter.isActive || query.length >= 2
                        ? libraryLines
                        : null,
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
                            libraryTotalCount: libraryCount,
                          )
                          : () => setState(() {
                            _pickerFilter = const ExercisePickerFilter();
                            _buscaCtrl.clear();
                          }),
                ),
              ),
            ],
            if (!showFilterEmpty && !compact && displayItems.isNotEmpty) ...[
              if (listTitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  listTitle,
                  style: FocuxHubTypography.bodyMuted(
                    fontWeight: FontWeight.w800,
                    color:
                        isDark
                            ? EagleTokens.darkInkMute
                            : TokensStrip.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _SuggestionList(
                exercicios: displayItems,
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
                displayItems.isEmpty &&
                query.isEmpty &&
                !_pickerFilter.isActive) ...[
              _BuscarIdleHint(primary: primary, isDark: isDark),
            ],
            if (!showFilterEmpty && !compact && libraryCount > 0) ...[
              const SizedBox(height: 12),
              _BuscarQuickLinks(
                totalCount: libraryCount,
                createLabel: uiHints.createCtaLabel,
                primary: primary,
                onOpenPicker:
                    () => _openExercisePicker(
                      alreadyInTreinoIds: alreadyInTreinoIds,
                      searchPlaceholder: uiHints.searchPlaceholder,
                      libraryTotalCount: libraryCount,
                    ),
                onCreate: _openCreateExercise,
              ),
            ],
          ],
        );
    }
  }
}

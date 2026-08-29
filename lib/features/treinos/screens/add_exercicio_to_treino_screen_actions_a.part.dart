part of 'add_exercicio_to_treino_screen.dart';

extension AddExercicioToTreinoScreenActionsA
    on _AddExercicioToTreinoScreenState {
  /// Espaço inferior do scroll para não ficar sob faixas fixas.
  double _scrollBottomInset(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    var inset = 108 + safe;
    if (_tabIndex == 0 && _selecionado != null && !_bottomBarHidden) {
      inset += 118;
    }
    return inset;
  }

  void _openPrescriptionEditor() {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = ShellChrome.of(context).ink;
    showFxHomeSheet<void>(
      context,
      builder:
          (ctx) => _PrescriptionEditorSheet(
            isDark: isDark,
            primary: primary,
            ink: ink,
            presetId: _presetId,
            tipoSerie: _tipoSerie,
            globalPresetMode: _selecionado == null,
            lastPrescription: _lastPrescription,
            seriesCtrl: _seriesCtrl,
            repCtrl: _repCtrl,
            descansoCtrl: _descansoCtrl,
            cargaCtrl: _cargaCtrl,
            observacoesCtrl: _observacoesCtrl,
            grupoSupersetCtrl: _grupoSupersetCtrl,
            onPresetSelected: _applyPreset,
            onTipoSerieChanged:
                (value) => setState(() => _tipoSerie = value),
            onApplyLastPrescription: _applyLastPrescription,
          ),
    );
  }

  void _openPadraoMovimentoExplorer(Set<int> alreadyInTreinoIds) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    showFxHomeSheet<void>(
      context,
      builder:
          (ctx) => FxHomeSheetSurface(
            isDark: isDark,
            maxHeight:
                MediaQuery.sizeOf(ctx).height *
                FxHomeSheetChrome.expandHeightFactor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FxHomeSheetHandle(isDark: isDark),
                FxHomeSheetHeader(
                  isDark: isDark,
                  title: 'Por movimento',
                  subtitle: 'Empurrar, puxar, agachar, core…',
                  leading: Icon(
                    Icons.account_tree_outlined,
                    color: primary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.groupPadH,
                      0,
                      FxSettingsLayout.groupPadH,
                      FxSettingsLayout.footerAfterGroup,
                    ),
                    child: PadraoMovimentoGrid(
                      alreadyInTreinoIds: alreadyInTreinoIds,
                      onAdicionar: (exercicio) {
                        Navigator.pop(ctx);
                        _adicionarRapido(exercicio);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _applyAlunoEquipmentFilter() async {
    final alunoId = widget.alunoId;
    if (alunoId == null) return;
    try {
      final aluno = await ref.read(alunoProvider(alunoId).future);
      if (!mounted || aluno.equipamentosDisponiveis.isEmpty) return;
      setState(() {
        _alunoFilterNome = aluno.nome;
        _pickerFilter = ExercisePickerFilter.fromAlunoEquipamentos(
          aluno.equipamentosDisponiveis,
        );
      });
    } catch (_) {
      // Mantém filtros manuais se o perfil do aluno não carregar.
    }
  }

  void _triggerVideoUploadCelebration() {
    _celebrateVideoTimer?.cancel();
    setState(() => _celebrateVideoSuccess = true);
    _celebrateVideoTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _celebrateVideoSuccess = false);
    });
  }

  Future<void> _loadPickerMemory() async {
    final recent = await RecentExerciseUsageStore.recentIds();
    final last = await ExercisePrescriptionMemoryStore.load();
    if (!mounted) return;
    setState(() {
      _recentIds = recent;
      _lastPrescription = last;
    });
  }

  Future<void> _persistAfterAdd(int exercicioId) async {
    await RecentExerciseUsageStore.recordUsage(exercicioId);
    final memory = _currentPrescriptionMemory();
    await ExercisePrescriptionMemoryStore.save(memory);
    if (!mounted) return;
    setState(() => _lastPrescription = memory);
    final recent = await RecentExerciseUsageStore.recentIds();
    if (!mounted) return;
    setState(() => _recentIds = recent);
  }

  ExercisePrescriptionMemory _currentPrescriptionMemory() {
    return ExercisePrescriptionMemory(
      presetId: _presetId,
      series: int.tryParse(_seriesCtrl.text) ?? 3,
      repeticoes: _repCtrl.text,
      descansoSegundos: int.tryParse(_descansoCtrl.text) ?? 60,
      tipoSerie: _tipoSerie,
      cargaKg: double.tryParse(_cargaCtrl.text.replaceAll(',', '.')),
      observacoes: _observacoesCtrl.text,
      grupoSuperset:
          _tipoSerie == 'SUPERSET'
              ? int.tryParse(_grupoSupersetCtrl.text)
              : null,
    );
  }

  void _applyLastPrescription() {
    final memory = _lastPrescription;
    if (memory == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _applyPreset(memory.presetId, notify: false);
      _seriesCtrl.text = memory.series.toString();
      _repCtrl.text = memory.repeticoes;
      _descansoCtrl.text = memory.descansoSegundos.toString();
      _tipoSerie = memory.tipoSerie;
      _observacoesCtrl.text = memory.observacoes;
      if (memory.cargaKg != null) {
        _cargaCtrl.text = memory.cargaKg!.toString();
      } else {
        _cargaCtrl.clear();
      }
      if (memory.grupoSuperset != null) {
        _grupoSupersetCtrl.text = memory.grupoSuperset.toString();
      }
    });
  }

  Future<void> _ensureBiblioteca() async {
    await BibliotecaBootstrap.ensureReady(context);
    if (!mounted) return;
    final selectedId = _selecionado?.id;
    if (selectedId == null) return;
    ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
    final home =
        await ref.read(treinoPickerHomeProvider(widget.treinoId).future);
    Exercicio? fresh;
    for (final exercicio in home.exercicios) {
      if (exercicio.id == selectedId) {
        fresh = exercicio;
        break;
      }
    }
    if (fresh != null && mounted) {
      setState(() => _selecionado = fresh);
    }
  }

  Set<int> _treinoExercicioIds(AsyncValue<Treino> treinoAsync) {
    return treinoAsync.maybeWhen(
      data:
          (treino) =>
              treino.exercicios.map((item) => item.exercicio.id).toSet(),
      orElse: () => const <int>{},
    );
  }

  void _selectExercise(Exercicio exercicio) {
    setState(() {
      _selecionado = exercicio;
      _tabIndex = 0;
      _error = null;
    });
  }

  Future<void> _openCreateExercise() async {
    final criado = await context.push<bool>('/exercicios/novo');
    if (criado == true && mounted) {
      ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
      ref.invalidate(exerciciosProvider);
    }
  }

  Future<void> _openTemplateBuilder() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (_) => FxShellScaffold(
              useMesh: true,
              appBar: FxShellAppBar(
                title: 'Montar por modelo',
                subtitle: 'Preencha o treino com modelos prontos',
                onBack: () => Navigator.pop(context),
              ),
              body: TemplateSplitPicker(
                alreadyInTreinoIds: _treinoExercicioIds(
                  ref
                      .read(treinoPickerHomeProvider(widget.treinoId))
                      .whenData((h) => h.treino),
                ),
                onAdicionar: (exercicio) async {
                  await _adicionarRapido(exercicio);
                  AnalyticsService.instance.track(
                    'template_uso',
                    props: {'treinoId': widget.treinoId, 'exId': exercicio.id},
                  );
                },
              ),
            ),
      ),
    );
    if (mounted) {
      ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
      ref.invalidate(treinoProvider(widget.treinoId));
    }
  }

  void _applyPreset(String id, {bool notify = true}) {
    final preset = workoutBuilderPresetById(id);
    void apply() {
      _presetId = id;
      _seriesCtrl.text = preset.series.toString();
      _repCtrl.text = preset.repeticoes;
      _descansoCtrl.text = preset.descansoSegundos.toString();
      _tipoSerie = preset.tipoSerie;
      _observacoesCtrl.text = preset.observacoes;
      if (preset.grupoSuperset != null) {
        _grupoSupersetCtrl.text = preset.grupoSuperset.toString();
      }
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }
}

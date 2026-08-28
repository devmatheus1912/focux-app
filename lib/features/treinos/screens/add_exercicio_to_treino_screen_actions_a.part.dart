part of 'add_exercicio_to_treino_screen.dart';

extension AddExercicioToTreinoScreenActionsA
    on _AddExercicioToTreinoScreenState {
  void _syncPrescriptionVisibility() {
    if (_selecionado == null) {
      if (_prescriptionInView) {
        setState(() => _prescriptionInView = false);
      }
      return;
    }
    final ctx = _prescriptionAnchor.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;

    final top = box.localToGlobal(Offset.zero).dy;
    final threshold = MediaQuery.sizeOf(ctx).height * 0.62;
    final inView = top < threshold;
    if (inView != _prescriptionInView) {
      setState(() => _prescriptionInView = inView);
    }
  }

  bool get _showPrescriptionPanel =>
      _tabIndex == 0 && (_selecionado != null || _prescriptionEditorOpen);

  void _openPrescriptionEditor() {
    HapticFeedback.selectionClick();
    setState(() {
      _tabIndex = 0;
      _prescriptionEditorOpen = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _prescriptionAnchor.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        alignment: 0.06,
      );
      _syncPrescriptionVisibility();
    });
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
      _prescriptionEditorOpen = true;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _prescriptionAnchor.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      _syncPrescriptionVisibility();
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
                subtitle: 'Preencha os slots do treino com modelos prontos',
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

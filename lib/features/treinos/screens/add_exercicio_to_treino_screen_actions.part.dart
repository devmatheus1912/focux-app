part of 'add_exercicio_to_treino_screen.dart';

extension _AddExercicioToTreinoScreenActions
    on _AddExercicioToTreinoScreenState {
  String _prescriptionSummaryLine() {
    final preset = workoutBuilderPresetById(_presetId);
    return formatActivePrescriptionLine(
      presetLabel: preset.label,
      series: _seriesCtrl.text,
      repeticoes: _repCtrl.text,
      descansoSegundos: _descansoCtrl.text,
      tipoSerie: _tipoSerie,
    );
  }

  Widget? _alunoFilterHeader(bool isDark, Color primary) {
    if (_alunoFilterWarning != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _BibliotecaSyncBanner(
          message: _alunoFilterWarning!,
          isDark: isDark,
          primary: primary,
          showProgress: false,
          warning: true,
          embedded: true,
          onDismiss: () => setState(() => _alunoFilterWarning = null),
        ),
      );
    }
    if (_alunoFilterNome != null && _pickerFilter.filtrarPorAluno) {
      return _AlunoEquipmentFilterBanner(
        alunoNome: _alunoFilterNome!,
        equipamentos: _pickerFilter.equipamentosAluno,
        isDark: isDark,
        primary: primary,
        onClear:
            () => setState(
              () => _pickerFilter = _pickerFilter.copyWith(clearAluno: true),
            ),
      );
    }
    return null;
  }

  void _openPrescriptionEditor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final ink = ShellChrome.of(context).ink;
    showPrescriptionEditorSheet(
      context,
      isDark: isDark,
      primary: primary,
      ink: ink,
      presetId: _presetId,
      tipoSerie: _tipoSerie,
      globalPresetMode: true,
      lastPrescription: _lastPrescription,
      seriesCtrl: _seriesCtrl,
      repCtrl: _repCtrl,
      descansoCtrl: _descansoCtrl,
      cargaCtrl: _cargaCtrl,
      rpeAlvoCtrl: _rpeAlvoCtrl,
      observacoesCtrl: _observacoesCtrl,
      grupoSupersetCtrl: _grupoSupersetCtrl,
      onPresetSelected: _applyPreset,
      onTipoSerieChanged: (value) => setState(() => _tipoSerie = value),
      onApplyLastPrescription: _applyLastPrescription,
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
        _alunoFilterWarning = null;
        _pickerFilter = ExercisePickerFilter.fromAlunoEquipamentos(
          aluno.equipamentosDisponiveis,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _alunoFilterWarning =
            'Não carregamos o equipamento do aluno. Filtre manualmente.';
      });
    }
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
  }

  Set<int> _treinoExercicioIds(AsyncValue<Treino> treinoAsync) {
    return treinoAsync.maybeWhen(
      data:
          (treino) =>
              treino.exercicios.map((item) => item.exercicio.id).toSet(),
      orElse: () => const <int>{},
    );
  }

  Future<void> _openCreateExercise() async {
    final criado = await context.push<bool>('/exercicios/novo');
    if (criado == true && mounted) {
      ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
      ref.invalidate(exerciciosProvider);
      ref.invalidate(exercicioPickerStatsProvider);
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
      // Observações ficam com o personal — tip de coaching do preset não polui o sheet.
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

  AddExercisePrescriptionInput? _resolvePrescriptionOrSetError() {
    final resolved = resolveAddExercisePrescription(
      seriesText: _seriesCtrl.text,
      repeticoesText: _repCtrl.text,
      descansoText: _descansoCtrl.text,
      cargaText: _cargaCtrl.text,
      rpeAlvoText: _rpeAlvoCtrl.text,
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

  Future<void> _adicionarRapido(Exercicio exercicio) async {
    if (_loading) return;
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
            rpeAlvo: prescription.rpeAlvo,
            observacoes: prescription.observacoes,
            tipoSerie: prescription.tipoSerie,
            grupoSuperset: prescription.grupoSuperset,
          );
      await _persistAfterAdd(exercicioId);
      AnalyticsService.instance.track(
        'quick_add_exercicio',
        props: {'exId': exercicio.id, 'treinoId': widget.treinoId},
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
        ref.invalidate(treinoProvider(widget.treinoId));
        FeedbackHelper.showSuccess(
          context,
          '${exercicio.nomeDisplay} adicionado.',
        );
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

  Future<ExercicioPickerPage> _loadPickerPage({
    required String busca,
    required int page,
    required ExercisePickerFilter filter,
    PadraoMovimento? padrao,
    GrupoMuscular? grupo,
  }) {
    return ref.read(
      exercicioPickerPageProvider(
        ExercicioPickerQuery(
          busca: busca.trim().isEmpty ? null : busca.trim(),
          padraoMovimento: padrao,
          grupoMuscularPrimario: grupo,
          espaco: filter.espaco,
          equipamento: filter.equipamento,
          equipamentosAluno:
              filter.filtrarPorAluno ? filter.equipamentosAluno : const {},
          somenteFavoritos: filter.somenteFavoritos,
          somenteComVideo: filter.somenteComVideo,
          page: page,
        ),
      ).future,
    );
  }
}

class _PrescriptionActiveStrip extends StatelessWidget {
  const _PrescriptionActiveStrip({
    required this.summary,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final String summary;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BrandPalette.softened(primary);
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        8,
        FxSettingsLayout.pageInset,
        0,
      ),
      child: Semantics(
        button: true,
        label: 'Prescrição padrão: $summary. Toque para editar.',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(14),
            child: DecoratedBox(
              decoration: activePrescriptionStripDecoration(
                brand: brand,
                isDark: isDark,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded, color: brand, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Prescrição padrão',
                            style: activePrescriptionCaptionStyle(mute: mute),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: activePrescriptionLineStyle(brand: brand),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: mute,
                      size: FxSettingsLayout.chevronSize,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BibliotecaSyncBanner extends StatelessWidget {
  const _BibliotecaSyncBanner({
    required this.message,
    required this.isDark,
    required this.primary,
    this.showProgress = true,
    this.warning = false,
    this.embedded = false,
    this.onDismiss,
  });

  final String message;
  final bool isDark;
  final Color primary;
  final bool showProgress;
  final bool warning;
  final bool embedded;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          embedded
              ? EdgeInsets.zero
              : const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                8,
                FxSettingsLayout.pageInset,
                0,
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              warning
                  ? EagleTokens.warn.withValues(alpha: isDark ? 0.16 : 0.1)
                  : primary.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                warning
                    ? EagleTokens.warn.withValues(alpha: 0.28)
                    : primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showProgress)
              SizedBox(
                width: 16,
                height: 16,
                child: FxLoading(size: 16, strokeWidth: 2, color: primary),
              )
            else
              Icon(
                warning ? Icons.info_outline_rounded : Icons.sync_rounded,
                color: warning ? EagleTokens.warn : primary,
                size: 18,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: FocuxHubTypography.bodyMuted(
                  color: isDark ? EagleTokens.darkInk : TokensStrip.textPrimary,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                tooltip: 'Dispensar',
                icon: const Icon(Icons.close_rounded, size: 16),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}

class _AlunoEquipmentFilterBanner extends StatelessWidget {
  const _AlunoEquipmentFilterBanner({
    required this.alunoNome,
    required this.equipamentos,
    required this.isDark,
    required this.primary,
    required this.onClear,
  });

  final String alunoNome;
  final Set<Equipamento> equipamentos;
  final bool isDark;
  final Color primary;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
    final labels = equipamentos
        .map((e) => TaxonomyLabels.equipamento[e] ?? e.name)
        .take(3)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline_rounded, color: primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Equipamento de $alunoNome: $labels',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FocuxHubTypography.bodyMuted(
                  color: mute,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: Text(
                'Limpar',
                style: FocuxHubTypography.bodyMuted(
                  color: primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

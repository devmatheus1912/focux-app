part of 'add_exercicio_to_treino_screen.dart';

// A faixa global saiu. Os métodos antigos ficam até a próxima limpeza do arquivo.
// ignore_for_file: unused_element

extension _AddExercicioToTreinoScreenActions
    on _AddExercicioToTreinoScreenState {
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
    final recent = await RecentExerciseUsageStore.recentesIds();
    final mais = await RecentExerciseUsageStore.maisUsadosIds();
    final last = await ExercisePrescriptionMemoryStore.load();
    if (!mounted) return;
    setState(() {
      _recentIds = recent;
      _maisUsadosIds = mais;
      _lastPrescription = last;
    });
  }

  Future<void> _persistAfterAdd(int exercicioId) async {
    await RecentExerciseUsageStore.recordUsage(exercicioId);
    final memory = _currentPrescriptionMemory();
    await ExercisePrescriptionMemoryStore.save(memory);
    if (!mounted) return;
    setState(() => _lastPrescription = memory);
    await _recarregarUso();
  }

  Future<void> _recarregarUso() async {
    final recent = await RecentExerciseUsageStore.recentesIds();
    final mais = await RecentExerciseUsageStore.maisUsadosIds();
    if (!mounted) return;
    setState(() {
      _recentIds = recent;
      _maisUsadosIds = mais;
    });
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
    final criado = await context.push<ExercicioCriado>(
      '/exercicios/novo?origem=treino',
    );
    if (criado == null || !mounted) return;
    ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
    ref.invalidate(exerciciosProvider);
    ref.invalidate(exercicioPickerStatsProvider);
    switch (criado.destino) {
      case ExercicioCriadoDestino.adicionarAoTreino:
        await _adicionarRapido(Exercicio(id: criado.id, nome: criado.nome));
      case ExercicioCriadoDestino.criarOutro:
        await _openCreateExercise();
      case ExercicioCriadoDestino.verEmMeus:
        await context.push('/exercicios');
      case ExercicioCriadoDestino.ficar || ExercicioCriadoDestino.usarNoLugar:
        break;
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

  /// "3 × 10-12" de cada exercício que já está no treino.
  Map<int, String> _resumoNoTreino(AsyncValue<Treino> treinoAsync) {
    return treinoAsync.maybeWhen(
      data: (treino) => {
        for (final item in treino.exercicios)
          item.exercicio.id: '${item.series} × ${item.repeticoes}',
      },
      orElse: () => const <int, String>{},
    );
  }

  Future<void> _adicionarRapido(Exercicio exercicio) async {
    if (_loading) return;
    final bloco = widget.bloco;
    final treinoAtual = ref
        .read(treinoPickerHomeProvider(widget.treinoId))
        .whenData((h) => h.treino)
        .value;
    final jaNoTreino = treinoAtual?.exercicios
        .where((e) => e.exercicio.id == exercicio.id)
        .toList();
    if (jaNoTreino != null && jaNoTreino.isNotEmpty) {
      final escolha = await showFxGroupedActionSheet<String>(
        context,
        titulo: exercicio.nomeDisplay,
        subtitulo: 'Já está neste treino',
        icone: Icons.fitness_center_rounded,
        grupos: [
          FxActionGroup<String>(null, [
            FxActionItem(
              valor: 'ajustar',
              rotulo: 'Ajustar prescrição',
              icone: Icons.edit_note_rounded,
            ),
            FxActionItem(
              valor: 'repetir',
              rotulo: 'Adicionar de novo',
              descricao: 'Entra como outra linha do treino',
              icone: Icons.control_point_duplicate_rounded,
            ),
          ]),
        ],
      );
      if (!mounted || escolha == null) return;
      if (escolha == 'ajustar') {
        final item = jaNoTreino.last;
        final salvou = await showPrescricaoDoItem(
          context,
          treinoId: widget.treinoId,
          item: item,
          repo: ref.read(treinoRepositoryProvider),
          outrosNoBloco: [
            for (final e in treinoAtual!.exercicios)
              if (e.id != item.id && e.bloco == item.bloco) e,
          ],
        );
        if (salvou == true && mounted) {
          ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
          ref.invalidate(treinoProvider(widget.treinoId));
        }
        return;
      }
    }
    final deste = await ExercisePrescriptionMemoryStore.loadFor(
      exercicio.id,
      bloco: bloco,
    );
    final global = usaMemoriaGlobal(bloco)
        ? await ExercisePrescriptionMemoryStore.loadGlobalSeries()
        : null;
    final padrao = padraoDoBloco(bloco);
    // Memória do exercício vence o padrão do bloco; a global só vale no trabalho.
    final linhas = deste == null && global == null
        ? padrao.linhas
        : seriesIniciais(desteExercicio: deste, ultimaGlobal: global);
    final validas = linhas.where((linha) => !linha.aquecimento).toList();
    final base = validas.isEmpty ? linhas.first : validas.first;
    final descanso = usaMemoriaGlobal(bloco)
        ? prescricaoHipertrofiaDescanso
        : padrao.descansoSegundos;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final treino = await ref
          .read(treinoRepositoryProvider)
          .adicionarExercicio(
            widget.treinoId,
            exercicio.id,
            series: linhas.length,
            repeticoes: base.repeticoes,
            descanso: descanso,
            cargaKg: base.cargaKg,
            bloco: bloco,
          );
      final item = treino.exercicios
          .where((linha) => linha.exercicio.id == exercicio.id)
          .fold<TreinoExercicioItem?>(null, (atual, linha) => atual == null || linha.id > atual.id ? linha : atual);
      // O servidor já cria as séries iguais (mesma repetição e carga). Só
      // precisa da segunda chamada quando há aquecimento ou séries diferentes.
      final uniformes = linhas.every(
        (l) =>
            !l.aquecimento &&
            l.repeticoes == base.repeticoes &&
            l.cargaKg == base.cargaKg,
      );
      if (item != null && !uniformes) {
        await ref.read(treinoRepositoryProvider).salvarSeries(
          widget.treinoId,
          item.id,
          linhas: linhas,
          bloco: bloco,
          descansoSegundos: descanso,
        );
      }
      await ExercisePrescriptionMemoryStore.saveFor(exercicio.id, linhas, bloco: bloco);
      await RecentExerciseUsageStore.recordUsage(exercicio.id);
      AnalyticsService.instance.track(
        'quick_add_exercicio',
        props: {'exId': exercicio.id, 'treinoId': widget.treinoId, 'bloco': bloco},
      );
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _adicionados++;
          _ultimo =
              item == null
                  ? null
                  : _UltimoAdicionado(
                    itemId: item.id,
                    nome: exercicio.nomeDisplay,
                    chave: ++_ultimoSeq,
                  );
        });
        ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
        ref.invalidate(treinoProvider(widget.treinoId));
        unawaited(_recarregarUso());
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = friendlyError(error, fallback: 'Não adicionou o exercício.'));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Prévia da mídia com a ação fixa "Adicionar ao Treino A" (ou, se já está
  /// no treino, "Ajustar prescrição").
  Future<void> _abrirPrevia(Exercicio exercicio) {
    final treino = ref
        .read(treinoPickerHomeProvider(widget.treinoId))
        .whenData((h) => h.treino)
        .value;
    final jaNoTreino =
        treino?.exercicios.any((e) => e.exercicio.id == exercicio.id) ?? false;
    final nome = treino == null ? 'treino' : displayWorkoutName(treino.nome);
    return showExerciseMediaPreview(
      context,
      exercicio: exercicio,
      rodape: Builder(
        builder:
            (sheetContext) => FxLiquidPrimaryButton(
              label:
                  jaNoTreino
                      ? 'Já está no treino · Ajustar'
                      : 'Adicionar ao $nome',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                _adicionarRapido(exercicio);
              },
            ),
      ),
    );
  }

  /// Remove o exercício recém-adicionado (faixa "Adicionado · Desfazer").
  Future<void> _desfazerUltimo() async {
    final ultimo = _ultimo;
    if (ultimo == null || _loading) return;
    setState(() {
      _ultimo = null;
      _loading = true;
    });
    try {
      await ref
          .read(treinoRepositoryProvider)
          .removerExercicio(widget.treinoId, ultimo.itemId);
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() {
        if (_adicionados > 0) _adicionados--;
      });
      ref.invalidate(treinoPickerHomeProvider(widget.treinoId));
      ref.invalidate(treinoProvider(widget.treinoId));
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = friendlyError(
            error,
            fallback: 'Não conseguimos desfazer. Remova pelo treino.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
          // Equipamentos escolhidos à mão valem sobre os do aluno.
          equipamentosAluno:
              filter.equipamentos.isNotEmpty
                  ? filter.equipamentos
                  : (filter.filtrarPorAluno
                      ? filter.equipamentosAluno
                      : const {}),
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

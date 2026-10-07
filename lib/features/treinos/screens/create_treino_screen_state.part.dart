part of 'create_treino_screen.dart';

class _CreateTreinoScreenState extends ConsumerState<CreateTreinoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  final _nomeFocusNode = FocusNode();
  final _nomeFieldKey = GlobalKey();
  final _formNonce = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  String? _nivel;
  bool _loading = false;
  String? _error;

  /// Treino já criado cuja atribuição ao aluno falhou: reenviar só atribui.
  int? _treinoCriadoId;

  @override
  void initState() {
    super.initState();
    _nomeCtrl.addListener(_onFormChanged);
    _objetivoCtrl.addListener(_onFormChanged);
    _descricaoCtrl.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  bool get _dirty =>
      _nomeCtrl.text.trim().isNotEmpty ||
      _objetivoCtrl.text.trim().isNotEmpty ||
      _descricaoCtrl.text.trim().isNotEmpty ||
      _nivel != null;

  CreateTreinoSaida get _saida => CreateTreinoLogic.saida(
    preenchido: _dirty,
    treinoCriado: _treinoCriadoId != null,
  );

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    final s = S.of(context);
    final saida = _saida;
    final aviso = switch (saida) {
      CreateTreinoSaida.livre => null,
      CreateTreinoSaida.descartar => (
        titulo: 'Descartar treino?',
        texto: 'O que você preencheu não será salvo.',
        confirmar: 'Descartar',
      ),
      CreateTreinoSaida.treinoSemAluno => (
        titulo: s.treinoSairSemAtribuirTitulo,
        texto: s.treinoSairSemAtribuirTexto,
        confirmar: s.treinoSairSemAtribuir,
      ),
    };
    if (aviso != null) {
      final ok = await showFxConfirmSheet(
        context,
        title: aviso.titulo,
        message: aviso.texto,
        confirmLabel: aviso.confirmar,
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/treinos');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _objetivoCtrl.dispose();
    _nomeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FxKeyboardDismissScope.dismiss();
    if (_treinoCriadoId == null && !_formKey.currentState!.validate()) {
      _nomeFocusNode.requestFocus();
      final fieldContext = _nomeFieldKey.currentContext;
      if (fieldContext != null) {
        await Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.2,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    try {
      final repo = ref.read(treinoRepositoryProvider);
      var treinoId = _treinoCriadoId;
      if (treinoId == null) {
        treinoId = (await repo.criar(
          _nomeCtrl.text.trim(),
          _descricaoCtrl.text.trim(),
          _objetivoCtrl.text.trim(),
          _nivel,
          offlineQueue: widget.alunoId == null,
          formNonce: _formNonce,
        )).id;
        invalidateTreinosCaches(ref);
      }
      if (widget.alunoId != null) {
        _treinoCriadoId = treinoId;
        await repo.atribuirAluno(treinoId, widget.alunoId!);
        invalidateTreinosDoAluno(ref, widget.alunoId!);
        invalidateTreinosCaches(ref);
      }
      ref.invalidate(treinoProvider(treinoId));
      if (mounted) {
        HapticFeedback.heavyImpact();
        // pushReplacement evita pop+push (tela branca / freeze no go_router).
        context.pushReplacement(
          '/treinos/$treinoId/exercicios/add',
          extra:
              TreinoRouteExtra(
                alunoId: widget.alunoId,
                alunoNome: widget.alunoNome,
                recemCriado: true,
              ).toExtra(),
        );
      }
    } on OfflineQueuedException {
      if (mounted) leaveWithQueuedNotice(context, '/treinos');
    } catch (e) {
      if (mounted) {
        final s = S.of(context);
        final criado = _treinoCriadoId != null;
        final erro = friendlyError(
          e,
          fallback:
              criado ? s.treinoAtribuirFalhouFallback : 'Erro ao criar treino.',
        );
        setState(() {
          _error = criado ? s.treinoAtribuirFalhouTexto(erro) : erro;
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

  Future<void> _usarPlanoSalvo() async {
    FxKeyboardDismissScope.dismiss();
    final s = S.of(context);
    final repo = ref.read(treinoRepositoryProvider);
    final alunoId = widget.alunoId;
    var jaVinculados = <int>{};
    if (alunoId != null) {
      try {
        final page = await repo.listarTreinosDoAlunoPagina(alunoId, size: 100);
        jaVinculados = page.treinos.map((t) => t.id).toSet();
      } catch (_) {}
      if (!mounted) return;
    }
    final plano = await showTreinoSalvoPicker(
      context,
      excluirIds: jaVinculados,
    );
    if (plano == null || !mounted) return;

    bool? copiar;
    if (alunoId != null) {
      copiar = await showFxInsetPickerSheet<bool>(
        context,
        title: s.treinoPlanoSalvoComoAplicar,
        headerIcon: Icons.person_add_alt_1_rounded,
        items: [
          FxInsetPickerSheetItem(
            value: true,
            label: s.treinoPlanoSalvoCopiar,
            subtitle: s.treinoDetalheCopiarSubtitulo,
            icon: Icons.copy_rounded,
          ),
          FxInsetPickerSheetItem(
            value: false,
            label: s.treinoPlanoSalvoVincular,
            subtitle: s.treinoDetalheAtribuirSubtitulo,
            icon: Icons.link_rounded,
          ),
        ],
      );
      if (copiar == null || !mounted) return;
    }

    setState(() => _loading = true);
    try {
      if (alunoId == null) {
        final base = await repo.duplicar(plano.id);
        invalidateTreinosCaches(ref);
        if (!mounted) return;
        context.pushReplacement(
          '/treinos/${base.id}',
          extra: const TreinoRouteExtra(recemCriado: true).toExtra(),
        );
        return;
      }
      if (copiar!) {
        final copia = await repo.clonarParaAluno(plano.id, alunoId);
        invalidateTreinosCaches(ref);
        invalidateTreinosDoAluno(ref, alunoId);
        if (!mounted) return;
        FeedbackHelper.showSuccess(context, s.treinoPlanoSalvoCopiado);
        context.pushReplacement(
          '/treinos/${copia.id}',
          extra:
              TreinoRouteExtra(
                alunoId: alunoId,
                alunoNome: widget.alunoNome,
              ).toExtra(),
        );
        return;
      }
      await repo.atribuirAluno(plano.id, alunoId);
      invalidateTreinosCaches(ref);
      invalidateTreinosDoAluno(ref, alunoId);
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, s.treinoPlanoSalvoVinculado);
      if (context.canPop()) {
        context.pop(true);
      } else {
        safePopOrGo(context, '/treinos');
      }
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showApiFailure(
        context,
        e,
        fallback:
            alunoId == null
                ? s.treinoPlanoSalvoDuplicarFalhou
                : s.treinoPlanoSalvoAplicarFalhou,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyPreset(TreinoCreatePreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _objetivoCtrl.text = preset.title;
      if (_nomeCtrl.text.trim().isEmpty) {
        _nomeCtrl.text = displayWorkoutName('Treino ${preset.title}');
      }
      _nivel ??= 'INTERMEDIARIO';
    });
  }

  Future<void> _openNivelPicker() {
    return showCreateTreinoNivelPicker(
      context,
      selected: _nivel,
      onSelected: (value) => setState(() => _nivel = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final s = S.of(context);
    final soAtribuir = _treinoCriadoId != null;
    final canSubmit =
        (soAtribuir || _nomeCtrl.text.trim().isNotEmpty) && !_loading;
    final selectedPreset = CreateTreinoLogic.matchingPresetTitle(
      _objetivoCtrl.text,
    );
    final hasNome = _nomeCtrl.text.trim().isNotEmpty;
    final previewTitle =
        hasNome
            ? displayWorkoutName(_nomeCtrl.text.trim())
            : 'Plano sem nome';
    final previewMeta = CreateTreinoLogic.previewMeta(
      objetivo: _objetivoCtrl.text,
      nivel: _nivel,
    );

    return fxScreenA11yScope(
      label: widget.alunoId == null ? 'Novo treino' : 'Treino vinculado',
      child: FxFormPopGuard(
        dirty: _saida != CreateTreinoSaida.livre,
        onCancel: _cancel,
        child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: widget.alunoId == null ? 'Novo Treino' : 'Treino vinculado',
          subtitle:
              widget.alunoId != null
                  ? widget.alunoNome?.trim().isNotEmpty == true
                      ? widget.alunoNome!.trim()
                      : 'Vincular ao aluno'
                  : null,
          leadingWidth: 92,
          leading: TextButton(
            onPressed: _cancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancelar'),
          ),
          actions: [
            FxHelpIconButton(
              tooltip: 'Ajuda sobre novo treino',
              onTap: () => showCreateTreinoHelpSheet(context),
            ),
            const SizedBox(width: TokensStrip.s2),
          ],
        ),
        bottomNavigationBar: FxFormStickyBar(
          child: Semantics(
            button: true,
            enabled: canSubmit,
            label:
                soAtribuir
                    ? (_loading ? s.treinoAtribuindo : s.treinoTentarAtribuir)
                    : _loading
                    ? 'Criando treino'
                    : canSubmit
                    ? 'Criar treino'
                    : 'Criar treino. Informe o nome para habilitar',
            child: FxLiquidPrimaryButton(
              label: soAtribuir ? s.treinoTentarAtribuir : 'Criar',
              loading: _loading,
              loadingLabel: soAtribuir ? s.treinoAtribuindo : 'Criando…',
              onPressed: canSubmit ? _submit : null,
            ),
          ),
        ),
        body: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  6,
                  FxSettingsLayout.pageInset,
                  24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FxStaggerItem(
                        index: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FxSettingsGroup(
                              header: 'Modelos rápidos',
                              caption:
                                  'Toque em um modelo para pré-preencher nome e objetivo.',
                              accent: primary,
                              edgeToEdgeRows: true,
                              children: FxInsetPickerOption.list(
                                accent: soft,
                                items: [
                                  for (final preset
                                      in CreateTreinoLogic.presets)
                                    FxInsetPickerOptionSpec(
                                      label: preset.title,
                                      subtitle: preset.subtitle,
                                      icon: preset.icon,
                                      selected:
                                          selectedPreset == preset.title,
                                      onTap: () => _applyPreset(preset),
                                    ),
                                ],
                              ),
                            ),
                            if (!soAtribuir) ...[
                              const SizedBox(
                                height: FxSettingsLayout.groupGap,
                              ),
                              FxSettingsGroup(
                                accent: primary,
                                children: [
                                  FxSettingsTile(
                                    icon: Icons.grid_view_rounded,
                                    accent: soft,
                                    label: s.treinoPlanoSalvoUsar,
                                    subtitle: s.treinoPlanoSalvoUsarSubtitulo,
                                    value: '',
                                    showDivider: false,
                                    onTap: _loading ? null : _usarPlanoSalvo,
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxStaggerItem(
                        index: 1,
                        child: FxSettingsGroup(
                          header: 'Plano base',
                          caption: CreateTreinoLogic.planoBaseCaption(
                            hasNome: hasNome,
                          ),
                          accent: primary,
                          children: [
                            _PlanoBaseSummary(
                              title: previewTitle,
                              meta: previewMeta,
                              primary: primary,
                              soft: soft,
                              onTap: () {
                                _nomeFocusNode.requestFocus();
                                final fieldContext = _nomeFieldKey.currentContext;
                                if (fieldContext != null) {
                                  Scrollable.ensureVisible(
                                    fieldContext,
                                    alignment: 0.2,
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                            ),
                            AlunoInsetFormField(
                              key: _nomeFieldKey,
                              controller: _nomeCtrl,
                              focusNode: _nomeFocusNode,
                              label: 'Nome do treino',
                              icon: Icons.edit_outlined,
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Informe o nome'
                                          : null,
                            ),
                            AlunoInsetFormField(
                              controller: _objetivoCtrl,
                              label: 'Objetivo (opcional)',
                              icon: Icons.flag_outlined,
                            ),
                            FxInsetPickerRow(
                              icon: Icons.tune_rounded,
                              iconColor: soft,
                              label: 'Nível',
                              value: CreateTreinoLogic.nivelLabel(_nivel),
                              onTap: _openNivelPicker,
                            ),
                            AlunoInsetFormField(
                              controller: _descricaoCtrl,
                              label: 'Descrição (opcional)',
                              icon: Icons.notes_rounded,
                              maxLines: 2,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: FxSettingsLayout.groupGap),
                        FxStaggerItem(
                          index: 2,
                          child: FxErrorState(
                            chromeOnDark: isDark,
                            primary: primary,
                            title:
                                soAtribuir
                                    ? s.treinoAtribuirFalhouTitulo
                                    : 'Não foi possível criar o treino',
                            message: _error!,
                            onRetry: _submit,
                          ),
                        ),
                      ],
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

part of 'create_treino_screen.dart';

class _CreateTreinoScreenState extends ConsumerState<CreateTreinoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  final _nomeFocusNode = FocusNode();
  final _nomeFieldKey = GlobalKey();
  String? _nivel;
  bool _loading = false;
  String? _error;

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

  Future<void> _cancel() async {
    if (_dirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Descartar treino?',
        message: 'O que você preencheu não será salvo.',
        confirmLabel: 'Descartar',
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
    if (!_formKey.currentState!.validate()) {
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
      final treino = await ref
          .read(treinoRepositoryProvider)
          .criar(
            _nomeCtrl.text.trim(),
            _descricaoCtrl.text.trim(),
            _objetivoCtrl.text.trim(),
            _nivel,
          );
      if (widget.alunoId != null) {
        await ref
            .read(treinoRepositoryProvider)
            .atribuirAluno(treino.id, widget.alunoId!);
        ref.invalidate(treinosDoAlunoProvider(widget.alunoId!));
      }
      invalidateTreinosCaches(ref);
      ref.invalidate(treinoProvider(treino.id));
      if (mounted) {
        HapticFeedback.heavyImpact();
        context.pop(true);
        context.push(
          '/treinos/${treino.id}/exercicios/add',
          extra:
              widget.alunoId == null
                  ? null
                  : {'alunoId': widget.alunoId, 'alunoNome': widget.alunoNome},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e, fallback: 'Erro ao criar treino.');
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
    final canSubmit = _nomeCtrl.text.trim().isNotEmpty && !_loading;
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
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  6,
                  FxSettingsLayout.pageInset,
                  88 + MediaQuery.paddingOf(context).bottom,
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
                            if (widget.alunoId == null) ...[
                              const SizedBox(
                                height: FxSettingsLayout.groupGap,
                              ),
                              FxSettingsGroup(
                                accent: primary,
                                children: [
                                  FxSettingsTile(
                                    icon: Icons.grid_view_rounded,
                                    accent: soft,
                                    label: 'Abrir biblioteca',
                                    subtitle:
                                        'Planos já salvos na sua conta',
                                    value: '',
                                    showDivider: false,
                                    onTap:
                                        () =>
                                            safePopOrGo(context, '/treinos'),
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
                            title: 'Não foi possível criar o treino',
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
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensStrip.s4,
                    0,
                    TokensStrip.s4,
                    12,
                  ),
                  child: Semantics(
                    button: true,
                    enabled: canSubmit,
                    label:
                        _loading
                            ? 'Criando treino'
                            : canSubmit
                            ? 'Criar treino'
                            : 'Criar treino. Informe o nome para habilitar',
                    child: FxLiquidPrimaryButton(
                      label: 'Criar',
                      loading: _loading,
                      loadingLabel: 'Criando…',
                      onPressed: canSubmit ? _submit : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

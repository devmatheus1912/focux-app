part of 'create_treino_screen.dart';


class _CreateTreinoScreenState extends ConsumerState<CreateTreinoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _objetivoCtrl = TextEditingController();
  final _nomeFocusNode = FocusNode();
  final _nomeFieldKey = GlobalKey();
  String? _nivel;
  bool _loading = false;
  String? _error;

  late final AnimationController _entryCtrl;

  @override
  void initState() {
    super.initState();
    _nomeCtrl.addListener(_onFormChanged);
    _objetivoCtrl.addListener(_onFormChanged);
    _descricaoCtrl.addListener(_onFormChanged);
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _objetivoCtrl.dispose();
    _nomeFocusNode.dispose();
    _entryCtrl.dispose();
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
      String msg = 'Erro ao criar treino.';
      if (e is DioException) {
        final data = e.response?.data;
        final serverMsg =
            data is Map
                ? data['mensagem'] ?? data['message'] ?? data['erro']
                : null;
        if (serverMsg != null) msg = serverMsg.toString();
      }
      if (mounted) {
        setState(() {
          _error = msg;
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

  void _applyPreset(_TreinoPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _objetivoCtrl.text = preset.title;
      if (_nomeCtrl.text.trim().isEmpty) {
        _nomeCtrl.text = displayWorkoutName('Treino ${preset.title}');
      }
      _nivel ??= 'INTERMEDIARIO';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final canSubmit = _nomeCtrl.text.trim().isNotEmpty && !_loading;
    final previewTitle =
        _nomeCtrl.text.trim().isEmpty
            ? 'Plano sem nome'
            : displayWorkoutName(_nomeCtrl.text.trim());
    final previewGoal =
        _objetivoCtrl.text.trim().isEmpty
            ? 'Escolha um objetivo'
            : displayPtBr(_objetivoCtrl.text.trim());
    final previewLevel =
        _nivel == null
            ? 'Nível em aberto'
            : _niveisLabel[_niveis.indexOf(_nivel!)];

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: widget.alunoId == null ? 'Novo Treino' : 'Treino vinculado',
        subtitle: widget.alunoId == null ? 'PLANO BASE' : 'PLANO DO ALUNO',
        onBack: () => safePopOrGo(context, '/treinos'),
      ),
      bottomNavigationBar: _StickyCreateBar(
        canSubmit: canSubmit,
        loading: _loading,
        onSubmit: _submit,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _entryCtrl,
                  curve: Curves.easeOut,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 116),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CreationHero(
                          title: previewTitle,
                          goal: previewGoal,
                          level: previewLevel,
                          isDark: isDark,
                          primary: primary,
                        ),
                        const SizedBox(height: 18),
                        _SectionKicker(
                          title: 'Comece por um modelo',
                          action:
                              widget.alunoId == null
                                  ? 'Biblioteca'
                                  : widget.alunoNome ?? 'Aluno',
                          isDark: isDark,
                          onAction:
                              widget.alunoId == null
                                  ? () => safePopOrGo(context, '/treinos')
                                  : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Deslize para ver mais modelos',
                          style: AppTypography.inter(
                            color:
                                isDark
                                    ? EagleTokens.darkInkMute
                                    : TokensStrip.textSecondary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _PresetRail(
                          presets: _objetivoPresets,
                          selected: _objetivoCtrl.text.trim(),
                          isDark: isDark,
                          primary: primary,
                          onTap: _applyPreset,
                        ),
                        const SizedBox(height: 20),
                        _SectionKicker(
                          title: 'Dados essenciais',
                          action: canSubmit ? 'Pronto' : 'Nome obrigatório',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _FxField(
                          key: _nomeFieldKey,
                          controller: _nomeCtrl,
                          focusNode: _nomeFocusNode,
                          label: 'Nome do treino',
                          icon: Icons.edit_outlined,
                          isDark: isDark,
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Informe o nome'
                                      : null,
                        ),
                        const SizedBox(height: TokensStrip.s4),
                        _LevelSelector(
                          selected: _nivel,
                          isDark: isDark,
                          onChanged: (value) => setState(() => _nivel = value),
                        ),
                        const SizedBox(height: 18),
                        _FxField(
                          controller: _objetivoCtrl,
                          label: 'Objetivo (opcional)',
                          icon: Icons.flag_outlined,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _FxField(
                          controller: _descricaoCtrl,
                          label: 'Descrição (opcional)',
                          icon: Icons.notes_rounded,
                          isDark: isDark,
                          maxLines: 2,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: TokensStrip.s4),
                          _ErrorNotice(message: _error!),
                        ],
                      ],
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

part of 'add_exercicio_screen.dart';

class _AddExercicioScreenState extends ConsumerState<AddExercicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _errosComunsCtrl = TextEditingController();
  final _contraindicacoesCtrl = TextEditingController();

  Modalidade? _modalidade = Modalidade.musculacao;
  PadraoMovimento? _padraoMovimento;
  GrupoMuscular? _grupoMuscularPrimario;
  Dificuldade? _dificuldade = Dificuldade.iniciante;
  final Set<Equipamento> _equipamentos = {
    Equipamento.halter,
    Equipamento.barra,
    Equipamento.maquina,
    Equipamento.polia,
    Equipamento.banco,
  };
  final Set<Espaco> _espacos = {Espaco.academiaCompleta, Espaco.academiaBasica};
  bool _unilateral = false;
  bool _showGuidance = false;
  bool _loading = false;
  bool _didPrefill = false;
  String? _error;
  String? _selectedSetupLabel = 'Academia';

  bool get _isEdit => widget.exercicioId != null;

  @override
  void initState() {
    super.initState();
    _nomeCtrl.addListener(_onFormChanged);
    if (_isEdit) {
      Future.microtask(_prefillFromApi);
    }
  }

  Future<void> _prefillFromApi() async {
    try {
      final ex = await ref.read(exercicioProvider(widget.exercicioId!).future);
      if (!mounted || _didPrefill) return;
      setState(() {
        _prefillFrom(ex);
        _didPrefill = true;
      });
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = friendlyError(
                e,
                fallback: 'Erro ao carregar exercício.',
              ),
        );
      }
    }
  }

  void _prefillFrom(Exercicio ex) {
    _nomeCtrl.text = ex.nome;
    _descricaoCtrl.text = ex.descricao ?? '';
    _errosComunsCtrl.text = ex.errosComuns ?? '';
    _contraindicacoesCtrl.text = ex.contraindicacoes ?? '';
    _modalidade = ex.modalidade ?? Modalidade.musculacao;
    _padraoMovimento = ex.padraoMovimento;
    _grupoMuscularPrimario = ex.grupoMuscularPrimario;
    _dificuldade = ex.dificuldade ?? Dificuldade.iniciante;
    _equipamentos
      ..clear()
      ..addAll(ex.equipamentos);
    _espacos
      ..clear()
      ..addAll(ex.espacosCompativeis);
    _unilateral = ex.unilateral;
    _selectedSetupLabel = null;
    _showGuidance =
        ex.descricao?.trim().isNotEmpty == true ||
        ex.errosComuns?.trim().isNotEmpty == true ||
        ex.contraindicacoes?.trim().isNotEmpty == true;
  }

  Map<String, String> _formPayload() {
    return {
      'nome': _nomeCtrl.text.trim(),
      'descricao': _descricaoCtrl.text.trim(),
      'musculoAlvo': _grupoMuscularPrimario?.backendName ?? '',
      'categoria': _modalidade?.backendName ?? '',
      'equipamento': _equipamentos
          .map((e) => TaxonomyLabels.equipamento[e])
          .join(', '),
      'nivel':
          _dificuldade == null
              ? ''
              : TaxonomyLabels.dificuldade[_dificuldade!] ?? '',
      'mecanica':
          _padraoMovimento == null
              ? ''
              : TaxonomyLabels.padrao[_padraoMovimento!] ?? '',
      'errosComuns': _errosComunsCtrl.text.trim(),
      'contraindicacoes': _contraindicacoesCtrl.text.trim(),
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final payload = _formPayload();
    try {
      final repo = ref.read(exercicioRepositoryProvider);
      if (_isEdit) {
        await repo.atualizar(
          id: widget.exercicioId!,
          nome: payload['nome']!,
          descricao: payload['descricao'],
          musculoAlvo: payload['musculoAlvo'],
          categoria: payload['categoria'],
          equipamento: payload['equipamento'],
          nivel: payload['nivel'],
          mecanica: payload['mecanica'],
          modalidade: _modalidade,
          padraoMovimento: _padraoMovimento,
          grupoMuscularPrimario: _grupoMuscularPrimario,
          equipamentos: _equipamentos.toList(),
          espacosCompativeis: _espacos.toList(),
          dificuldade: _dificuldade,
          unilateral: _unilateral,
          errosComuns: payload['errosComuns'],
          contraindicacoes: payload['contraindicacoes'],
        );
        ref.invalidate(exercicioProvider(widget.exercicioId!));
      } else {
        await repo.criar(
          nome: payload['nome']!,
          descricao: payload['descricao'],
          musculoAlvo: payload['musculoAlvo'],
          categoria: payload['categoria'],
          equipamento: payload['equipamento'],
          nivel: payload['nivel'],
          mecanica: payload['mecanica'],
          modalidade: _modalidade,
          padraoMovimento: _padraoMovimento,
          grupoMuscularPrimario: _grupoMuscularPrimario,
          equipamentos: _equipamentos.toList(),
          espacosCompativeis: _espacos.toList(),
          dificuldade: _dificuldade,
          unilateral: _unilateral,
          errosComuns: payload['errosComuns'],
          contraindicacoes: payload['contraindicacoes'],
        );
      }
      ref.invalidate(exerciciosFilteredProvider);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = S.of(context);
        setState(
          () =>
              _error = friendlyError(
                e,
                fallback:
                    _isEdit ? l10n.exerciseSaveError : l10n.exerciseCreateError,
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nomeCtrl.removeListener(_onFormChanged);
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _errosComunsCtrl.dispose();
    _contraindicacoesCtrl.dispose();
    super.dispose();
  }

  void _applyQuickSetup(_ExerciseQuickSetup setup) {
    setState(() {
      _selectedSetupLabel = setup.label;
      _modalidade = setup.modalidade;
      _dificuldade = setup.dificuldade;
      if (setup.padraoMovimento != null) {
        _padraoMovimento = setup.padraoMovimento;
      }
      _equipamentos
        ..clear()
        ..addAll(setup.equipamentos);
      _espacos
        ..clear()
        ..addAll(setup.espacos);
    });
  }

  Future<void> _openFiltersSheet() async {
    final result = await showAddExercicioFiltersSheet(
      context,
      equipamentos: _equipamentos,
      espacos: _espacos,
    );
    if (result == null || !mounted) return;
    setState(() {
      _equipamentos
        ..clear()
        ..addAll(result.equipamentos);
      _espacos
        ..clear()
        ..addAll(result.espacos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final isDark = chrome.isDark;
    final loadingEdit = _isEdit && !_didPrefill && _error == null;
    final canSubmit =
        !_loading && !loadingEdit && _nomeCtrl.text.trim().isNotEmpty;
    final screenTitle =
        _isEdit ? l10n.editExerciseTitle : l10n.newExerciseTitle;
    final errorTitle =
        _isEdit ? l10n.exerciseSaveFailedTitle : l10n.exerciseCreateFailedTitle;

    return fxScreenA11yScope(
      label: screenTitle,
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: screenTitle,
          onBack: () => safePopOrGo(context, '/exercicios'),
          actions: [
            FxHelpIconButton(
              tooltip: 'Como cadastrar',
              onTap: () => showNovoExercicioHelpSheet(context),
            ),
            const SizedBox(width: TokensStrip.s2),
          ],
        ),
        bottomNavigationBar:
            loadingEdit
                ? null
                : SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      TokensStrip.s2,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s3,
                    ),
                    child: Semantics(
                      button: true,
                      enabled: canSubmit,
                      label:
                          _loading
                              ? (_isEdit
                                  ? l10n.exerciseSavingSemantics
                                  : l10n.exerciseCreatingSemantics)
                              : canSubmit
                              ? (_isEdit
                                  ? l10n.exerciseSaveSemantics
                                  : l10n.exerciseRegisterSemantics)
                              : l10n.exerciseRegisterDisabledSemantics,
                      child: FxLiquidPrimaryButton(
                        label: _isEdit ? l10n.save : l10n.exerciseRegister,
                        loading: _loading,
                        loadingLabel:
                            _isEdit
                                ? l10n.exerciseSaving
                                : l10n.exerciseCreating,
                        onPressed: canSubmit ? _submit : null,
                      ),
                    ),
                  ),
                ),
        body:
            loadingEdit
                ? const SafeArea(child: SkeletonList(count: 6))
                : SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      FxSettingsLayout.pageInset,
                      6,
                      FxSettingsLayout.pageInset,
                      TokensStrip.s4,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FxStaggerItem(
                            index: 0,
                            child: FxSettingsGroup(
                              header: 'Identidade',
                              caption:
                                  'Nome, grupo muscular e como o movimento é prescrito.',
                              accent: primary,
                              children: [
                                AlunoInsetFormField(
                                  controller: _nomeCtrl,
                                  label: 'Nome do exercício',
                                  hint: 'Ex.: Elevação lateral',
                                  icon: Icons.fitness_center_outlined,
                                  validator:
                                      (v) =>
                                          v == null || v.trim().isEmpty
                                              ? 'Informe o nome'
                                              : null,
                                ),
                                if (!_isEdit)
                                  _QuickSetupStrip(
                                    selectedLabel: _selectedSetupLabel,
                                    onSelected: _applyQuickSetup,
                                  ),
                                _EnumDropdown<GrupoMuscular>(
                                  label: 'Grupo principal',
                                  icon: Icons.accessibility_new_rounded,
                                  iconColor: soft,
                                  sheetContextLabel: screenTitle,
                                  value: _grupoMuscularPrimario,
                                  values: GrupoMuscular.values,
                                  labels: TaxonomyLabels.grupo,
                                  onChanged:
                                      (v) => setState(
                                        () => _grupoMuscularPrimario = v,
                                      ),
                                  validator:
                                      (v) =>
                                          v == null ? 'Escolha o grupo' : null,
                                ),
                                _EnumDropdown<Modalidade>(
                                  label: 'Modalidade',
                                  icon: Icons.sports_gymnastics_rounded,
                                  iconColor: soft,
                                  sheetContextLabel: screenTitle,
                                  value: _modalidade,
                                  values: Modalidade.values,
                                  labels: TaxonomyLabels.modalidade,
                                  onChanged:
                                      (v) => setState(() => _modalidade = v),
                                ),
                                _EnumDropdown<Dificuldade>(
                                  label: 'Dificuldade',
                                  icon: Icons.signal_cellular_alt_rounded,
                                  iconColor: soft,
                                  sheetContextLabel: screenTitle,
                                  value: _dificuldade,
                                  values: Dificuldade.values,
                                  labels: TaxonomyLabels.dificuldade,
                                  onChanged:
                                      (v) => setState(() => _dificuldade = v),
                                ),
                                _EnumDropdown<PadraoMovimento>(
                                  label: 'Padrão de movimento',
                                  icon: Icons.sync_alt_rounded,
                                  iconColor: soft,
                                  sheetContextLabel: screenTitle,
                                  value: _padraoMovimento,
                                  values: PadraoMovimento.values,
                                  labels: TaxonomyLabels.padrao,
                                  onChanged:
                                      (v) =>
                                          setState(() => _padraoMovimento = v),
                                ),
                                FxSettingsTile(
                                  icon: Icons.swap_horiz_rounded,
                                  accent: soft,
                                  label: 'Unilateral',
                                  subtitle:
                                      'Cada lado executado separadamente (ex.: 12 por braço).',
                                  value: '',
                                  showDivider: false,
                                  accessory: Switch.adaptive(
                                    value: _unilateral,
                                    onChanged:
                                        (v) => setState(() => _unilateral = v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: FxSettingsLayout.groupGap),
                          FxStaggerItem(
                            index: 1,
                            child: FxSettingsGroup(
                              header: 'Ambiente',
                              caption:
                                  'Onde e com o quê o aluno pode executar este exercício.',
                              accent: primary,
                              children: [
                                FxSettingsTile(
                                  icon: Icons.inventory_2_outlined,
                                  accent: soft,
                                  label: 'Equipamentos e espaços',
                                  subtitle: _filterSummary(
                                    equipamentos: _equipamentos.length,
                                    espacos: _espacos.length,
                                  ),
                                  value: '',
                                  picker: true,
                                  showDivider: false,
                                  onTap: _openFiltersSheet,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: FxSettingsLayout.groupGap),
                          FxStaggerItem(
                            index: 2,
                            child: _CollapsibleSection(
                              icon: Icons.co_present_outlined,
                              title: 'Orientação opcional',
                              subtitle:
                                  _showGuidance
                                      ? 'Detalhes úteis para o aluno executar com segurança.'
                                      : 'Descrição, erros comuns e restrições quando precisar.',
                              expanded: _showGuidance,
                              onToggle:
                                  () => setState(
                                    () => _showGuidance = !_showGuidance,
                                  ),
                              child: Column(
                                children: [
                                  AlunoInsetFormField(
                                    controller: _descricaoCtrl,
                                    label: 'Descrição curta',
                                    hint:
                                        'Como executar em uma frase objetiva.',
                                    icon: Icons.notes_rounded,
                                    maxLines: 2,
                                  ),
                                  AlunoInsetFormField(
                                    controller: _errosComunsCtrl,
                                    label: 'Erros comuns',
                                    hint:
                                        'Ex.: elevar os ombros, roubar com o tronco.',
                                    icon: Icons.warning_amber_rounded,
                                    maxLines: 2,
                                  ),
                                  AlunoInsetFormField(
                                    controller: _contraindicacoesCtrl,
                                    label: 'Contraindicações',
                                    hint:
                                        'Quando evitar ou adaptar este exercício.',
                                    icon: Icons.health_and_safety_outlined,
                                    maxLines: 2,
                                    showDivider: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: FxSettingsLayout.groupGap),
                            FxStaggerItem(
                              index: 3,
                              child: FxErrorState(
                                chromeOnDark: isDark,
                                primary: primary,
                                title: errorTitle,
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
    );
  }
}

String _filterSummary({required int equipamentos, required int espacos}) {
  if (equipamentos == 0 && espacos == 0) {
    return 'Opcional: refine filtros quando isso ajudar na busca.';
  }
  if (equipamentos == 0) {
    final espacoText = '$espacos espaço${espacos == 1 ? '' : 's'}';
    return '$espacoText definido${espacos == 1 ? '' : 's'}. Toque para ajustar.';
  }
  if (espacos == 0) {
    final equipamentoText =
        '$equipamentos equipamento${equipamentos == 1 ? '' : 's'}';
    return '$equipamentoText definido${equipamentos == 1 ? '' : 's'}. Toque para ajustar.';
  }
  final equipamentoText =
      '$equipamentos equipamento${equipamentos == 1 ? '' : 's'}';
  final espacoText = '$espacos espaço${espacos == 1 ? '' : 's'}';
  return '$equipamentoText · $espacoText. Toque para ajustar.';
}

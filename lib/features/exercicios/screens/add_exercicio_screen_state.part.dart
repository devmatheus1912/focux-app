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
  bool _showFilters = false;
  bool _showGuidance = false;
  bool _loading = false;
  String? _error;
  String? _selectedSetupLabel = 'Academia';

  @override
  void initState() {
    super.initState();
    _nomeCtrl.addListener(_onFormChanged);
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(exercicioRepositoryProvider)
          .criar(
            nome: _nomeCtrl.text.trim(),
            descricao: _descricaoCtrl.text.trim(),
            musculoAlvo: _grupoMuscularPrimario?.backendName,
            categoria: _modalidade?.backendName,
            equipamento: _equipamentos
                .map((e) => TaxonomyLabels.equipamento[e])
                .join(', '),
            nivel:
                _dificuldade == null
                    ? null
                    : TaxonomyLabels.dificuldade[_dificuldade!],
            mecanica:
                _padraoMovimento == null
                    ? null
                    : TaxonomyLabels.padrao[_padraoMovimento!],
            modalidade: _modalidade,
            padraoMovimento: _padraoMovimento,
            grupoMuscularPrimario: _grupoMuscularPrimario,
            equipamentos: _equipamentos.toList(),
            espacosCompativeis: _espacos.toList(),
            dificuldade: _dificuldade,
            unilateral: _unilateral,
            errosComuns: _errosComunsCtrl.text.trim(),
            contraindicacoes: _contraindicacoesCtrl.text.trim(),
          );
      ref.invalidate(exerciciosFilteredProvider);
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = friendlyError(
                e,
                fallback: 'Erro ao cadastrar exercício.',
              ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final isDark = chrome.isDark;
    final canSubmit = !_loading && _nomeCtrl.text.trim().isNotEmpty;

    return fxScreenA11yScope(
      label: 'Novo exercício',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: 'Novo Exercício',
          onBack: () => safePopOrGo(context, '/exercicios'),
        ),
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  FxSettingsLayout.pageInset,
                  6,
                  FxSettingsLayout.pageInset,
                  96,
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
                              'Nome, grupo muscular e intenção principal do movimento.',
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
                            _QuickSetupStrip(
                              selectedLabel: _selectedSetupLabel,
                              onSelected: _applyQuickSetup,
                            ),
                            _EnumDropdown<GrupoMuscular>(
                              label: 'Grupo principal',
                              icon: Icons.accessibility_new_rounded,
                              iconColor: soft,
                              value: _grupoMuscularPrimario,
                              values: GrupoMuscular.values,
                              labels: TaxonomyLabels.grupo,
                              onChanged:
                                  (v) => setState(
                                    () => _grupoMuscularPrimario = v,
                                  ),
                              validator:
                                  (v) => v == null ? 'Escolha o grupo' : null,
                            ),
                            _EnumDropdown<Modalidade>(
                              label: 'Modalidade',
                              icon: Icons.sports_gymnastics_rounded,
                              iconColor: soft,
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
                              value: _padraoMovimento,
                              values: PadraoMovimento.values,
                              labels: TaxonomyLabels.padrao,
                              onChanged:
                                  (v) => setState(() => _padraoMovimento = v),
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxStaggerItem(
                        index: 1,
                        child: FxSettingsGroup(
                          accent: primary,
                          children: [
                            FxSettingsTile(
                              icon: Icons.swap_horiz_rounded,
                              accent: soft,
                              label: 'Unilateral',
                              subtitle:
                                  'Marque quando cada lado deve ser executado separadamente.',
                              value: '',
                              showDivider: false,
                              onTap: () => setState(() => _unilateral = !_unilateral),
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
                        index: 2,
                        child: _CollapsibleSection(
                          icon: Icons.inventory_2_outlined,
                          title: 'Equipamentos e espaços',
                          subtitle: _filterSummary(
                            equipamentos: _equipamentos.length,
                            espacos: _espacos.length,
                          ),
                          expanded: _showFilters,
                          onToggle:
                              () => setState(() => _showFilters = !_showFilters),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _GroupLabel(
                                label: 'Equipamentos',
                                count: _equipamentos.length,
                              ),
                              const SizedBox(height: 6),
                              _ChoiceGroup<Equipamento>(
                                values: Equipamento.values,
                                selected: _equipamentos,
                                labels: TaxonomyLabels.equipamento,
                                onToggle:
                                    (value) => setState(() {
                                      _equipamentos.contains(value)
                                          ? _equipamentos.remove(value)
                                          : _equipamentos.add(value);
                                    }),
                              ),
                              const SizedBox(height: 10),
                              _GroupLabel(
                                label: 'Espaços',
                                count: _espacos.length,
                              ),
                              const SizedBox(height: 6),
                              _ChoiceGroup<Espaco>(
                                values: Espaco.values,
                                selected: _espacos,
                                labels: TaxonomyLabels.espaco,
                                onToggle:
                                    (value) => setState(() {
                                      _espacos.contains(value)
                                          ? _espacos.remove(value)
                                          : _espacos.add(value);
                                    }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: FxSettingsLayout.groupGap),
                      FxStaggerItem(
                        index: 3,
                        child: _CollapsibleSection(
                          icon: Icons.co_present_outlined,
                          title: 'Orientação opcional',
                          subtitle:
                              _showGuidance
                                  ? 'Detalhes úteis para o aluno executar com segurança.'
                                  : 'Execução, erros comuns e restrições quando precisar.',
                          expanded: _showGuidance,
                          onToggle:
                              () =>
                                  setState(() => _showGuidance = !_showGuidance),
                          child: Column(
                            children: [
                              AlunoInsetFormField(
                                controller: _descricaoCtrl,
                                label: 'Descrição curta',
                                hint: 'Como executar em uma frase objetiva.',
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
                                hint: 'Quando evitar ou adaptar este exercício.',
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
                          index: 4,
                          child: FxErrorState(
                            chromeOnDark: isDark,
                            primary: primary,
                            title: 'Não foi possível cadastrar',
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
              alignment: AlignmentDirectional.bottomEnd,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    0,
                    FxSettingsLayout.pageInset,
                    12,
                  ),
                  child: Semantics(
                    button: true,
                    enabled: canSubmit,
                    label:
                        _loading
                            ? 'Cadastrando exercício'
                            : canSubmit
                            ? 'Cadastrar exercício'
                            : 'Cadastrar exercício. Informe o nome para habilitar',
                    child: DashboardHomeActionChip(
                      label: _loading ? 'Cadastrando…' : 'Cadastrar',
                      accent: primary,
                      isDark: isDark,
                      enabled: canSubmit,
                      onPressed: _submit,
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

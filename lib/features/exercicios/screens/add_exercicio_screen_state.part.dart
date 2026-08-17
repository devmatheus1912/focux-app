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
  void dispose() {
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
    final bottom = MediaQuery.paddingOf(context).bottom;

    return fxScreenA11yScope(
      label: 'Novo exercício',
      child: FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: 'Novo Exercício',
        subtitle: 'NOVO ITEM',
        onBack: () => safePopOrGo(context, '/exercicios'),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  TokensStrip.s5,
                  0,
                  20,
                  118 + bottom,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        icon: Icons.fitness_center_rounded,
                        title: 'Identidade',
                        subtitle: 'Defina nome, grupo e intenção principal.',
                        child: Column(
                          children: [
                            _TextInput(
                              controller: _nomeCtrl,
                              label: 'Nome do exercício',
                              hint: 'Ex.: Elevação lateral',
                              validator:
                                  (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Informe o nome'
                                          : null,
                            ),
                            const SizedBox(height: 12),
                            _QuickSetupStrip(
                              selectedLabel: _selectedSetupLabel,
                              onSelected: _applyQuickSetup,
                            ),
                            const SizedBox(height: 12),
                            _EnumDropdown<GrupoMuscular>(
                              label: 'Grupo principal',
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
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _EnumDropdown<Modalidade>(
                                    label: 'Modalidade',
                                    value: _modalidade,
                                    values: Modalidade.values,
                                    labels: TaxonomyLabels.modalidade,
                                    onChanged:
                                        (v) => setState(() => _modalidade = v),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _EnumDropdown<Dificuldade>(
                                    label: 'Dificuldade',
                                    value: _dificuldade,
                                    values: Dificuldade.values,
                                    labels: TaxonomyLabels.dificuldade,
                                    onChanged:
                                        (v) => setState(() => _dificuldade = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _EnumDropdown<PadraoMovimento>(
                              label: 'Padrão de movimento',
                              value: _padraoMovimento,
                              values: PadraoMovimento.values,
                              labels: TaxonomyLabels.padrao,
                              onChanged:
                                  (v) => setState(() => _padraoMovimento = v),
                            ),
                            const SizedBox(height: 12),
                            _SwitchRow(
                              value: _unilateral,
                              title: 'Unilateral',
                              subtitle:
                                  'Marque quando cada lado deve ser executado separadamente.',
                              onChanged: (v) => setState(() => _unilateral = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GroupLabel(
                              label: 'Equipamentos',
                              count: _equipamentos.length,
                            ),
                            const SizedBox(height: 8),
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
                            const SizedBox(height: 14),
                            _GroupLabel(
                              label: 'Espaços',
                              count: _espacos.length,
                            ),
                            const SizedBox(height: 8),
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
                      const SizedBox(height: 12),
                      _SectionCard(
                        icon: Icons.co_present_outlined,
                        title: 'Orientação opcional',
                        subtitle:
                            _showGuidance
                                ? 'Adicione detalhes se eles forem úteis para o aluno.'
                                : 'Execução, erros comuns e restrições quando precisar.',
                        expanded: _showGuidance,
                        onToggle:
                            () =>
                                setState(() => _showGuidance = !_showGuidance),
                        child: Column(
                          children: [
                            _TextInput(
                              controller: _descricaoCtrl,
                              label: 'Descrição curta',
                              hint: 'Como executar em uma frase objetiva.',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _TextInput(
                              controller: _errosComunsCtrl,
                              label: 'Erros comuns',
                              hint:
                                  'Ex.: elevar os ombros, roubar com o tronco.',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            _TextInput(
                              controller: _contraindicacoesCtrl,
                              label: 'Contraindicações',
                              hint: 'Quando evitar ou adaptar este exercício.',
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        FxErrorState(
                          chromeOnDark: chrome.isDark,
                          primary: primary,
                          title: 'Não foi possível cadastrar',
                          message: _error!,
                          onRetry: _submit,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: chrome.isDark ? EagleTokens.darkBg : TokensStrip.pageBg,
          border: Border(top: BorderSide(color: chrome.line)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: chrome.isDark ? 0.3 : 0.08),
              blurRadius: 22,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(TokensStrip.s5, 10, 20, 12),
            child: Semantics(
              button: true,
              label: 'Cadastrar exercício',
              enabled: !_loading,
              child: FxLiquidPrimaryButton(
                label: 'Cadastrar exercício',
                onPressed: _loading ? null : _submit,
                loading: _loading,
              ),
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
    return 'Espaço definido: $espacoText. Toque para adicionar equipamentos.';
  }
  if (espacos == 0) {
    final equipamentoText =
        '$equipamentos equipamento${equipamentos == 1 ? '' : 's'}';
    return 'Equipamentos definidos: $equipamentoText. Toque para adicionar espaços.';
  }
  final equipamentoText =
      '$equipamentos equipamento${equipamentos == 1 ? '' : 's'}';
  final espacoText = '$espacos espaço${espacos == 1 ? '' : 's'}';
  return '$equipamentoText e $espacoText definidos. Toque para ajustar.';
}

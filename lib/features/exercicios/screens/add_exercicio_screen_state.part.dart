part of 'add_exercicio_screen.dart';

class _AddExercicioScreenState extends ConsumerState<AddExercicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _errosComunsCtrl = TextEditingController();
  final _contraindicacoesCtrl = TextEditingController();

  static const _defaultEquipamentos = {
    Equipamento.halter,
    Equipamento.barra,
    Equipamento.maquina,
    Equipamento.polia,
    Equipamento.banco,
  };
  static const _defaultEspacos = {
    Espaco.academiaCompleta,
    Espaco.academiaBasica,
  };

  Modalidade? _modalidade = Modalidade.musculacao;
  PadraoMovimento? _padraoMovimento;
  GrupoMuscular? _grupoMuscularPrimario;
  Dificuldade? _dificuldade = Dificuldade.iniciante;
  final Set<Equipamento> _equipamentos = {..._defaultEquipamentos};
  final Set<Espaco> _espacos = {..._defaultEspacos};
  bool _unilateral = false;
  bool _showGuidance = false;
  bool _loading = false;
  bool _didPrefill = false;
  String? _error;
  String? _selectedSetupLabel = 'Academia';

  /// Vídeo escolhido na criação (opcional); sobe depois que o exercício existe.
  VideoDoExercicio? _video;
  int? _criadoId;

  /// O sistema ainda entrega o arquivo escolhido (vídeo longo leva segundos).
  bool _preparandoVideo = false;

  /// Exercício criado, vídeo subindo: [_progressoVideo] de 0 a 1, depois o
  /// servidor converte. Sair agora cancela pelo [_cancelVideo].
  bool _enviandoVideo = false;
  double? _progressoVideo;
  CancelToken? _cancelVideo;
  bool _saiuDuranteEnvio = false;

  // Baseline for edit dirty-check (filled after prefill).
  String _baselineNome = '';
  String _baselineDescricao = '';
  String _baselineErros = '';
  String _baselineContra = '';
  Modalidade? _baselineModalidade;
  PadraoMovimento? _baselinePadrao;
  GrupoMuscular? _baselineGrupo;
  Dificuldade? _baselineDificuldade;
  Set<Equipamento> _baselineEquipamentos = {};
  Set<Espaco> _baselineEspacos = {};
  bool _baselineUnilateral = false;
  bool _baselineShowGuidance = false;

  bool get _isEdit => widget.exercicioId != null;

  bool get _dirty {
    if (_isEdit) {
      if (!_didPrefill) return false;
      return _nomeCtrl.text != _baselineNome ||
          _descricaoCtrl.text != _baselineDescricao ||
          _errosComunsCtrl.text != _baselineErros ||
          _contraindicacoesCtrl.text != _baselineContra ||
          _modalidade != _baselineModalidade ||
          _padraoMovimento != _baselinePadrao ||
          _grupoMuscularPrimario != _baselineGrupo ||
          _dificuldade != _baselineDificuldade ||
          !_setEquals(_equipamentos, _baselineEquipamentos) ||
          !_setEquals(_espacos, _baselineEspacos) ||
          _unilateral != _baselineUnilateral ||
          _showGuidance != _baselineShowGuidance;
    }
    return _video != null ||
        _nomeCtrl.text.trim().isNotEmpty ||
        _descricaoCtrl.text.trim().isNotEmpty ||
        _errosComunsCtrl.text.trim().isNotEmpty ||
        _contraindicacoesCtrl.text.trim().isNotEmpty ||
        _grupoMuscularPrimario != null ||
        _padraoMovimento != null ||
        _unilateral ||
        _modalidade != Modalidade.musculacao ||
        _dificuldade != Dificuldade.iniciante ||
        !_setEquals(_equipamentos, _defaultEquipamentos) ||
        !_setEquals(_espacos, _defaultEspacos) ||
        _selectedSetupLabel != 'Academia' ||
        _showGuidance;
  }

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    if (_enviandoVideo) {
      final ficar = await showFxConfirmSheetOuFechar(
        context,
        title: exerciseVideoSairTitulo(),
        message: exerciseVideoSairTexto(),
        icon: FxIcons.video,
        confirmLabel: exerciseVideoSairFicar(),
        cancelLabel: exerciseVideoSairConfirmar(),
      );
      if (ficar != false || !mounted || !_enviandoVideo) return;
      // O envio cancelado devolve o exercício (já criado) a quem abriu.
      _saiuDuranteEnvio = true;
      _cancelVideo?.cancel();
      return;
    }
    if (_dirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: _isEdit ? 'Descartar alterações?' : 'Descartar cadastro?',
        message:
            _isEdit
                ? 'O que você alterou não será salvo.'
                : 'O que você preencheu não será salvo.',
        confirmLabel: 'Descartar',
        discard: true,
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/exercicios');
  }

  @override
  void initState() {
    super.initState();
    _nomeCtrl.addListener(_onFormChanged);
    _descricaoCtrl.addListener(_onFormChanged);
    _errosComunsCtrl.addListener(_onFormChanged);
    _contraindicacoesCtrl.addListener(_onFormChanged);
    if (_isEdit) {
      Future.microtask(_prefillFromApi);
    } else if (widget.copiaDe != null) {
      // Cópia da biblioteca: mesmos dados, nome "(meu)", nunca o vídeo.
      _prefillFrom(widget.copiaDe!);
      _nomeCtrl.text = nomeDaCopia(widget.copiaDe!.nomeDisplay);
    } else if (widget.nomeInicial?.trim().isNotEmpty == true) {
      _nomeCtrl.text = widget.nomeInicial!.trim();
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
    _baselineNome = _nomeCtrl.text;
    _baselineDescricao = _descricaoCtrl.text;
    _baselineErros = _errosComunsCtrl.text;
    _baselineContra = _contraindicacoesCtrl.text;
    _baselineModalidade = _modalidade;
    _baselinePadrao = _padraoMovimento;
    _baselineGrupo = _grupoMuscularPrimario;
    _baselineDificuldade = _dificuldade;
    _baselineEquipamentos = {..._equipamentos};
    _baselineEspacos = {..._espacos};
    _baselineUnilateral = _unilateral;
    _baselineShowGuidance = _showGuidance;
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
        _criadoId =
            (await repo.criar(
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
            )).id;
      }
      ref.invalidate(exerciciosFilteredProvider);
      if (!_isEdit && _video != null) {
        await _enviarVideoDoNovo();
      }
      if (!mounted) return;
      final criadoId = _criadoId;
      if (_saiuDuranteEnvio && criadoId != null) {
        context.pop(ExercicioCriado(id: criadoId, nome: _nomeCtrl.text.trim()));
        return;
      }
      if (_isEdit || criadoId == null) {
        context.pop(true);
        return;
      }
      final destino = await showExercicioCriadoSheet(
        context,
        nome: _nomeCtrl.text.trim(),
        origem: widget.origem,
      );
      if (!mounted) return;
      context.pop(
        ExercicioCriado(
          id: criadoId,
          nome: _nomeCtrl.text.trim(),
          destino: destino,
        ),
      );
    } on OfflineQueuedException {
      if (mounted) leaveWithQueuedNotice(context, '/exercicios');
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

  /// Escolher leva tempo com vídeo longo (o sistema copia o arquivo): a
  /// linha mostra "Preparando vídeo…" e o Cadastrar espera.
  Future<void> _escolherVideo() async {
    if (_preparandoVideo || _loading) return;
    FxKeyboardDismissScope.dismiss();
    try {
      final video = await ref.read(escolherVideoDoExercicioProvider)(
        context,
        aoPreparar: () {
          if (mounted) setState(() => _preparandoVideo = true);
        },
      );
      if (video == null || !mounted) return;
      setState(() => _video = video);
    } finally {
      if (mounted) setState(() => _preparandoVideo = false);
    }
  }

  /// O exercício já existe: sobe o vídeo. Falha não desfaz o cadastro.
  Future<void> _enviarVideoDoNovo() async {
    final id = _criadoId;
    final video = _video;
    if (id == null || video == null) return;
    final cancel = CancelToken();
    setState(() {
      _enviandoVideo = true;
      _progressoVideo = 0;
      _cancelVideo = cancel;
    });
    try {
      await ref
          .read(exercicioRepositoryProvider)
          .uploadVideoExercicio(
            id,
            video.path,
            cancelToken: cancel,
            onProgresso: (p) {
              // Um setState por ponto percentual, não por pacote enviado.
              final antes = ((_progressoVideo ?? 0) * 100).floor();
              if (mounted && (p * 100).floor() != antes) {
                setState(() => _progressoVideo = p);
              }
            },
          );
      ref.invalidate(exerciciosFilteredProvider);
    } catch (e) {
      if (_saiuDuranteEnvio) return;
      if (mounted) FeedbackHelper.showWarn(context, exerciseVideoNovoFalhou());
    } finally {
      if (mounted) {
        setState(() {
          _enviandoVideo = false;
          _cancelVideo = null;
        });
      }
    }
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nomeCtrl.removeListener(_onFormChanged);
    _descricaoCtrl.removeListener(_onFormChanged);
    _errosComunsCtrl.removeListener(_onFormChanged);
    _contraindicacoesCtrl.removeListener(_onFormChanged);
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
        !_loading &&
        !loadingEdit &&
        !_preparandoVideo &&
        _nomeCtrl.text.trim().isNotEmpty;
    final screenTitle =
        _isEdit ? l10n.editExerciseTitle : l10n.newExerciseTitle;
    final errorTitle =
        _isEdit ? l10n.exerciseSaveFailedTitle : l10n.exerciseCreateFailedTitle;

    return fxScreenA11yScope(
      label: screenTitle,
      child: FxFormPopGuard(
        dirty: _dirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          comFundo: true,
          appBar: FxShellAppBar(
            title: screenTitle,
            leadingWidth: 92,
            leading: _CancelarTexto(onTap: _cancel),
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
                  : FxFormStickyBar(
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
                        label:
                            _isEdit
                                ? l10n.save
                                : _preparandoVideo
                                ? exerciseVideoEsperando()
                                : l10n.exerciseRegister,
                        loading: _loading,
                        loadingLabel:
                            _isEdit
                                ? l10n.exerciseSaving
                                : _enviandoVideo
                                ? exerciseVideoEnvioRotulo(_progressoVideo)
                                : l10n.exerciseCreating,
                        onPressed: canSubmit ? _submit : null,
                      ),
                    ),
                  ),
          body:
              loadingEdit
                  ? const SafeArea(child: SkeletonList(count: 6))
                  : SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
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
                                    icon: FxIcons.treino,
                                    rotuloVisivel: true,
                                    obrigatorio: true,
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
                                    obrigatorio: true,
                                    icon: FxIcons.acessibilidade,
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
                                            v == null
                                                ? 'Escolha o grupo'
                                                : null,
                                  ),
                                  _EnumDropdown<Modalidade>(
                                    label: 'Modalidade',
                                    icon: FxIcons.alongamento,
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
                                    icon: FxIcons.nivel,
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
                                    icon: FxIcons.trocar,
                                    iconColor: soft,
                                    sheetContextLabel: screenTitle,
                                    value: _padraoMovimento,
                                    values: PadraoMovimento.values,
                                    labels: TaxonomyLabels.padrao,
                                    onChanged:
                                        (v) => setState(
                                          () => _padraoMovimento = v,
                                        ),
                                  ),
                                  FxSettingsTile(
                                    icon: FxIcons.trocar,
                                    accent: soft,
                                    label: 'Unilateral',
                                    subtitle:
                                        'Cada lado executado separadamente (ex.: 12 por braço).',
                                    value: '',
                                    showDivider: false,
                                    accessory: Switch.adaptive(
                                      activeTrackColor:
                                          Theme.of(context).colorScheme.primary,
                                      value: _unilateral,
                                      onChanged:
                                          (v) =>
                                              setState(() => _unilateral = v),
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
                                    icon: FxIcons.estoque,
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
                            if (!_isEdit) ...[
                              const SizedBox(height: FxSettingsLayout.groupGap),
                              FxSettingsGroup(
                                header: 'Vídeo',
                                caption:
                                    'Opcional. O aluno vê o seu vídeo no treino; dá para enviar depois.',
                                accent: primary,
                                children: [
                                  FxSettingsTile(
                                    icon: FxIcons.video,
                                    accent: soft,
                                    label: exerciseVideoLinhaTitulo(
                                      preparando: _preparandoVideo,
                                      escolhido: _video != null,
                                    ),
                                    subtitle: exerciseVideoLinhaApoio(
                                      preparando: _preparandoVideo,
                                      resumo: _video?.resumo,
                                    ),
                                    value: '',
                                    picker: !_preparandoVideo,
                                    accessory:
                                        _preparandoVideo
                                            ? FxLoading(
                                              size: 18,
                                              strokeWidth: 2,
                                              color: primary,
                                            )
                                            : null,
                                    showDivider: _video != null,
                                    onTap:
                                        _preparandoVideo || _loading
                                            ? null
                                            : _escolherVideo,
                                  ),
                                  if (_video != null)
                                    FxSettingsTile(
                                      icon: FxIcons.excluir,
                                      label: 'Tirar vídeo',
                                      value: '',
                                      danger: true,
                                      showDivider: false,
                                      onTap:
                                          _loading
                                              ? null
                                              : () =>
                                                  setState(() => _video = null),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: FxSettingsLayout.groupGap),
                            FxStaggerItem(
                              index: 2,
                              child: _CollapsibleSection(
                                icon: FxIcons.apresentacao,
                                title: 'Orientação',
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
                                      rotuloVisivel: true,
                                      hint:
                                          'Como executar em uma frase objetiva.',
                                      icon: FxIcons.notas,
                                      maxLines: 2,
                                    ),
                                    AlunoInsetFormField(
                                      controller: _errosComunsCtrl,
                                      label: 'Erros comuns',
                                      rotuloVisivel: true,
                                      hint:
                                          'Ex.: elevar os ombros, roubar com o tronco.',
                                      icon: FxIcons.alerta,
                                      maxLines: 2,
                                    ),
                                    AlunoInsetFormField(
                                      controller: _contraindicacoesCtrl,
                                      label: 'Contraindicações',
                                      rotuloVisivel: true,
                                      hint:
                                          'Quando evitar ou adaptar este exercício.',
                                      icon: FxIcons.saude,
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
      ),
    );
  }
}

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);

String _filterSummary({required int equipamentos, required int espacos}) {
  if (equipamentos == 0 && espacos == 0) {
    return 'Opcional: refine filtros quando isso ajudar na busca.';
  }
  if (equipamentos == 0) {
    final espacoText = '$espacos espaço${espacos == 1 ? '' : 's'}';
    return espacoText;
  }
  if (espacos == 0) {
    final equipamentoText =
        '$equipamentos equipamento${equipamentos == 1 ? '' : 's'}';
    return equipamentoText;
  }
  final equipamentoText =
      '$equipamentos equipamento${equipamentos == 1 ? '' : 's'}';
  final espacoText = '$espacos espaço${espacos == 1 ? '' : 's'}';
  return '$equipamentoText · $espacoText';
}

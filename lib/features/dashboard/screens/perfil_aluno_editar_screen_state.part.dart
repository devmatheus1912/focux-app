part of 'perfil_aluno_editar_screen.dart';

/// Ação aberta ao carregar o editor (`?acao=` vindo das pendências da Home).
enum PerfilEditarAcao {
  foto,
  medida;

  static PerfilEditarAcao? tryParse(String? raw) {
    for (final a in values) {
      if (a.name == raw) return a;
    }
    return null;
  }
}

class _PerfilAlunoEditarScreenState extends ConsumerState<PerfilAlunoEditarScreen> {
  bool _acaoInicialFeita = false;

  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _objetivo = TextEditingController();
  final _genero = TextEditingController();
  final _tipoConsultoria = TextEditingController();
  final _peso = TextEditingController();
  final _altura = TextEditingController();
  final _dataNascimento = TextEditingController();

  String? _fotoUrl;
  bool _loaded = false;
  bool _saving = false;
  bool _uploading = false;
  String _baseNome = '';
  String _baseEmail = '';
  String _baseTelefone = '';
  String _baseWhatsapp = '';
  String _baseObjetivo = '';
  String _baseGenero = '';
  String _baseTipo = '';
  String _basePeso = '';
  String _baseAltura = '';
  String _baseNascimento = '';
  String? _baseFotoUrl;

  var _mesmoNumero = true;

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _isDirty {
    if (!_loaded) return false;
    return _nome.text != _baseNome ||
        _email.text != _baseEmail ||
        _telefone.text != _baseTelefone ||
        _whatsapp.text != _baseWhatsapp ||
        _objetivo.text != _baseObjetivo ||
        _genero.text != _baseGenero ||
        _tipoConsultoria.text != _baseTipo ||
        _peso.text != _basePeso ||
        _altura.text != _baseAltura ||
        _dataNascimento.text != _baseNascimento ||
        _fotoUrl != _baseFotoUrl;
  }

  void _captureBaseline() {
    _baseNome = _nome.text;
    _baseEmail = _email.text;
    _baseTelefone = _telefone.text;
    _baseWhatsapp = _whatsapp.text;
    _baseObjetivo = _objetivo.text;
    _baseGenero = _genero.text;
    _baseTipo = _tipoConsultoria.text;
    _basePeso = _peso.text;
    _baseAltura = _altura.text;
    _baseNascimento = _dataNascimento.text;
    _baseFotoUrl = _fotoUrl;
  }

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    if (_isDirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Descartar alterações?',
        message: 'O que você alterou não será salvo.',
        confirmLabel: 'Descartar',
        discard: true,
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/aluno/perfil');
  }

  @override
  void dispose() {
    for (final c in [
      _nome,
      _email,
      _telefone,
      _whatsapp,
      _objetivo,
      _genero,
      _tipoConsultoria,
      _peso,
      _altura,
      _dataNascimento,
    ]) {
      c
        ..removeListener(_onFieldChanged)
        ..dispose();
    }
    super.dispose();
  }

  Future<void> _loadIfNeeded(Aluno aluno) async {
    if (_loaded) return;
    _loaded = true;
    for (final c in [
      _nome,
      _email,
      _telefone,
      _whatsapp,
      _objetivo,
      _genero,
      _tipoConsultoria,
      _peso,
      _altura,
      _dataNascimento,
    ]) {
      c.addListener(_onFieldChanged);
    }
    _nome.text = aluno.nome;
    _email.text = aluno.email;
    _telefone.text = BrPhone.formatDisplay(aluno.telefone);
    _whatsapp.text = BrPhone.formatDisplay(aluno.whatsapp ?? aluno.telefone);
    _mesmoNumero =
        BrPhone.digitsOnly(_telefone.text).isEmpty ||
        BrPhone.digitsOnly(_telefone.text) == BrPhone.digitsOnly(_whatsapp.text);
    _objetivo.text = aluno.objetivo ?? '';
    _genero.text = aluno.genero ?? '';
    _tipoConsultoria.text = aluno.tipoConsultoria ?? '';
    _peso.text = aluno.peso == null ? '' : numeroSemZero(aluno.peso!);
    _altura.text = aluno.altura == null ? '' : aluno.altura!.toStringAsFixed(2).replaceAll('.', ',');
    _dataNascimento.text = formatBirthDateForDisplay(aluno.dataNascimento);
    _fotoUrl = aluno.fotoUrl;
    _captureBaseline();
    if (mounted) setState(() {});
    _abrirAcaoInicial();
  }

  void _abrirAcaoInicial() {
    final acao = widget.acao;
    if (acao == null || _acaoInicialFeita) return;
    _acaoInicialFeita = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (acao) {
        case PerfilEditarAcao.foto:
          _pickFoto();
        case PerfilEditarAcao.medida:
          _registrarMedida();
      }
    });
  }

  Future<void> _pickFoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final url = await ref.read(alunoRepositoryProvider).uploadMinhaFoto(
        bytes: await file.readAsBytes(),
        filename: file.name,
      );
      if (!mounted) return;
      setState(() => _fotoUrl = url);
      await _save(silent: true);
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _save({bool silent = false}) async {
    FxKeyboardDismissScope.dismiss();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final alunoRepo = ref.read(alunoRepositoryProvider);
      await alunoRepo.atualizarMe({
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'telefone': _mesmoNumero ? _whatsapp.text.trim() : _telefone.text.trim(),
        'whatsapp': _whatsapp.text.trim(),
        'objetivo': _objetivo.text.trim(),
        'genero': _genero.text.trim(),
        'tipoConsultoria': _tipoConsultoria.text.trim(),
        'peso': double.tryParse(_peso.text.trim().replaceAll(',', '.')),
        'altura': double.tryParse(_altura.text.trim().replaceAll(',', '.')),
        'dataNascimento': normalizeBirthDateForApi(_dataNascimento.text),
        'fotoUrl': _fotoUrl,
      });
      ref.invalidate(alunoPerfilHomeProvider);
      ref.invalidate(alunoMeProvider);
      invalidateAlunoDashboardHome(ref);
      _captureBaseline();
      if (!silent && mounted) {
        FeedbackHelper.showSuccess(context, 'Perfil do aluno atualizado.');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _escolher(
    String titulo,
    TextEditingController campo,
    List<({String valor, String rotulo})> opcoes,
  ) async {
    final escolha = await showFxGroupedActionSheet<String>(
      context,
      titulo: titulo,
      grupos: [
        FxActionGroup<String>(null, [
          for (final o in opcoes)
            FxActionItem(
              valor: o.valor,
              rotulo: o.rotulo,
              icone: Icons.chevron_right_rounded,
            ),
        ]),
      ],
    );
    if (escolha != null && mounted) campo.text = escolha;
  }

  String _dataCurta(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _escolherNascimento() async {
    final agora = DateTime.now();
    final atual = DateTime.tryParse(normalizeBirthDateForApi(_dataNascimento.text) ?? '');
    final data = await showDatePicker(
      context: context,
      initialDate: atual ?? DateTime(agora.year - 25),
      firstDate: DateTime(1920),
      lastDate: agora,
      locale: const Locale('pt', 'BR'),
    );
    if (data == null || !mounted) return;
    _dataNascimento.text = formatBirthDateForDisplay(data.toIso8601String());
  }

  Future<void> _registrarMedida() async {
    final formKey = GlobalKey<FormState>();
    var data = DateTime.now();
    String? erroGeral;
    final pesoCtrl = TextEditingController(text: _peso.text.trim());
    final cinturaCtrl = TextEditingController();
    final quadrilCtrl = TextEditingController();
    final bracoCtrl = TextEditingController();
    String? fotoUrl;
    bool saving = false;
    bool uploading = false;

    await showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> selecionarFoto() async {
              final file = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 86,
              );
              if (file == null) return;
              setModalState(() => uploading = true);
              try {
                final url = await MediaUploadService(
                  ref.read(apiClientProvider),
                ).uploadBytes(
                  bytes: await file.readAsBytes(),
                  filename: file.name,
                  folder: 'alunos/evolucao',
                  resourceType: 'image',
                );
                setModalState(() => fotoUrl = url);
              } catch (e) {
                if (mounted) {
                  FeedbackHelper.showError(context, friendlyError(e));
                }
              } finally {
                if (ctx.mounted) {
                  setModalState(() => uploading = false);
                }
              }
            }

            Future<void> escolherData() async {
              final hoje = DateTime.now();
              final nova = await showDatePicker(
                context: ctx,
                initialDate: data,
                firstDate: DateTime(hoje.year - 10),
                lastDate: hoje,
                locale: const Locale('pt', 'BR'),
              );
              if (nova != null) setModalState(() => data = nova);
            }

            Future<void> salvar() async {
              if (!formKey.currentState!.validate()) return;
              final vazia =
                  fotoUrl == null &&
                  [pesoCtrl, cinturaCtrl, quadrilCtrl, bracoCtrl]
                      .every((c) => c.text.trim().isEmpty);
              if (vazia) {
                setModalState(() => erroGeral = 'Preencha uma medida ou adicione uma foto.');
                return;
              }
              setModalState(() {
                erroGeral = null;
                saving = true;
              });
              try {
                final repo = EvolucaoRepository(ref.read(apiClientProvider));
                final peso = double.tryParse(
                  pesoCtrl.text.trim().replaceAll(',', '.'),
                );
                await repo.adicionarMinhaMedida(
                  data: data.toIso8601String().substring(0, 10),
                  peso: peso,
                  cintura: double.tryParse(
                    cinturaCtrl.text.trim().replaceAll(',', '.'),
                  ),
                  quadril: double.tryParse(
                    quadrilCtrl.text.trim().replaceAll(',', '.'),
                  ),
                  braco: double.tryParse(
                    bracoCtrl.text.trim().replaceAll(',', '.'),
                  ),
                  fotoUrl: fotoUrl,
                );
                ref.invalidate(alunoPerfilHomeProvider);
                if (peso != null) {
                  _peso.text = numeroSemZero(peso);
                  await _save(silent: true);
                }
                if (!ctx.mounted || !mounted) return;
                Navigator.of(ctx).pop();
                FeedbackHelper.showSuccess(context, 'Nova medida registrada.');
              } catch (e) {
                if (!mounted) return;
                FeedbackHelper.showError(context, friendlyError(e));
              } finally {
                if (ctx.mounted) {
                  setModalState(() => saving = false);
                }
              }
            }

            return FxHomeSheetSurface(
              isDark: Theme.of(ctx).brightness == Brightness.dark,
              maxHeight:
                  MediaQuery.sizeOf(ctx).height *
                  FxHomeSheetChrome.maxHeightFactor,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FxHomeSheetHandle(
                      isDark: Theme.of(ctx).brightness == Brightness.dark,
                    ),
                    SizedBox(height: TokensStrip.s4),
                    FxHomeSheetHeader(
                      isDark: Theme.of(ctx).brightness == Brightness.dark,
                      title: 'Registrar medida',
                      leading: Icon(
                        Icons.monitor_weight_outlined,
                        color: Theme.of(ctx).colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    FxTonalButton(
                      label: _dataCurta(data),
                      icon: Icons.calendar_today_outlined,
                      compact: true,
                      onPressed: escolherData,
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          MedidaCampo(
                            controller: pesoCtrl,
                            label: 'Peso',
                            sufixo: 'kg',
                            validator: validarPeso,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: MedidaCampo(
                                  controller: cinturaCtrl,
                                  label: 'Cintura',
                                  sufixo: 'cm',
                                  validator: validarCm,
                                ),
                              ),
                              const SizedBox(width: TokensStrip.s2),
                              Expanded(
                                child: MedidaCampo(
                                  controller: quadrilCtrl,
                                  label: 'Quadril',
                                  sufixo: 'cm',
                                  validator: validarCm,
                                ),
                              ),
                              const SizedBox(width: TokensStrip.s2),
                              Expanded(
                                child: MedidaCampo(
                                  controller: bracoCtrl,
                                  label: 'Braço',
                                  sufixo: 'cm',
                                  validator: validarCm,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        FxTonalButton(
                          label: fotoUrl == null ? 'Adicionar foto' : 'Trocar foto',
                          icon: Icons.add_a_photo_outlined,
                          compact: true,
                          loading: uploading,
                          onPressed: uploading ? null : selecionarFoto,
                        ),
                        if (fotoUrl != null) ...[
                          const SizedBox(width: TokensStrip.s3),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(TokensStrip.rSm),
                            child: FxCachedNetworkImage(
                              imageUrl: fotoUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              memCacheWidth: 144,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (erroGeral != null) ...[
                      const SizedBox(height: TokensStrip.s2),
                      Text(
                        erroGeral!,
                        style: FocuxHubTypography.bodyMuted(color: EagleTokens.bad),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FxLiquidPrimaryButton(
                        loading: saving,
                        icon: Icons.check_circle_outline,
                        label: 'Salvar medida',
                        onPressed: saving ? null : salvar,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final homeAsync = ref.watch(alunoPerfilHomeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chrome = ShellChrome.forBrightness(context, isDark);
    final ink = chrome.ink;
    final line = chrome.line;
    final mute = chrome.mute;

    return fxScreenA11yScope(
      label: 'Meu perfil',
      child: FxFormPopGuard(
        dirty: _isDirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Editar cadastro',
            onBack: _cancel,
          ),
          bottomNavigationBar: FxFormStickyBar(
            child: FxLiquidPrimaryButton(
              loading: _saving,
              loadingLabel: 'Salvando…',
              label: _saving ? 'Salvando…' : 'Salvar meu perfil',
              onPressed: _saving || !_isDirty ? null : _save,
            ),
          ),
          body: homeAsync.when(
          loading:
              () => const Padding(
                padding: EdgeInsets.all(TokensStrip.s4),
                child: SkeletonList(count: 6),
              ),
          error:
              (e, _) => FxErrorState(
                chromeOnDark: isDark,
                primary: primary,
                message: friendlyError(e),
                title: FocuxMicrocopy.naoFoiPossivelCarregar,
                onRetry: () => ref.invalidate(alunoPerfilHomeProvider),
              ),
          data: (home) {
            final aluno = home.aluno;
            _loadIfNeeded(aluno);
            return FxKeyboardDismissScope(
              child: Form(
              key: _formKey,
              child: FxContentWidthLimiter(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    FxSettingsLayout.pageInset,
                    8,
                    FxSettingsLayout.pageInset,
                    24 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors:
                              isDark
                                  ? [EagleTokens.darkCardHi, EagleTokens.darkBg]
                                  : [EagleTokens.brandSofter, EagleTokens.card],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 38,
                                    backgroundImage:
                                        _fotoUrl != null && _fotoUrl!.isNotEmpty
                                            ? NetworkImage(_fotoUrl!)
                                            : null,
                                    backgroundColor: BrandPalette.soft(primary),
                                    child:
                                        _fotoUrl == null || _fotoUrl!.isEmpty
                                            ? Text(
                                              aluno.nome.isNotEmpty
                                                  ? aluno.nome[0].toUpperCase()
                                                  : 'A',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            )
                                            : null,
                                  ),
                                  Positioned(
                                    right: -4,
                                    bottom: -4,
                                    child: IconButton.filled(
                                      onPressed: _uploading ? null : _pickFoto,
                                      icon:
                                          _uploading
                                              ? const SizedBox(
                                                width: 15,
                                                height: 15,
                                                child: FxLoading(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                              : const Icon(
                                                Icons.camera_alt,
                                                size: 16,
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      aluno.nome,
                                      style: FocuxHubTypography.pageTitle(
                                        context,
                                        color: ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Quanto mais completo seu perfil, melhor o ajuste do treino.',
                                      style: TextStyle(
                                        color: mute,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    FxSettingsGroup(
                      header: 'Identidade e contato',
                      caption: 'Dados básicos para contato e rotina do aluno.',
                      children: [
                        AlunoInsetFormField(
                          controller: _nome,
                          label: 'Nome',
                          icon: Icons.person_outline,
                          rotuloFlutuante: true,
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Obrigatório.'
                                      : null,
                        ),
                        AlunoInsetFormField(
                          controller: _email,
                          label: 'E-mail',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          rotuloFlutuante: true,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Obrigatório.';
                            }
                            if (!v.contains('@')) return 'E-mail inválido.';
                            return null;
                          },
                        ),
                        AlunoInsetFormField(
                          controller: _whatsapp,
                          label: 'WhatsApp',
                          icon: Icons.chat_outlined,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [BrPhone.formatter()],
                          rotuloFlutuante: true,
                        ),
                        InkWell(
                          onTap:
                              () => setState(() => _mesmoNumero = !_mesmoNumero),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _mesmoNumero,
                                onChanged:
                                    (v) => setState(() => _mesmoNumero = v ?? true),
                              ),
                              Expanded(
                                child: Text(
                                  'É o mesmo número do telefone',
                                  style: FxSettingsLayout.footer(color: mute),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_mesmoNumero)
                          AlunoInsetFormField(
                            controller: _telefone,
                            label: 'Telefone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [BrPhone.formatter()],
                            rotuloFlutuante: true,
                          ),
                        CampoDeEscolha(
                          rotulo: 'Gênero',
                          valor: rotuloDoGenero(_genero.text),
                          icone: Icons.badge_outlined,
                          onTap: () => _escolher('Gênero', _genero, generosDoAluno),
                        ),
                        CampoDeEscolha(
                          rotulo: 'Nascimento',
                          valor: _dataNascimento.text.replaceAll('-', '/'),
                          icone: Icons.cake_outlined,
                          onTap: _escolherNascimento,
                        ),
                      ],
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    FxSettingsGroup(
                      header: 'Corpo e metas',
                      caption:
                          'O que você quer construir e de onde está partindo.',
                      children: [
                        CampoDeEscolha(
                          rotulo: 'Objetivo',
                          valor: _objetivo.text,
                          icone: Icons.flag_outlined,
                          onTap: () => _escolher(
                            'Objetivo',
                            _objetivo,
                            [
                              for (final o in objetivosDoAluno)
                                (valor: o, rotulo: o),
                            ],
                          ),
                        ),
                        AlunoInsetFormField(
                          controller: _altura,
                          label: 'Altura (m)',
                          icon: Icons.height,
                          rotuloFlutuante: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        CampoDeEscolha(
                          rotulo: 'Peso',
                          valor: _peso.text.isEmpty ? '' : '${_peso.text} kg',
                          icone: Icons.monitor_weight_outlined,
                          acao: FxTonalButton(
                            label: 'Registrar',
                            compact: true,
                            onPressed: _registrarMedida,
                          ),
                        ),
                        if (_tipoConsultoria.text.trim().isNotEmpty)
                          CampoDeEscolha(
                            rotulo: 'Consultoria',
                            valor: rotuloDaConsultoria(_tipoConsultoria.text),
                            icone: Icons.fitness_center,
                          ),
                      ],
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    Text(
                      'Esses dados ajudam o personal a ajustar treino, contato, segurança e aderência sem depender de conversa toda hora.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mute, fontSize: 12, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
            ),
            );
          },
          ),
        ),
      ),
    );
  }
}

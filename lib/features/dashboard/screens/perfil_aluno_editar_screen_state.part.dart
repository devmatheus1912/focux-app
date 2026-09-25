part of 'perfil_aluno_editar_screen.dart';

class _PerfilAlunoEditarScreenState extends ConsumerState<PerfilAlunoEditarScreen> {
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
    _telefone.text = aluno.telefone ?? '';
    _whatsapp.text = aluno.whatsapp ?? '';
    _objetivo.text = aluno.objetivo ?? '';
    _genero.text = aluno.genero ?? '';
    _tipoConsultoria.text = aluno.tipoConsultoria ?? '';
    _peso.text = aluno.peso?.toString() ?? '';
    _altura.text = aluno.altura?.toString() ?? '';
    _dataNascimento.text = formatBirthDateForDisplay(aluno.dataNascimento);
    _fotoUrl = aluno.fotoUrl;
    _captureBaseline();
    if (mounted) setState(() {});
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
        'telefone': _telefone.text.trim(),
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
      ref.invalidate(alunoDashboardHomeProvider);
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

  String _formatarDataCurta(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final dia = parsed.day.toString().padLeft(2, '0');
    final mes = parsed.month.toString().padLeft(2, '0');
    return '$dia/$mes/${parsed.year}';
  }

  Future<void> _registrarMedida() async {
    final dataCtrl = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
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

            Future<void> salvar() async {
              setModalState(() => saving = true);
              try {
                final repo = EvolucaoRepository(ref.read(apiClientProvider));
                final peso = double.tryParse(
                  pesoCtrl.text.trim().replaceAll(',', '.'),
                );
                await repo.adicionarMinhaMedida(
                  data: dataCtrl.text.trim(),
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
                  _peso.text = peso.toStringAsFixed(1);
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
                      title: 'Registrar progresso',
                      subtitle:
                          'Atualize peso, medidas e uma foto opcional para acompanhar sua evolucao sem depender do personal.',
                      leading: Icon(
                        Icons.monitor_weight_outlined,
                        color: Theme.of(ctx).colorScheme.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    _Field(
                      controller: dataCtrl,
                      label: 'Data AAAA-MM-DD',
                      icon: Icons.calendar_today_outlined,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: pesoCtrl,
                            label: 'Peso kg',
                            icon: Icons.monitor_weight_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(
                            controller: cinturaCtrl,
                            label: 'Cintura cm',
                            icon: Icons.straighten_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            controller: quadrilCtrl,
                            label: 'Quadril cm',
                            icon: Icons.straighten_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _Field(
                            controller: bracoCtrl,
                            label: 'Braco cm',
                            icon: Icons.fitness_center,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton.icon(
                      onPressed: uploading ? null : selecionarFoto,
                      icon:
                          uploading
                              ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: FxLoading(strokeWidth: 2),
                              )
                              : const Icon(Icons.add_a_photo_outlined),
                      label: Text(
                        fotoUrl == null
                            ? 'Adicionar foto de progresso'
                            : 'Foto de progresso pronta',
                      ),
                    ),
                    if (fotoUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: AspectRatio(
                          aspectRatio: 1.15,
                          child: FxCachedNetworkImage(
                            imageUrl: fotoUrl!,
                            fit: BoxFit.cover,
                            memCacheWidth: 720,
                          ),
                        ),
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
    final freshnessLabel = FxHubFreshness.fromFetchedAt(
      homeAsync.value?.fetchedAt,
    );
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
            subtitle: freshnessLabel,
            onBack: _cancel,
          ),
          bottomNavigationBar: FxFormStickyBar(
            child: FxLiquidPrimaryButton(
              loading: _saving,
              loadingLabel: 'Salvando…',
              label: _saving ? 'Salvando…' : 'Salvar meu perfil',
              onPressed: _saving ? null : _save,
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
            final medidas = home.medidas;
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
                          validator:
                              (v) =>
                                  v == null || v.trim().isEmpty
                                      ? 'Obrigatório.'
                                      : null,
                        ),
                        AlunoInsetFormField(
                          controller: _email,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Obrigatório.';
                            }
                            if (!v.contains('@')) return 'E-mail inválido.';
                            return null;
                          },
                        ),
                        AlunoInsetFormField(
                          controller: _telefone,
                          label: 'Telefone',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        AlunoInsetFormField(
                          controller: _whatsapp,
                          label: 'WhatsApp',
                          icon: Icons.chat_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        AlunoInsetFormField(
                          controller: _genero,
                          label: 'Gênero',
                          icon: Icons.badge_outlined,
                        ),
                        AlunoInsetFormField(
                          controller: _dataNascimento,
                          label: 'Nascimento DD-MM-AAAA',
                          icon: Icons.cake_outlined,
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    FxSettingsGroup(
                      header: 'Corpo e metas',
                      caption:
                          'O que você quer construir e de onde está partindo.',
                      children: [
                        AlunoInsetFormField(
                          controller: _objetivo,
                          label: 'Objetivo principal',
                          icon: Icons.flag_outlined,
                          maxLines: 2,
                        ),
                        AlunoInsetFormField(
                          controller: _tipoConsultoria,
                          label: 'Tipo de consultoria',
                          icon: Icons.fitness_center,
                        ),
                        AlunoInsetFormField(
                          controller: _peso,
                          label: 'Peso kg',
                          icon: Icons.monitor_weight_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        AlunoInsetFormField(
                          controller: _altura,
                          label: 'Altura m',
                          icon: Icons.height,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: FxSettingsLayout.groupGap),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FxSettingsLayout.groupPadH,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progresso corporal',
                                  style: FxSettingsLayout.sectionHeader(
                                    color: mute,
                                  ),
                                ),
                                const SizedBox(
                                  height: FxSettingsLayout.captionAfterHeader,
                                ),
                                Text(
                                  'Medidas, foto de evolução e histórico rápido.',
                                  style: FxSettingsLayout.footer(color: mute),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _registrarMedida,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 44),
                            ),
                            icon: const Icon(Icons.add_chart),
                            label: const Text('Registrar'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: FxSettingsLayout.headerToGroup),
                    FxSettingsGroup(
                      children: [
                        if (medidas.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(TokensStrip.s3),
                            child: FxEmptyState(
                              icon: 'chart',
                              title: 'Histórico corporal vazio',
                              subtitle:
                                  'Registrar a primeira medida melhora acompanhamento, ajuste de carga e conversa com o personal.',
                              action: FxEmptyAction(
                                label: 'Registrar medida',
                                onTap: _registrarMedida,
                              ),
                            ),
                          )
                        else ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              FxSettingsLayout.groupPadH,
                              TokensStrip.s3,
                              FxSettingsLayout.groupPadH,
                              TokensStrip.s2,
                            ),
                            child: Text(
                              'Últimas atualizações',
                              style: TextStyle(
                                color: ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          ...medidas
                              .take(3)
                              .map(
                                (medida) => Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    FxSettingsLayout.groupPadH,
                                    0,
                                    FxSettingsLayout.groupPadH,
                                    TokensStrip.s2,
                                  ),
                                  child: _ProgressEntryCard(
                                    medida: medida,
                                    isDark: isDark,
                                    formatarData: _formatarDataCurta,
                                  ),
                                ),
                              ),
                          const SizedBox(height: TokensStrip.s2),
                        ],
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

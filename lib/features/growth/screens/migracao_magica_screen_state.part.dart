part of 'migracao_magica_screen.dart';

class _MigracaoMagicaScreenState extends ConsumerState<MigracaoMagicaScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isImportingFile = false;
  String? _importedFileLabel;
  Uint8List? _importedPhotoBytes;
  List<MigracaoAlunoLinha>? _alunosEncontrados;
  bool _emptyResult = false;
  MigracaoFonte _fonte = MigracaoFonte.texto;

  bool get _isReviewing =>
      _alunosEncontrados != null && _alunosEncontrados!.isNotEmpty;

  bool get _captureBusy => _isLoading || _isImportingFile;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDraftChanged);
    unawaited(_restoreDraft());
  }

  Future<void> _restoreDraft() async {
    final draft = await MigracaoMagicaDraftCache.load();
    if (!mounted || draft == null) return;
    setState(() {
      _fonte = draft.fonte;
      _controller.text = draft.text;
    });
  }

  void _persistDraft() {
    unawaited(
      MigracaoMagicaDraftCache.save(text: _controller.text, fonte: _fonte),
    );
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
    _persistDraft();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onDraftChanged)
      ..dispose();
    super.dispose();
  }

  void _voltarRevisao() {
    setState(() {
      _alunosEncontrados = null;
      _emptyResult = false;
    });
  }

  void _continuarCaptura() {
    switch (_fonte) {
      case MigracaoFonte.planilha:
        _importarArquivo();
        break;
      case MigracaoFonte.foto:
        _subirFoto();
        break;
      case MigracaoFonte.texto:
        _processarMigracao();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: 'Migração Focux — importar alunos',
      child: FeatureGate(
        featureName: 'Migração Focux',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'iaCopiloto',
        child: _buildContent(context),
      ),
    );
  }

  Duration _motionDuration(BuildContext context) =>
      TokensStrip.prefersReducedMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 280);

  Widget _stagger(
    BuildContext context, {
    required int index,
    required Widget child,
    Key? key,
  }) {
    final reduce = TokensStrip.prefersReducedMotion(context);
    return FxStaggerItem(
      key: key,
      index: index,
      staggerDelay: reduce ? Duration.zero : const Duration(milliseconds: 60),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 400),
      slideOffset: reduce ? 0 : 20,
      child: child,
    );
  }

  Widget _buildContent(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final isDark = chrome.isDark;
    final ink = chrome.ink;
    final mute = chrome.mute;
    final brand = Theme.of(context).colorScheme.primary;
    final brandDeep = BrandPalette.deep(brand);
    final brandSoft = BrandPalette.soft(brand, dark: isDark);
    final brandSofter = BrandPalette.softer(brand, dark: isDark);
    final alunos = _alunosEncontrados;

    return FxFormPopGuard(
      dirty: _hasUnsavedWork,
      onCancel: _handleBack,
      child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Migração Focux',
            subtitle: migracaoEtapaLabel(reviewing: _isReviewing),
            onBack: _handleBack,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como funciona a migração',
                onTap: () => showFxHelpSheet(
                  context,
                  title: 'Migração Focux',
                  subtitle: 'Importe alunos e revise antes de salvar.',
                  tips: const [
                    FxHelpTip(
                      'Importar',
                      'Planilha, texto colado ou foto. A análise de texto não cria ficha ainda.',
                    ),
                    FxHelpTip(
                      'Confirmar',
                      'Só a confirmação grava alunos. Duplicados são ignorados.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: FxWizardStickyBar(
            secondary:
                _isReviewing
                    ? TextButton(
                      onPressed: _isSaving ? null : _voltarRevisao,
                      child: Text(migracaoVoltarLabel()),
                    )
                    : null,
            primary: FxLiquidPrimaryButton(
              label:
                  _isReviewing
                      ? (_isSaving
                          ? migracaoSalvandoLabel()
                          : migracaoSalvarLabel(
                            (alunos ?? const [])
                                .where((a) => !a.duplicado)
                                .length,
                          ))
                      : migracaoContinueCaptureLabel(
                        fonte: _fonte,
                        loading: _captureBusy,
                      ),
              loading: _isReviewing ? _isSaving : _captureBusy,
              onPressed:
                  _isReviewing
                      ? (_isSaving ? null : _salvarAlunos)
                      : (_captureBusy
                          ? null
                          : (_fonte == MigracaoFonte.texto &&
                                  _controller.text.trim().isEmpty
                              ? null
                              : _continuarCaptura)),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              FxSettingsLayout.pageInset,
              TokensStrip.s2,
              FxSettingsLayout.pageInset,
              TokensStrip.s6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text(
                migracaoQuestionTitle(reviewing: _isReviewing),
                style: FocuxHubTypography.sectionTitle(context, color: ink),
              ),
              const SizedBox(height: TokensStrip.s2),
              Text(
                migracaoQuestionCaption(reviewing: _isReviewing),
                style: FocuxHubTypography.bodyMuted(color: mute),
              ),
              if (!_isReviewing) ...[
              const SizedBox(height: FxSettingsLayout.headerToGroup),
              Wrap(
                spacing: TokensStrip.s2,
                runSpacing: TokensStrip.s2,
                children: [
                  for (final fonte in MigracaoFonte.values)
                    FxToggleChip(
                      label: migracaoFonteLabel(fonte),
                      selected: _fonte == fonte,
                      isDark: isDark,
                      showCheckmark: true,
                      onTap: _captureBusy
                          ? null
                          : () {
                            setState(() => _fonte = fonte);
                            _persistDraft();
                          },
                    ),
                ],
              ),
              const SizedBox(height: TokensStrip.s3),
              _stagger(
                context,
                index: 3,
                child: Container(
                  padding: const EdgeInsets.all(TokensStrip.s4),
                  decoration: fxListCardDecoration(context, accent: brand),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Importar dados',
                        style: FocuxHubTypography.cardTitle(color: ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Planilha estruturada vai direto para revisão. Foto usa OCR gratuito no app.',
                        style: TextStyle(
                          fontSize: 12,
                          color: mute,
                          height: 1.35,
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final plano = ref.watch(planoFeaturesProvider).value;
                          if (plano == null || !plano.migracaoFoto) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Foto/print: Pro (${MigracaoFotoLimits.pro}/mês) ou Enterprise (${MigracaoFotoLimits.enterprise}/mês).',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: mute,
                                  height: 1.35,
                                ),
                              ),
                            );
                          }
                          final limite = plano.limiteMigracaoFotoMensal ?? 0;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Fotos este mês: ${plano.migracaoFotosUsadasMes}/$limite · '
                              '${plano.migracaoFotosRestantes} restante(s)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: brand,
                                height: 1.35,
                              ),
                            ),
                          );
                        },
                      ),
                      if (_importedFileLabel != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: brandSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _importedPhotoBytes != null
                                    ? Icons.image_rounded
                                    : Icons.insert_drive_file_rounded,
                                size: 14,
                                color: brand,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _importedFileLabel!,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: brand,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_importedPhotoBytes != null) ...[
                        const SizedBox(height: TokensStrip.s3),
                        Semantics(
                          label: 'Preview do print enviado',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              TokensStrip.rSm,
                            ),
                            child: Image.memory(
                              _importedPhotoBytes!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: TokensStrip.s3),
                      if (_fonte == MigracaoFonte.texto) ...[
                      Semantics(
                        label:
                            'Campo para colar dados desestruturados dos alunos',
                        child: Container(
                          padding: const EdgeInsets.all(TokensStrip.s3),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : brandSofter,
                            borderRadius: BorderRadius.circular(
                              TokensStrip.rSm,
                            ),
                            border: Border.all(
                              color:
                                  isDark
                                      ? EagleTokens.darkLine
                                      : brand.withValues(alpha: 0.18),
                            ),
                          ),
                          child: TextField(
                            controller: _controller,
                            maxLines: 8,
                            minLines: 4,
                            style: AppTypography.mono(
                              fontSize: 13,
                              color: ink,
                              height: 1.6,
                            ),
                            decoration: InputDecoration.collapsed(
                              hintText:
                                  'Beatriz Carvalho — 28 anos — (11)99999-1111 — bia@gmail.com — hipertrofia\n'
                                  'Ou cole texto copiado de print/PDF…',
                              hintStyle: TextStyle(
                                color: mute.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _captureBusy ? null : _colarClipboard,
                        child: Text(migracaoColarLabel()),
                      ),
                      ],
                    ],
                  ),
                ),
              ),
              ],
              AnimatedSwitcher(
                duration: _motionDuration(context),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _buildResultsSection(
                  key: ValueKey('${alunos?.length ?? 0}-$_emptyResult'),
                  isDark: isDark,
                  ink: ink,
                  mute: mute,
                  brand: brand,
                  brandDeep: brandDeep,
                  alunos: alunos,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection({
    required Key key,
    required bool isDark,
    required Color ink,
    required Color mute,
    required Color brand,
    required Color brandDeep,
    required List<MigracaoAlunoLinha>? alunos,
  }) {
    if (_emptyResult) {
      return _stagger(
        context,
        key: key,
        index: 4,
        child: const Padding(
          padding: EdgeInsets.only(top: TokensStrip.s4),
          child: FxEmptyState(
            icon: 'search',
            title: 'Nenhum aluno identificado',
            subtitle:
                'Revise o texto colado e tente novamente com mais linhas ou campos visíveis.',
          ),
        ),
      );
    }

    if (alunos == null || alunos.isEmpty) {
      return SizedBox(key: key);
    }

    return _stagger(
      context,
      key: key,
      index: 4,
      child: Padding(
        padding: const EdgeInsets.only(top: TokensStrip.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              label:
                  '${alunos.length} alunos encontrados para revisão. Toque para editar.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${alunos.length} alunos encontrados',
                    style: FocuxHubTypography.sectionTitle(
                      context,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toque para editar · remova duplicados antes de salvar',
                    style: FocuxHubTypography.bodyMuted(color: mute),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TokensStrip.s3),
            ...alunos.asMap().entries.map((entry) {
              final index = entry.key;
              final aluno = entry.value;
              final nome = aluno.nome.isEmpty ? 'Desconhecido' : aluno.nome;
              final email = aluno.email ?? '';
              final telefone = aluno.telefone ?? '';
              final objetivo = aluno.objetivo ?? '';
              final duplicado = aluno.duplicado;
              final meta = [
                if (email.isNotEmpty) email,
                if (telefone.isNotEmpty) telefone,
                if (objetivo.isNotEmpty) objetivo,
              ].join(' · ');

              return Padding(
                padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                child: Semantics(
                  label:
                      duplicado
                          ? 'Aluno $nome duplicado. $meta. Toque para editar.'
                          : 'Aluno $nome. $meta. Toque para editar.',
                  button: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _editarAluno(index),
                      borderRadius: BorderRadius.circular(TokensStrip.rCard),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: fxListCardDecoration(
                          context,
                          accent: brand,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isDark ? brandDeep : brand,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nome,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (meta.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      meta,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: mute,
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (duplicado) ...[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: EagleTokens.warnSoft,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        'Já cadastrado',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: EagleTokens.warn,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remover da lista',
                              onPressed: () => _removerAluno(index),
                              icon: Icon(
                                Icons.close_rounded,
                                size: 20,
                                color: mute,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: TokensStrip.s3),
          ],
        ),
      ),
    );
  }
}

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

  static const _passos = [
    'Importe planilha, foto/print (OCR no celular) ou cole texto',
    'Revise, edite ou remova linhas antes de confirmar',
    'Confirme e salve: duplicados são ignorados automaticamente',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onDraftChanged);
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onDraftChanged)
      ..dispose();
    super.dispose();
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

    return PopScope(
      canPop: !_hasUnsavedWork,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Migração Focux',
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
              _stagger(
                context,
                index: 0,
                child: Semantics(
                  header: true,
                  label:
                      'Importe alunos com planilha, foto de app concorrente ou texto colado.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : brandSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: brand,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'IA FOCUX',
                            style: TextStyle(
                              fontSize: 12,
                              color: brand,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TokensStrip.s2),
                      Text(
                        'Importe alunos',
                        style: FocuxTypography.display(color: ink).copyWith(
                          fontSize: 28,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Planilha (.csv, .xlsx), print de app concorrente ou texto — '
                        'análise automática no app. Você revisa antes de salvar.',
                        style: TextStyle(
                          fontSize: 14,
                          color: mute,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s3),
              _stagger(
                context,
                index: 1,
                child: Semantics(
                  label:
                      'Dica: prints de apps concorrentes como MFIT e Trainerize podem ser importados por foto.',
                  child: Container(
                    padding: const EdgeInsets.all(TokensStrip.s3),
                    decoration: BoxDecoration(
                      color: brandSofter,
                      borderRadius: BorderRadius.circular(TokensStrip.rSm),
                      border: Border.all(
                        color: brand.withValues(alpha: isDark ? 0.35 : 0.22),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.screenshot_monitor_rounded,
                          color: brand,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Veio de outro app?',
                                style: FocuxHubTypography.cardTitle(color: ink),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Suba um print da lista de alunos (MFIT, Trainerize, Excel, WhatsApp). '
                                'OCR no celular lê a tela — sem redigitar. Pro: '
                                '${MigracaoFotoLimits.pro} fotos/mês · Enterprise: '
                                '${MigracaoFotoLimits.enterprise}/mês.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: mute,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
              _stagger(
                context,
                index: 2,
                child: Semantics(
                  label: 'Como funciona em três passos',
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s5,
                      20,
                      TokensStrip.s5,
                      18,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient:
                          isDark
                              ? LinearGradient(
                                colors: [brandDeep, EagleTokens.cinematicBg],
                              )
                              : LinearGradient(colors: [brand, brandDeep]),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Como funciona',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._passos.asMap().entries.map((entry) {
                          return Semantics(
                            label: 'Passo ${entry.key + 1}. ${entry.value}',
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: AppTypography.mono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.88,
                                        ),
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: TokensStrip.s4),
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
                      FxSettingsGroup(
                        children: [
                          FxSettingsTile(
                            fxIcon: 'article',
                            label: _isImportingFile
                                ? migracaoPlanilhaLendoLabel()
                                : migracaoPlanilhaLabel(),
                            value: '',
                            accent: brand,
                            mute: mute,
                            onTap: (_isLoading || _isImportingFile)
                                ? () {}
                                : _importarArquivo,
                          ),
                          FxSettingsTile(
                            fxIcon: 'spark',
                            label: migracaoColarLabel(),
                            value: '',
                            accent: brand,
                            mute: mute,
                            onTap: _isLoading ? () {} : _colarClipboard,
                          ),
                          FxSettingsTile(
                            fxIcon: 'plus',
                            label: _isLoading && _importedPhotoBytes != null
                                ? migracaoFotoLendoLabel()
                                : migracaoFotoLabel(),
                            value: '',
                            showDivider: false,
                            accent: brand,
                            mute: mute,
                            semanticsLabel:
                                'Subir foto ou print de app concorrente',
                            onTap: (_isLoading || _isImportingFile)
                                ? () {}
                                : _subirFoto,
                          ),
                        ],
                      ),
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
                      if (_controller.text.trim().isNotEmpty) ...[
                        const SizedBox(height: TokensStrip.s3),
                        FxSettingsGroup(
                          children: [
                            FxSettingsTile(
                              fxIcon: 'spark',
                              label: _isLoading && _importedPhotoBytes == null
                                  ? migracaoIniciarAnalisandoLabel()
                                  : migracaoIniciarLabel(),
                              value: '',
                              showDivider: false,
                              highlight: true,
                              accent: brand,
                              mute: mute,
                              onTap: (_isLoading && _importedPhotoBytes == null)
                                  ? () {}
                                  : _processarMigracao,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
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
            FxSettingsGroup(
              children: [
                FxSettingsTile(
                  fxIcon: 'circle-check',
                  label: _isSaving
                      ? migracaoSalvandoLabel()
                      : migracaoSalvarLabel(
                          alunos.where((a) => !a.duplicado).length,
                        ),
                  value: '',
                  showDivider: false,
                  highlight: true,
                  accent: brand,
                  mute: mute,
                  onTap: _isSaving ? () {} : _salvarAlunos,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

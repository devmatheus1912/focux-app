part of 'ia_copiloto_screen.dart';

extension IaCopilotoScreenBuild on _IaCopilotoScreenState {
  Widget buildIaCopilotoBody(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final dark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final primarySoft = BrandPalette.soft(primary, dark: dark);
    final primaryAccent = BrandPalette.accent(primary);
    final primaryDeep = BrandPalette.deep(primary);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final line = chrome.line;
    final brand = dark ? primaryAccent : primary;
    final freshnessLabel = FxHubFreshness.fromFetchedAt(_fetchedAt);
    final homeAsync = ref.watch(iaCopilotoHomeProvider);
    final home = homeAsync.valueOrNull;
    final planoFromHome = home?.planoFeatures;
    if (planoFromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
      });
    }
    final quotaLabel = _quotaHeaderLabel(planoFromHome);

    return fxScreenA11yScope(
      label: 'Copiloto',
      child: FeatureGate(
        featureName: 'Copiloto IA',
        requiredPlan: SubscriptionPlan.PREMIUM,
        capability: 'iaCopiloto',
        child: FxShellScaffold(
          useMesh: true,
          safeArea: false,
          appBar: FxShellAppBar(
            title: 'Copiloto',
            subtitle: 'IA FOCUX',
            onBack: () => safePopOr(context, () => goToRoleHome(context, ref)),
            actions: [
              IaCopilotHeaderStatus(
                dark: dark,
                brand: brand,
                line: line,
                ink: ink,
                quotaLabel: quotaLabel,
              ),
            ],
          ),
          bottomNavigationBar:
              _gerado
                  ? IaCopilotResultActionBar(
                    brand: brand,
                    ink: ink,
                    onCreateTask: _atribuir,
                    onMore: _abrirMenu,
                  )
                  : null,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              clipBehavior: Clip.hardEdge,
              padding: EdgeInsets.only(bottom: _gerado ? 108 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: TokensStrip.s3),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      12,
                    ),
                    child:
                        homeAsync.hasError
                            ? FxErrorState(
                              chromeOnDark: dark,
                              primary: brand,
                              message: friendlyError(
                                homeAsync.error!,
                                fallback:
                                    'Não foi possível carregar alunos e cota.',
                              ),
                              onRetry:
                                  () => ref.invalidate(iaCopilotoHomeProvider),
                            )
                            : IaCopilotStudentSelector(
                              alunoNome: _selectedAlunoNome,
                              brand: brand,
                              ink: ink,
                              mute: mute,
                              onTap: _selecionarAluno,
                            ),
                  ),

                  // Mode selector
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      14,
                    ),
                    child: IaCopilotModeSelector(
                      modes: _modes,
                      selectedIndex: _modeIdx,
                      brand: brand,
                      dark: dark,
                      line: line,
                      mute: mute,
                      onSelect: (index) => setState(() => _modeIdx = index),
                    ),
                  ),

                  // Contexto e preparo
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      14,
                    ),
                    child: IaCopilotReadinessCard(
                      headline: _readinessHeadline,
                      modeDisplay: _modeDisplay,
                      icon: _modeIcon,
                      promise: _modePromise,
                      checks: _modeChecks,
                      alunoNome: _selectedAlunoNome,
                      recoveryAsync:
                          _selectedAlunoId == null
                              ? null
                              : ref.watch(
                                copilotRecoveryProvider(_selectedAlunoId!),
                              ),
                    ),
                  ),

                  // Safety disclaimer
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      12,
                    ),
                    child: IaCopilotSafetyNote(
                      ink: ink,
                      mute: mute,
                      brand: brand,
                    ),
                  ),

                  // Generate button / progress
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      TokensStrip.s4,
                      0,
                      16,
                      18,
                    ),
                    child:
                        !_gerado && !_gerando
                            ? IaCopilotPrimaryAction(
                              label: 'Gerar $_modeDisplay',
                              icon: _modeIcon,
                              brand: brand,
                              primaryDeep: primaryDeep,
                              onTap: _gerar,
                            )
                            : IaCopilotGenerationStatus(
                              gerando: _gerando,
                              gerado: _gerado,
                              elapsedMs: _geracaoMs,
                              mode: _modeDisplay,
                              ink: ink,
                              mute: mute,
                              primarySoft: primarySoft,
                            ),
                  ),

                  if (!_gerado && !_gerando && _erro == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        0,
                        16,
                        18,
                      ),
                      child: IaCopilotPreviewCard(
                        howItWorks: _howItWorksPreview,
                        brand: brand,
                        ink: ink,
                        mute: mute,
                        checks: _modeChecks,
                      ),
                    ),

                  // Result card — vinculado ao backend (/api/ia/copiloto/insights)
                  if (_erro != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        0,
                        16,
                        16,
                      ),
                      child: FxErrorState(
                        chromeOnDark: dark,
                        primary: brand,
                        message: _erroIaTexto(_erro!),
                        icon: Icons.error_outline_rounded,
                        onRetry:
                            _erroSugereUpgrade(_erro!)
                                ? _mostrarUpgradePorErro
                                : _gerar,
                        retryLabel:
                            _erroSugereUpgrade(_erro!) ? 'Fazer upgrade' : null,
                        retryIcon:
                            _erroSugereUpgrade(_erro!)
                                ? Icons.workspace_premium_rounded
                                : Icons.refresh_rounded,
                      ),
                    ),
                  ] else if (_gerado) ...[
                    Consumer(
                      builder: (context, ref, _) {
                        final query = InsightsQuery(
                          alunoId: _selectedAlunoId,
                          mode: _mode,
                        );
                        final insightsAsync = ref.watch(
                          insightsProvider(query),
                        );
                        return insightsAsync.when(
                          loading:
                              () => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  TokensStrip.s4,
                                  0,
                                  16,
                                  16,
                                ),
                                child: IaCopilotInsightsLoading(
                                  ink: ink,
                                  mute: mute,
                                  brand: brand,
                                ),
                              ),
                          error:
                              (e, _) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  TokensStrip.s4,
                                  0,
                                  16,
                                  16,
                                ),
                                child: FxErrorState(
                                  chromeOnDark: dark,
                                  primary: brand,
                                  message: _erroIaTexto(e),
                                  icon: Icons.error_outline_rounded,
                                  onRetry:
                                      () => ref.invalidate(
                                        insightsProvider(query),
                                      ),
                                ),
                              ),
                          data: (insights) {
                            final degraded = insights.any((insight) {
                              final status =
                                  (insight['status'] ?? 'READY').toString();
                              return status != 'READY';
                            });
                            if (insights.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  TokensStrip.s4,
                                  0,
                                  16,
                                  16,
                                ),
                                child: FxEmptyState(
                                  icon: 'spark',
                                  title: 'Sem insights no momento',
                                  subtitle:
                                      'Adicione mais treinos e check-ins para que a IA gere recomendações personalizadas.',
                                  action: FxEmptyAction(
                                    label: 'Gerar novamente',
                                    onTap: _gerar,
                                  ),
                                ),
                              );
                            }
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                TokensStrip.s4,
                                0,
                                16,
                                16,
                              ),
                              child: Container(
                                decoration: fxListCardDecoration(
                                  context,
                                  accent: primary,
                                  radius: 22,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        18,
                                        18,
                                        16,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors:
                                              dark
                                                  ? [
                                                    primaryDeep,
                                                    BrandPalette.deep(
                                                      primaryDeep,
                                                    ),
                                                  ]
                                                  : [primary, primaryDeep],
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'INSIGHTS · ${_mode.toUpperCase()}',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.7,
                                              ),
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          SizedBox(height: TokensStrip.s2),
                                          Text(
                                            '${insights.length} recomendações geradas',
                                            style:
                                                FocuxHubTypography.cardTitle(
                                              color: Colors.white,
                                            ).copyWith(height: 1.2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (degraded)
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          12,
                                          16,
                                          12,
                                        ),
                                        color: const Color(
                                          0xFFFFB020,
                                        ).withValues(alpha: 0.12),
                                        child: Text(
                                          'A IA respondeu fora do formato ideal. Mantivemos as recomendações para revisão manual.',
                                          style: TextStyle(
                                            color: ink,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ...insights.asMap().entries.map((e) {
                                      final ins = e.value;
                                      return IaCopilotInsightItem(
                                        index: e.key,
                                        insight: ins,
                                        isLast: e.key == insights.length - 1,
                                        highlighted: e.key == 0,
                                        line: line,
                                        primarySoft: primarySoft,
                                        brand: brand,
                                        ink: ink,
                                        mute: mute,
                                        chipBg:
                                            dark
                                                ? Colors.white.withValues(
                                                  alpha: 0.06,
                                                )
                                                : TokensStrip.borderDefault,
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        0,
                        16,
                        12,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: fxListCardDecoration(
                        context,
                        accent: brand,
                        radius: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, size: 16, color: brand),
                          SizedBox(width: TokensStrip.s2),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _resultNote,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color:
                                        dark
                                            ? EagleTokens.darkInk
                                            : EagleTokens.inkSoft,
                                    height: 1.45,
                                  ),
                                ),
                                if (freshnessLabel != null) ...[
                                  SizedBox(height: TokensStrip.s2),
                                  Text(
                                    freshnessLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: mute,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_tarefaCriada && _proximaAcao != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          TokensStrip.s4,
                          12,
                          16,
                          0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: fxListCardDecoration(
                            context,
                            accent: brand,
                            radius: 14,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _tarefaPersistida
                                        ? Icons.check_circle_outline
                                        : Icons.sync_problem_outlined,
                                    color: brand,
                                    size: 17,
                                  ),
                                  SizedBox(width: TokensStrip.s2),
                                  Expanded(
                                    child: Text(
                                      _tarefaPersistida
                                          ? 'Tarefa salva no ${FocuxMicrocopy.commandCenter}'
                                          : 'Tarefa criada, verifique a lista',
                                      style: TextStyle(
                                        color: ink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  IaCopilotTinyTypeChip(
                                    label: _proximaAcao!.statusLabel,
                                    color: brand,
                                    background: Colors.white.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: TokensStrip.s2),
                              Text(
                                _proximaAcao!.displayText,
                                style: TextStyle(
                                  color: mute,
                                  fontSize: 12.3,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: TokensStrip.s3),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          () => context.push(
                                            '/dashboard/command-center/copiloto',
                                          ),
                                      icon: const Icon(
                                        Icons.space_dashboard_outlined,
                                        size: 16,
                                      ),
                                      label: const Text('Ver tarefa'),
                                    ),
                                  ),
                                  SizedBox(width: TokensStrip.s2),
                                  Expanded(
                                    child: FxLiquidPrimaryButton(
                                      label: 'Abrir aluno',
                                      icon: Icons.person_outline,
                                      expand: true,
                                      onPressed:
                                          _selectedAlunoId == null
                                              ? null
                                              : () => context.push(
                                                '/alunos/$_selectedAlunoId',
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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

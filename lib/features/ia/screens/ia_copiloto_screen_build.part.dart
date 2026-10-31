part of 'ia_copiloto_screen.dart';

extension IaCopilotoScreenBuild on _IaCopilotoScreenState {
  Widget buildIaCopilotoBody(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final dark = chrome.isDark;
    final primary = Theme.of(context).colorScheme.primary;
    final brand = BrandPalette.softened(primary);
    final wash = primary.withValues(alpha: dark ? 0.16 : 0.10);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final homeAsync = ref.watch(iaCopilotoHomeProvider);
    final home = homeAsync.value;
    final tarefas = ref.watch(copilotoTarefasAbertasProvider).value;
    final planoFromHome = home?.planoFeatures;
    if (planoFromHome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        try {
          ref.read(planoFeaturesProvider.notifier).seedFromHome(planoFromHome);
        } on StateError catch (e) {
          // QA route cycling can dispose the element before this frame runs.
          if (!e.message.contains('ref')) rethrow;
        }
      });
    }
    final cotaEsgotada = planoFromHome?.iaQuotaEsgotada ?? false;

    if (home != null && !_viewTracked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _viewTracked) return;
        _viewTracked = true;
        AnalyticsService.instance.track(
          ProductEvents.iaCopilotoViewed,
          props: {'mode': _mode},
        );
        if (!_ttvTracked) {
          _ttvTracked = true;
          AnalyticsService.instance.track(
            ProductEvents.iaCopilotoTtv,
            props: {
              'ms': DateTime.now().difference(_openedAt).inMilliseconds,
              'mode': _mode,
            },
          );
        }
      });
    }

    return fxScreenA11yScope(
      label: 'Copiloto',
      child: PopScope(
        canPop: !_gerado,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _voltarAoInicio();
        },
        child: FeatureGate(
        featureName: 'Copiloto IA',
        requiredPlan: SubscriptionPlan.PRO,
        capability: 'iaCopiloto',
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          safeArea: false,
          appBar: FxShellAppBar(
            title: 'Copiloto',
            subtitle: _gerado ? _selectedAlunoNome : null,
            showBack: _gerado,
            onBack: _voltarAoInicio,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como usar o Copiloto',
                onTap: () {
                  AnalyticsService.instance.track(
                    ProductEvents.iaCopilotoHelpOpened,
                  );
                  showIaCopilotoHelpSheet(context);
                },
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                FxContentWidthLimiter(
                  child: SingleChildScrollView(
                    clipBehavior: Clip.hardEdge,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom:
                          _gerado
                              ? IaCopilotResultActionBar.scrollReserve
                              : 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    SizedBox(height: TokensStrip.s3),

                    if (!_gerado) ...[
                      if (planoFromHome case final plano?
                          when (plano.limiteIaMensal ?? 0) > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            0,
                            FxSettingsLayout.pageInset,
                            TokensStrip.s4,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              IaUsoLinha(
                                usado: plano.iaUsadaMes,
                                limite: plano.limiteIaMensal!,
                              ),
                              if (cotaEsgotada) ...[
                                const SizedBox(height: TokensStrip.s3),
                                _cotaEsgotadaCard(plano),
                              ],
                            ],
                          ),
                        ),
                      if (homeAsync.hasError)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            0,
                            FxSettingsLayout.pageInset,
                            12,
                          ),
                          child: FxErrorState(
                            chromeOnDark: dark,
                            primary: brand,
                            message: friendlyError(
                              homeAsync.error!,
                              fallback:
                                  'Não foi possível carregar alunos e cota.',
                            ),
                            onRetry:
                                () => ref.invalidate(iaCopilotoHomeProvider),
                          ),
                        )
                      else if (!_gerando)
                        Semantics(
                          hint: iaCopilotoComoCalculamos,
                          child: CopilotoCardView(
                            prioridades: copilotoPrioridades(
                              tarefas?.itens ?? const [],
                              {
                                for (final a in home?.alunosResumo ?? const <IaCopilotoAlunoResumo>[])
                                  a.id: a.nome,
                              },
                            ),
                            tarefasAbertas: tarefas?.totalItens ?? 0,
                            alunoNome: _selectedAlunoNome,
                            podeAnalisar: !cotaEsgotada,
                            onAnalisar: _analisar,
                            onAnalisarSelecionado: _gerar,
                            onEscolherAluno: _selecionarAluno,
                            onVerTarefas:
                                () => context.push(
                                  '/dashboard/command-center/copiloto',
                                ),
                          ),
                        ),
                    ],

                    if (_gerando)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          0,
                          FxSettingsLayout.pageInset,
                          18,
                        ),
                        child: IaCopilotGenerationStatus(
                          gerando: _gerando,
                          gerado: false,
                          elapsedMs: _geracaoMs,
                          ink: ink,
                          mute: mute,
                          wash: wash,
                        ),
                      ),

                    // Resultado — Insights above the fold (pilar 13); sticky = único P0.
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
                                  : () => _gerar(refazer: true),
                          retryLabel:
                              _erroSugereUpgrade(_erro!)
                                  ? 'Fazer upgrade'
                                  : null,
                          retryIcon:
                              _erroSugereUpgrade(_erro!)
                                  ? Icons.workspace_premium_rounded
                                  : Icons.refresh_rounded,
                        ),
                      ),
                    ] else if (_gerado) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          0,
                          FxSettingsLayout.pageInset,
                          TokensStrip.s3,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedAlunoNome ?? '',
                                    style: FocuxHubTypography.pageTitle(
                                      context,
                                      color: ink,
                                    ),
                                  ),
                                  if (_proximaAcao?.motivo case final motivo?
                                      when motivo.trim().isNotEmpty) ...[
                                    const SizedBox(height: TokensStrip.s1),
                                    Text(
                                      motivo.trim(),
                                      style: FocuxHubTypography.bodyMuted(
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
                              final degraded = insights.any(
                                (insight) => !insight.ready,
                              );
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
                                      onTap: () => _gerar(refazer: true),
                                    ),
                                  ),
                                );
                              }
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  FxSettingsLayout.pageInset,
                                  0,
                                  FxSettingsLayout.pageInset,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (degraded) ...[
                                      Text(
                                        'A IA respondeu fora do formato ideal. Mantivemos as recomendações para revisão manual.',
                                        style: FocuxHubTypography.bodyMuted(
                                          color: mute,
                                        ),
                                      ),
                                      const SizedBox(height: TokensStrip.s3),
                                    ],
                                    for (final e in insights.asMap().entries)
                                      IaCopilotInsightItem(
                                        index: e.key,
                                        insight: e.value,
                                        brand: brand,
                                        mute: mute,
                                      ),
                                    const SizedBox(height: TokensStrip.s2),
                                    const IaSafetyDisclaimer(compact: true),
                                    const SizedBox(height: TokensStrip.s3),
                                    FxTonalButton(
                                      label: S.of(context).copilotoAnalisarOutro,
                                      expanded: true,
                                      onPressed: _voltarAoInicio,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
                if (_gerado)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IaCopilotResultActionBar(
                      brand: brand,
                      primaryLabel: _resultPrimaryLabel,
                      onPrimary: _resultPrimaryAction,
                      onMore: _abrirMenu,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

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
    final line = chrome.line;
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
            subtitle: freshnessLabel ?? 'IA FOCUX',
            showBack: false,
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
              SizedBox(width: FxHelpChrome.gap),
              IaCopilotHeaderStatus(
                dark: dark,
                brand: brand,
                line: line,
                ink: ink,
                quotaLabel: quotaLabel,
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
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

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        0,
                        FxSettingsLayout.pageInset,
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
                                    () =>
                                        ref.invalidate(iaCopilotoHomeProvider),
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
                        FxSettingsLayout.pageInset,
                        0,
                        FxSettingsLayout.pageInset,
                        14,
                      ),
                      child: IaCopilotModeSelector(
                        modes: _modes,
                        selectedIndex: _modeIdx,
                        brand: brand,
                        dark: dark,
                        line: line,
                        mute: mute,
                        onSelect: (index) {
                          if (index == _modeIdx) return;
                          AnalyticsService.instance.track(
                            ProductEvents.iaCopilotoModeChanged,
                            props: {'from': _mode, 'to': _modes[index]},
                          );
                          setState(() => _modeIdx = index);
                        },
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
                        FxSettingsLayout.pageInset,
                        0,
                        FxSettingsLayout.pageInset,
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
                        FxSettingsLayout.pageInset,
                        0,
                        FxSettingsLayout.pageInset,
                        18,
                      ),
                      child:
                          !_gerado && !_gerando
                              ? IaCopilotPrimaryAction(
                                label: iaCopilotoGerarLabel(_modeDisplay),
                                brand: brand,
                                onTap: _gerar,
                              )
                              : IaCopilotGenerationStatus(
                                gerando: _gerando,
                                gerado: _gerado,
                                elapsedMs: _geracaoMs,
                                mode: _modeDisplay,
                                ink: ink,
                                mute: mute,
                                wash: wash,
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
                                      onTap: _gerar,
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
                                    DashboardSectionHeader(
                                      title: 'Insights · $_modeDisplay',
                                    ),
                                    const SizedBox(height: TokensStrip.s2),
                                    Text(
                                      degraded
                                          ? 'A IA respondeu fora do formato ideal. Mantivemos as recomendações para revisão manual.'
                                          : '${insights.length} recomendações geradas',
                                      style: TextStyle(
                                        color: mute,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: TokensStrip.s3),
                                    for (final e in insights.asMap().entries)
                                      IaCopilotInsightItem(
                                        index: e.key,
                                        insight: e.value,
                                        highlighted: e.key == 0,
                                        brand: brand,
                                        mute: mute,
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          0,
                          FxSettingsLayout.pageInset,
                          12,
                        ),
                        child: Text(
                          [
                            if (freshnessLabel != null &&
                                freshnessLabel.trim().isNotEmpty)
                              freshnessLabel,
                            _resultNote,
                          ].where((s) => s.trim().isNotEmpty).join(' · '),
                          style: TextStyle(
                            color: mute,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_tarefaCriada && _proximaAcao != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            FxSettingsLayout.pageInset,
                            12,
                            FxSettingsLayout.pageInset,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DashboardSectionHeader(
                                title:
                                    _tarefaPersistida
                                        ? 'Tarefa salva no ${FocuxMicrocopy.commandCenter}'
                                        : 'Tarefa criada, verifique a lista',
                              ),
                              const SizedBox(height: TokensStrip.s3),
                              FxSatelliteListTile(
                                title: _proximaAcao!.displayText,
                                subtitle: Text(_proximaAcao!.statusLabel),
                                accent: brand,
                                onTap:
                                    () => context.push(
                                      '/dashboard/command-center/copiloto',
                                    ),
                              ),
                              FxSatelliteListTile(
                                title: iaCopilotoVerTarefaLabel(),
                                onTap:
                                    () => context.push(
                                      '/dashboard/command-center/copiloto',
                                    ),
                              ),
                              if (_selectedAlunoId != null)
                                FxSatelliteListTile(
                                  title: iaCopilotoAbrirAlunoLabel(),
                                  onTap:
                                      () => context.push(
                                        '/alunos/$_selectedAlunoId',
                                      ),
                                ),
                            ],
                          ),
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
                      onMore:
                          () => _abrirMenu(
                            includeCreateTask: _resultUsesApplyOrProgressao,
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

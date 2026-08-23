part of 'landing_editor_screen.dart';

class _LandingEditorScreenState extends ConsumerState<LandingEditorScreen> {
  late final LandingEditorController _c = LandingEditorController(
    onStateChanged: () {
      if (!mounted) return;
      setState(() {});
      _syncReviewCelebration();
    },
  );

  @override
  void initState() {
    super.initState();
    _c.attachTextListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGrowth());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final perfil = perfilAsync.valueOrNull;
    if (perfil != null && !_c.loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _c.applyPerfil(perfil));
      });
    }

    return fxScreenA11yScope(
      label: 'Editor da landing',
      child: FeatureGate(
        requiredPlan: SubscriptionPlan.ENTERPRISE_PRO,
        capability: 'landingCompleta',
        featureName: 'Landing page completa',
        child: PopScope(
          canPop: !_c.dirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _tryPopAfterLeaveConfirm();
          },
          child: FxShellScaffold(
            useMesh: true,
            appBar: FxShellAppBar(
              title: 'Editor da landing',
              subtitle: _c.dirty ? 'Alterações pendentes' : null,
              onBack: _tryPopAfterLeaveConfirm,
            ),
            bottomNavigationBar:
                perfil == null
                    ? null
                    : LandingStickySaveBar(
                      dirty: _c.dirty,
                      saving: _c.saving,
                      onSave: _salvar,
                    ),
            body:
                perfil == null
                    ? (perfilAsync.hasError
                        ? FxErrorState(
                          chromeOnDark:
                              Theme.of(context).brightness == Brightness.dark,
                          primary: Theme.of(context).colorScheme.primary,
                          message: friendlyError(perfilAsync.error!),
                          onRetry: () => ref.invalidate(perfilProvider),
                        )
                        : const SkeletonList(count: 6))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_c.loaded)
                      LandingContentWarningBanner(
                        reviewCount: _c.contentReviewCount(),
                        configComplete:
                            _c.checklist.isNotEmpty &&
                            _c.checklist.every((item) => item.done),
                        onReview: () => _enterReviewFocus(),
                      ),
                    LandingEditorTabBar(
                      index: _c.tabIndex,
                      onChanged: (value) => setState(() => _c.tabIndex = value),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: offsetAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: switch (_c.tabIndex) {
                          0 => KeyedSubtree(
                            key: const ValueKey('tab-links'),
                            child: LandingEditorLinksTab(
                              controller: _c,
                              onReviewFocus: () => _enterReviewFocus(),
                              onChecklistTap: _onChecklistTap,
                              onApplyTemplate: _applyTemplate,
                            ),
                          ),
                          1 => KeyedSubtree(
                            key: const ValueKey('tab-conteudo'),
                            child: LandingEditorContentTab(
                              controller: _c,
                              onGenerateHero: _generateHero,
                              onUploadHero: () => _uploadImage(hero: true),
                              onUploadBio: () => _uploadImage(hero: false),
                              onRemoveHero: () => _removeImage(hero: true),
                              onRemoveBio: () => _removeImage(hero: false),
                              onUseDefaultHero:
                                  () => _useDefaultImage(hero: true),
                              onUseDefaultBio:
                                  () => _useDefaultImage(hero: false),
                              onMarkDirty: () => _c.markDirty(),
                              onHeroExpandedChanged:
                                  (v) => setState(() => _c.heroExpanded = v),
                              onCoverExpandedChanged:
                                  (v) => setState(() => _c.coverExpanded = v),
                              onPreviewLanding: () {
                                final slug = _c.slug;
                                if (slug == null || slug.isEmpty) return;
                                openLandingLink(
                                  context,
                                  url: Env.landingPageUrl(slug),
                                );
                              },
                              onCtasExpandedChanged:
                                  (v) => setState(() => _c.ctasExpanded = v),
                              onServicosExpandedChanged:
                                  (v) =>
                                      setState(() => _c.servicosExpanded = v),
                              onFaqExpandedChanged:
                                  (v) => setState(() => _c.faqExpanded = v),
                              onAddServico:
                                  () => setState(() => _c.addServico()),
                              onRemoveServico: _removeServico,
                              onUpdateServico:
                                  (i, {titulo, descricao}) => setState(
                                    () => _c.updateServico(
                                      i,
                                      titulo: titulo,
                                      descricao: descricao,
                                    ),
                                  ),
                              onAddFaq: () => setState(() => _c.addFaq()),
                              onRemoveFaq: _removeFaq,
                              onUpdateFaq:
                                  (i, {pergunta, resposta}) => setState(
                                    () => _c.updateFaq(
                                      i,
                                      pergunta: pergunta,
                                      resposta: resposta,
                                    ),
                                  ),
                              onExitReviewFocus: _exitReviewFocus,
                              onJumpToSection: _jumpToContentSection,
                            ),
                          ),
                          _ => KeyedSubtree(
                            key: const ValueKey('tab-ordem'),
                            child: LandingEditorOrderTab(
                              controller: _c,
                              onReorder: (old, newIndex) {
                                setState(
                                  () => _c.reorderSection(
                                    old,
                                    newIndex,
                                    onHighlightEnd: () {
                                      if (mounted) _c.clearSectionHighlight();
                                    },
                                  ),
                                );
                              },
                              onMoveUp: (i) {
                                setState(
                                  () => _c.moveSection(
                                    i,
                                    -1,
                                    onHighlightEnd: () {
                                      if (mounted) _c.clearSectionHighlight();
                                    },
                                  ),
                                );
                              },
                              onMoveDown: (i) {
                                setState(
                                  () => _c.moveSection(
                                    i,
                                    1,
                                    onHighlightEnd: () {
                                      if (mounted) _c.clearSectionHighlight();
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                        },
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

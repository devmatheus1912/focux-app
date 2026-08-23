part of 'landing_editor_screen.dart';

extension LandingEditorScreenActions on _LandingEditorScreenState {
  void _syncReviewCelebration() {
    if (!_c.loaded || !mounted) return;
    final count = _c.contentReviewCount();
    if (_c.lastReviewCount > 0 && count == 0 && !_c.celebrationShownForClear) {
      _c.celebrationShownForClear = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        FxCelebrationOverlay.show(
          context,
          title: 'Landing pronta!',
          subtitle: 'Todos os textos revisados. Pode publicar com confiança.',
          icon: Icons.verified_rounded,
          accent: EagleTokens.good,
        );
      });
    }
    if (count > 0) _c.celebrationShownForClear = false;
    if (count == 0 && _c.reviewFocusMode) _c.reviewFocusMode = false;
    _c.lastReviewCount = count;
  }

  Future<void> _loadGrowth() async {
    try {
      final repo = ref.read(landingGrowthRepositoryProvider);
      final presets = await repo.presets();
      final checklist = await repo.checklist();
      if (!mounted) return;
      setState(() {
        _c.presets = presets;
        _c.checklist = checklist;
        _c.checklistLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _c.checklistLoading = false);
    }
  }

  void _enterReviewFocus({LandingContentIssue? jumpTo}) {
    final issues = _c.contentIssuesForReview();
    if (issues.isEmpty) return;
    setState(() {
      _c.reviewFocusMode = true;
      _c.tabIndex = 1;
      _c.heroExpanded = _c.focusHeroIssue();
      _c.faqExpanded = _c.focusFaqIndices().isNotEmpty;
      _c.servicosExpanded = false;
      _c.ctasExpanded = false;
    });
    final target = jumpTo ?? issues.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateContentIssue(target);
    });
  }

  void _exitReviewFocus() => setState(() => _c.reviewFocusMode = false);

  void _navigateContentIssue(LandingContentIssue issue) {
    switch (issue.id) {
      case 'hero':
      case 'cta':
      case 'cta_accent':
        setState(() {
          _c.tabIndex = 1;
          _c.heroExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(_c.heroSectionKey);
        });
      case 'faq':
        final index = issue.faqIndex;
        setState(() {
          _c.tabIndex = 1;
          _c.faqExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (index != null) {
            await _scrollToSection(_c.faqKeyFor(index));
            _c.pulseFaqHighlight(
              index,
              onHighlightEnd: () {
                if (mounted) _c.clearFaqHighlight();
              },
            );
          } else {
            await _scrollToSection(_c.faqSectionKey);
          }
        });
    }
  }

  void _openContentReview() {
    final issues = _c.contentIssuesForReview();
    if (issues.isEmpty) return;
    showLandingContentReviewSheet(
      context,
      issues: issues,
      onIssueTap: _navigateContentIssue,
      onFocusMode: () => _enterReviewFocus(),
    );
  }

  void _jumpToContentSection(LandingEditorContentSection section) {
    setState(() {
      _c.tabIndex = 1;
      _c.expandForContentSection(section);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSection(_c.keyForContentSection(section));
    });
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    final ctx = key.currentContext;
    if (ctx == null || !ctx.mounted) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      alignment: 0.06,
    );
  }

  void _onChecklistTap(LandingChecklistItem item) {
    final target = landingChecklistTarget(item.id);
    if (target == null) return;

    switch (target) {
      case LandingChecklistTarget.linksTab:
        setState(() => _c.tabIndex = 0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(_c.capturaCardKey);
        });
      case LandingChecklistTarget.conteudoHero:
        setState(() {
          _c.tabIndex = 1;
          _c.heroExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(_c.heroSectionKey);
        });
      case LandingChecklistTarget.conteudoServicos:
        setState(() {
          _c.tabIndex = 1;
          _c.servicosExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(_c.servicosSectionKey);
        });
      case LandingChecklistTarget.conteudoFaq:
        setState(() {
          _c.tabIndex = 1;
          _c.faqExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(_c.faqSectionKey);
        });
      case LandingChecklistTarget.whiteLabel:
        context.push('/perfil/white-label');
      case LandingChecklistTarget.identidadeVisual:
        context.push('/identidade-visual');
      case LandingChecklistTarget.editProfile:
        final perfil = ref.read(perfilProvider).valueOrNull;
        if (perfil != null) {
          context.push('/perfil/editar', extra: perfil);
        }
      case LandingChecklistTarget.pacotes:
        context.push('/pacotes');
    }
  }

  Future<bool> _confirmApplyTemplate(String label) {
    return showFxConfirmSheet(
      context,
      title: 'Aplicar $label?',
      message:
          'Os textos atuais da abertura, serviços, dúvidas e botões serão substituídos. '
          'Fotos e planos da vitrine não mudam.',
      icon: Icons.auto_fix_high_rounded,
      confirmLabel: 'Aplicar modelo',
    );
  }

  Future<void> _applyTemplate(LandingCompleteTemplate template) async {
    if (!await _confirmApplyTemplate(template.label)) return;

    if (!landingTemplateIsRemote(template)) {
      setState(() => _c.applyTemplate(template));
      if (!mounted) return;
      FeedbackHelper.showSuccess(
        context,
        'Modelo padrão aplicado. Revise e salve.',
      );
      setState(() => _c.tabIndex = 1);
      return;
    }

    setState(() => _c.applyingTemplate = true);
    try {
      await ref.read(landingGrowthRepositoryProvider).applyPreset(template.id);
      ref.invalidate(perfilProvider);
      final perfil = await ref.read(perfilRepositoryProvider).buscar();
      if (!mounted) return;
      setState(() {
        _c.applyPerfil(perfil);
        _c.reviewFocusMode = false;
        _c.tabIndex = 1;
        _c.heroExpanded = true;
        _c.faqExpanded = true;
        _c.servicosExpanded = true;
      });
      FeedbackHelper.showSuccess(
        context,
        'Modelo "${template.label}" aplicado em todas as seções.',
      );
      await _loadGrowth();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _c.applyingTemplate = false);
    }
  }

  Future<void> _tryPopAfterLeaveConfirm() async {
    final router = GoRouter.of(context);
    if (!await _confirmLeave()) return;
    router.pop();
  }

  Future<bool> _confirmContentWarnings() async {
    final issues = _c.contentIssuesForReview();
    if (issues.isEmpty) return true;

    final publish = await showFxConfirmSheet(
      context,
      title: 'Publicar mesmo assim?',
      message:
          '${issues.map((e) => '• ${e.message}').join('\n')}\n\n'
          'Sua página pode parecer incompleta para quem visita.',
      icon: Icons.publish_rounded,
      confirmLabel: 'Publicar assim',
      cancelLabel: 'Revisar conteúdo',
    );
    if (!publish) _openContentReview();
    return publish;
  }

  Future<bool> _confirmLeave() async {
    if (!_c.dirty) return true;

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final choice = await showFxHomeSheet<LandingEditorLeaveChoice>(
      context,
      builder:
          (ctx) => FxHomeSheetSurface(
            isDark: isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FxHomeSheetHandle(isDark: isDark),
                const SizedBox(height: 16),
                FxHomeSheetHeader(
                  isDark: isDark,
                  title: 'Salvar antes de sair?',
                  subtitle:
                      'Você fez alterações na landing. O que prefere fazer?',
                  leading: Icon(
                    Icons.save_outlined,
                    color: scheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed:
                      () => Navigator.pop(
                        ctx,
                        LandingEditorLeaveChoice.saveAndLeave,
                      ),
                  child: const Text('Salvar e sair'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed:
                      () => Navigator.pop(ctx, LandingEditorLeaveChoice.stay),
                  child: const Text('Continuar editando'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed:
                      () =>
                          Navigator.pop(ctx, LandingEditorLeaveChoice.discard),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                  ),
                  child: const Text('Sair sem salvar'),
                ),
              ],
            ),
          ),
    );

    switch (choice) {
      case LandingEditorLeaveChoice.discard:
        return true;
      case LandingEditorLeaveChoice.saveAndLeave:
        await _salvar();
        return !_c.dirty;
      case LandingEditorLeaveChoice.stay:
      case null:
        return false;
    }
  }

  Future<bool> _confirmDelete(String label) {
    return showFxConfirmSheet(
      context,
      title: 'Remover $label?',
      message: 'Essa ação não pode ser desfeita até você salvar.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Remover',
      destructive: true,
    );
  }

  Future<void> _removeServico(int index) async {
    if (!await _confirmDelete('serviço ${index + 1}')) return;
    setState(() => _c.removeServico(index));
  }

  Future<void> _removeFaq(int index) async {
    if (!await _confirmDelete('pergunta ${index + 1}')) return;
    setState(() => _c.removeFaq(index));
  }

  Future<void> _generateHero() async {
    setState(() => _c.generatingHero = true);
    try {
      final copy =
          await ref.read(landingGrowthRepositoryProvider).generateHero();
      _c.heroTitle.text = copy.heroTitle;
      _c.heroSubtitle.text = copy.heroSubtitle;
      _c.primaryCta.text = copy.primaryCta;
      if (!mounted) return;
      FeedbackHelper.showSuccess(context, 'Textos sugeridos pela IA.');
      setState(() => _c.dirty = true);
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _c.generatingHero = false);
    }
  }

  Future<void> _uploadImage({required bool hero}) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1920,
    );
    if (file == null || !mounted) return;
    setState(() {
      if (hero) {
        _c.uploadingHero = true;
      } else {
        _c.uploadingBio = true;
      }
    });
    try {
      final url = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: hero ? 'landing/hero' : 'landing/bio',
        resourceType: 'image',
      );
      if (!mounted) return;
      setState(() {
        if (hero) {
          _c.heroImageUrl = url;
          _c.coverExpanded = true;
        } else {
          _c.bioImageUrl = url;
        }
        _c.dirty = true;
      });
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          if (hero) {
            _c.uploadingHero = false;
          } else {
            _c.uploadingBio = false;
          }
        });
      }
    }
  }

  Future<void> _removeImage({required bool hero}) async {
    final label = hero ? 'foto de capa' : 'foto customizada da seção sobre';
    final content =
        hero
            ? 'A imagem será removida da landing. Toque em Salvar para publicar a alteração.'
            : 'A foto customizada será removida. A seção sobre voltará a usar sua foto de perfil.';
    final confirmed = await showFxConfirmSheet(
      context,
      title: 'Remover $label?',
      message: content,
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      if (hero) {
        _c.clearHeroImage();
      } else {
        _c.clearBioImage();
      }
    });
    FeedbackHelper.showSuccess(
      context,
      '$label removida. Salve para publicar.',
    );
  }

  void _useDefaultImage({required bool hero}) {
    final alreadyDefault =
        hero
            ? (_c.heroImageUrl == null || _c.heroImageUrl!.isEmpty)
            : (_c.bioImageUrl == null || _c.bioImageUrl!.isEmpty);
    if (alreadyDefault) {
      FeedbackHelper.showInfo(context, 'Já está no padrão.');
      return;
    }
    setState(() {
      if (hero) {
        _c.clearHeroImage();
      } else {
        _c.clearBioImage();
      }
    });
    FeedbackHelper.showSuccess(
      context,
      hero
          ? 'Padrão aplicado — capa premium de academia na landing.'
          : 'Padrão aplicado — seção sobre usa sua foto de perfil.',
    );
  }

  Future<void> _salvar() async {
    final validation = _c.validateBeforeSave();
    if (validation != null) {
      FeedbackHelper.showWarn(context, validation);
      return;
    }
    if (!await _confirmContentWarnings()) return;

    setState(() => _c.saving = true);
    try {
      final normalizedOrder = normalizeLandingSectionOrder(_c.sectionOrder);
      final heroTitle = landingPolishShortText(_c.heroTitle.text.trim());
      final primaryCta = _c.polishCta(_c.primaryCta.text.trim());
      final offerCta = _c.polishCta(_c.offerCta.text.trim());
      final finalCta = _c.stickyBarCtaForSave();
      final contactCta = _c.polishCta(_c.contactCta.text.trim());
      final servicos = _c.servicosForSave();
      final faq = _c.faqForSave();
      await ref
          .read(perfilRepositoryProvider)
          .atualizarLanding(
            heroTitle: heroTitle,
            heroSubtitle: _c.heroSubtitle.text.trim(),
            primaryCta: primaryCta,
            descricaoProfissional: _c.descricaoProfissional.trim(),
            sectionOrder: normalizedOrder,
            servicos: servicos,
            faq: faq,
            heroImageUrl: _c.heroImageUrl,
            bioImageUrl: _c.bioImageUrl,
            offerCta: offerCta,
            finalCta: finalCta,
            contactCta: contactCta,
          );
      ref.invalidate(perfilProvider);
      if (!mounted) return;
      setState(() {
        _c.sectionOrder = normalizedOrder;
        _c.dirty = false;
        _c.applyPolishToControllers(
          polishedServicos: servicos,
          polishedFaq: faq,
          polishedHeroTitle: heroTitle,
          polishedPrimaryCta: primaryCta,
          polishedOfferCta: offerCta,
          polishedFinalCta: finalCta,
          polishedContactCta: contactCta,
        );
      });
      HapticFeedback.mediumImpact();
      FeedbackHelper.showSuccess(context, 'Landing publicada com sucesso.');
      await _loadGrowth();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _c.saving = false);
    }
  }

}

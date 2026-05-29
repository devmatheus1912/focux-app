import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/env.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_celebration_overlay.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/landing_growth_repository.dart';
import '../providers/perfil_provider.dart';
import '../widgets/landing_editor_widgets.dart';
import 'landing_editor_checklist.dart';
import 'landing_editor_content_tab.dart';
import 'landing_editor_controller.dart';
import 'landing_editor_links_tab.dart';
import 'landing_editor_order_tab.dart';
import 'landing_editor_quality.dart';
import 'landing_editor_sections.dart';
import 'landing_preset_mapper.dart';
import 'landing_section_templates.dart';

class LandingEditorScreen extends ConsumerStatefulWidget {
  const LandingEditorScreen({super.key});

  @override
  ConsumerState<LandingEditorScreen> createState() =>
      _LandingEditorScreenState();
}

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
          accent: const Color(0xFF0F9D7A),
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
      case LandingChecklistTarget.pacotes:
        context.push('/pacotes');
    }
  }

  Future<bool> _confirmApplyTemplate(String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aplicar $label?'),
        content: const Text(
          'Os textos atuais da abertura, serviços, dúvidas e botões serão substituídos. '
          'Fotos e planos da vitrine não mudam.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aplicar modelo'),
          ),
        ],
      ),
    );
    return ok ?? false;
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

    final publish = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publicar mesmo assim?'),
        content: Text(
          '${issues.map((e) => '• ${e.message}').join('\n')}\n\n'
          'Sua página pode parecer incompleta para quem visita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Revisar conteúdo'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publicar assim'),
          ),
        ],
      ),
    );
    if (publish == false) _openContentReview();
    return publish ?? false;
  }

  Future<bool> _confirmLeave() async {
    if (!_c.dirty) return true;

    final scheme = Theme.of(context).colorScheme;
    final choice = await showDialog<LandingEditorLeaveChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salvar antes de sair?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Você fez alterações na landing. O que prefere fazer?',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, LandingEditorLeaveChoice.saveAndLeave),
              child: const Text('Salvar e sair'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, LandingEditorLeaveChoice.stay),
              child: const Text('Continuar editando'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(ctx, LandingEditorLeaveChoice.discard),
              style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
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

  Future<bool> _confirmDelete(String label) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover $label?'),
        content: const Text('Essa ação não pode ser desfeita até você salvar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    return ok ?? false;
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
      final copy = await ref.read(landingGrowthRepositoryProvider).generateHero();
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
      final url = await MediaUploadService(ref.read(apiClientProvider)).uploadBytes(
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
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
      );
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
    final content = hero
        ? 'A imagem será removida da landing. Toque em Salvar para publicar a alteração.'
        : 'A foto customizada será removida. A seção sobre voltará a usar sua foto de perfil.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remover $label?'),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      if (hero) {
        _c.clearHeroImage();
      } else {
        _c.clearBioImage();
      }
    });
    FeedbackHelper.showSnackBar(
      context,
      SnackBar(content: Text('$label removida. Salve para publicar.')),
    );
  }

  void _useDefaultImage({required bool hero}) {
    final alreadyDefault = hero
        ? (_c.heroImageUrl == null || _c.heroImageUrl!.isEmpty)
        : (_c.bioImageUrl == null || _c.bioImageUrl!.isEmpty);
    if (alreadyDefault) {
      FeedbackHelper.showSnackBar(
        context,
        const SnackBar(content: Text('Já está no padrão.')),
      );
      return;
    }
    setState(() {
      if (hero) {
        _c.clearHeroImage();
      } else {
        _c.clearBioImage();
      }
    });
    FeedbackHelper.showSnackBar(
      context,
      SnackBar(
        content: Text(
          hero
              ? 'Padrão aplicado — capa premium de academia na landing.'
              : 'Padrão aplicado — seção sobre usa sua foto de perfil.',
        ),
      ),
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
      final finalCta = _c.polishCta(_c.finalCta.text.trim());
      final contactCta = _c.polishCta(_c.contactCta.text.trim());
      final servicos = _c.servicosForSave();
      final faq = _c.faqForSave();
      await ref.read(perfilRepositoryProvider).atualizarLanding(
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
      FeedbackHelper.showSuccess(context, 'Landing publicada com sucesso.');
      await _loadGrowth();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _c.saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);

    return perfilAsync.when(
      loading: () => const FxShellScaffold(
        appBar: FxShellAppBar(title: 'Editor da landing'),
        body: Center(child: FxLoading()),
      ),
      error: (e, _) => FxShellScaffold(
        appBar: FxShellAppBar(
          title: 'Editor da landing',
          onBack: () => context.pop(),
        ),
        body: Center(child: Text(friendlyError(e))),
      ),
      data: (perfil) {
        if (!_c.loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _c.applyPerfil(perfil));
          });
        }

        return PopScope(
          canPop: !_c.dirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _tryPopAfterLeaveConfirm();
          },
          child: FxShellScaffold(
            appBar: FxShellAppBar(
              title: 'Editor da landing',
              subtitle: _c.dirty ? 'Alterações pendentes' : null,
              onBack: _tryPopAfterLeaveConfirm,
            ),
            bottomNavigationBar: LandingStickySaveBar(
              dirty: _c.dirty,
              saving: _c.saving,
              onSave: _salvar,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_c.loaded)
                  LandingContentWarningBanner(
                    reviewCount: _c.contentReviewCount(),
                    configComplete: _c.checklist.isNotEmpty &&
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
                            onUseDefaultHero: () => _useDefaultImage(hero: true),
                            onUseDefaultBio: () => _useDefaultImage(hero: false),
                            onMarkDirty: () => _c.markDirty(),
                            onHeroExpandedChanged: (v) =>
                                setState(() => _c.heroExpanded = v),
                            onCoverExpandedChanged: (v) =>
                                setState(() => _c.coverExpanded = v),
                            onPreviewLanding: () {
                              final slug = _c.slug;
                              if (slug == null || slug.isEmpty) return;
                              openLandingLink(
                                context,
                                url: Env.landingPageUrl(slug),
                              );
                            },
                            onCtasExpandedChanged: (v) =>
                                setState(() => _c.ctasExpanded = v),
                            onServicosExpandedChanged: (v) =>
                                setState(() => _c.servicosExpanded = v),
                            onFaqExpandedChanged: (v) =>
                                setState(() => _c.faqExpanded = v),
                            onAddServico: () => setState(() => _c.addServico()),
                            onRemoveServico: _removeServico,
                            onUpdateServico: (i, {titulo, descricao}) => setState(
                              () => _c.updateServico(
                                i,
                                titulo: titulo,
                                descricao: descricao,
                              ),
                            ),
                            onAddFaq: () => setState(() => _c.addFaq()),
                            onRemoveFaq: _removeFaq,
                            onUpdateFaq: (i, {pergunta, resposta}) => setState(
                              () => _c.updateFaq(
                                i,
                                pergunta: pergunta,
                                resposta: resposta,
                              ),
                            ),
                            onExitReviewFocus: _exitReviewFocus,
                          ),
                        ),
                      _ => KeyedSubtree(
                          key: const ValueKey('tab-ordem'),
                          child: LandingEditorOrderTab(
                            controller: _c,
                            onReorder: (old, newIndex) {
                              setState(() => _c.reorderSection(
                                    old,
                                    newIndex,
                                    onHighlightEnd: () {
                                      if (mounted) _c.clearSectionHighlight();
                                    },
                                  ));
                            },
                            onMoveUp: (i) {
                              setState(() => _c.moveSection(
                                    i,
                                    -1,
                                    onHighlightEnd: () {
                                      if (mounted) _c.clearSectionHighlight();
                                    },
                                  ));
                            },
                            onMoveDown: (i) {
                              setState(() => _c.moveSection(
                                    i,
                                    1,
                                    onHighlightEnd: () {
                                      if (mounted) _c.clearSectionHighlight();
                                    },
                                  ));
                            },
                          ),
                        ),
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

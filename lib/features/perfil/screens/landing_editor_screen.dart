import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_celebration_overlay.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/landing_growth_repository.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../widgets/landing_editor_widgets.dart';
import 'landing_editor_checklist.dart';
import 'landing_editor_quality.dart';
import 'landing_editor_sections.dart';
import 'landing_section_templates.dart';

class LandingEditorScreen extends ConsumerStatefulWidget {
  const LandingEditorScreen({super.key});

  @override
  ConsumerState<LandingEditorScreen> createState() =>
      _LandingEditorScreenState();
}

enum _LeaveChoice { stay, discard, saveAndLeave }

class _LandingEditorScreenState extends ConsumerState<LandingEditorScreen> {
  final _conteudoScroll = ScrollController();
  final _heroSectionKey = GlobalKey();
  final _ctasSectionKey = GlobalKey();
  final _servicosSectionKey = GlobalKey();
  final _faqSectionKey = GlobalKey();
  final _capturaCardKey = GlobalKey();

  final _heroTitle = TextEditingController();
  final _heroSubtitle = TextEditingController();
  final _primaryCta = TextEditingController();
  final _offerCta = TextEditingController();
  final _finalCta = TextEditingController();
  final _contactCta = TextEditingController();

  List<String> _sectionOrder = List<String>.from(landingEditorCanonicalSections);
  List<LandingServiceItem> _servicos = [];
  List<LandingFaqItem> _faq = [];
  String? _slug;
  String? _heroImageUrl;
  String? _bioImageUrl;
  bool _loaded = false;
  bool _dirty = false;
  bool _saving = false;
  bool _uploadingHero = false;
  bool _uploadingBio = false;
  bool _generatingHero = false;
  int _tabIndex = 0;
  bool _heroExpanded = true;
  bool _ctasExpanded = false;
  bool _servicosExpanded = false;
  bool _faqExpanded = false;
  bool _checklistLoading = true;
  String? _highlightedSectionKey;
  int? _highlightedFaqIndex;
  Timer? _highlightTimer;
  Timer? _faqHighlightTimer;
  final _faqItemKeys = <int, GlobalKey>{};
  List<LandingNichePreset> _presets = [];
  List<LandingChecklistItem> _checklist = [];
  int _lastReviewCount = -1;
  bool _celebrationShownForClear = false;
  bool _reviewFocusMode = false;
  bool _applyingTemplate = false;

  static const _sectionTitleStyle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: TokensStrip.fontH2,
    letterSpacing: TokensStrip.trackingH2,
  );

  @override
  void initState() {
    super.initState();
    for (final c in [
      _heroTitle,
      _heroSubtitle,
      _primaryCta,
      _offerCta,
      _finalCta,
      _contactCta,
    ]) {
      c.addListener(_markDirty);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGrowth());
  }

  void _markDirty() {
    if (!_loaded || !mounted) return;
    setState(() => _dirty = true);
    _syncReviewCelebration();
  }

  void _syncReviewCelebration() {
    if (!_loaded || !mounted) return;
    final count = _contentReviewCount();
    if (_lastReviewCount > 0 && count == 0 && !_celebrationShownForClear) {
      _celebrationShownForClear = true;
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
    if (count > 0) _celebrationShownForClear = false;
    if (count == 0 && _reviewFocusMode) {
      _reviewFocusMode = false;
    }
    _lastReviewCount = count;
  }

  int _contentReviewScope() {
    return landingContentReviewScopeCount(faq: _faqPayload());
  }

  int _contentReviewedCount() {
    return landingContentReviewedCount(
      faq: _faqPayload(),
      primaryCta: _primaryCta.text,
      heroTitle: _heroTitle.text,
    );
  }

  Set<int> _focusFaqIndices() {
    return landingBadFaqIndices(faq: _faqPayload()).toSet();
  }

  bool _focusHeroIssue() {
    return _contentIssuesForReview().any((issue) => issue.id != 'faq');
  }

  void _enterReviewFocus({LandingContentIssue? jumpTo}) {
    final issues = _contentIssuesForReview();
    if (issues.isEmpty) return;
    setState(() {
      _reviewFocusMode = true;
      _tabIndex = 1;
      _heroExpanded = _focusHeroIssue();
      _faqExpanded = _focusFaqIndices().isNotEmpty;
      _servicosExpanded = false;
      _ctasExpanded = false;
    });
    final target = jumpTo ?? issues.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateContentIssue(target);
    });
  }

  void _exitReviewFocus() {
    setState(() => _reviewFocusMode = false);
  }

  Future<void> _loadGrowth() async {
    try {
      final repo = ref.read(landingGrowthRepositoryProvider);
      final presets = await repo.presets();
      final checklist = await repo.checklist();
      if (!mounted) return;
      setState(() {
        _presets = presets;
        _checklist = checklist;
        _checklistLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _checklistLoading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _heroTitle,
      _heroSubtitle,
      _primaryCta,
      _offerCta,
      _finalCta,
      _contactCta,
    ]) {
      c.removeListener(_markDirty);
      c.dispose();
    }
    _highlightTimer?.cancel();
    _faqHighlightTimer?.cancel();
    _conteudoScroll.dispose();
    super.dispose();
  }

  List<LandingContentIssue> _contentIssuesForReview() {
    return landingContentIssuesForReview(
      faq: _faqPayload(),
      primaryCta: _primaryCta.text,
      heroTitle: _heroTitle.text,
    );
  }

  int _contentReviewCount() {
    return landingContentReviewCount(
      faq: _faqPayload(),
      primaryCta: _primaryCta.text,
      heroTitle: _heroTitle.text,
    );
  }

  List<({String pergunta, String resposta})> _faqPayload() {
    return _faq
        .map((e) => (pergunta: e.pergunta, resposta: e.resposta))
        .toList();
  }

  GlobalKey _faqKeyFor(int index) =>
      _faqItemKeys.putIfAbsent(index, GlobalKey.new);

  void _pulseFaqHighlight(int? index) {
    setState(() => _highlightedFaqIndex = index);
    _faqHighlightTimer?.cancel();
    _faqHighlightTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _highlightedFaqIndex = null);
    });
  }

  void _navigateContentIssue(LandingContentIssue issue) {
    switch (issue.id) {
      case 'hero':
      case 'cta':
      case 'cta_accent':
        setState(() {
          _tabIndex = 1;
          _heroExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(_heroSectionKey);
        });
      case 'faq':
        final index = issue.faqIndex;
        setState(() {
          _tabIndex = 1;
          _faqExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (index != null) {
            await _scrollToSection(_faqKeyFor(index));
            _pulseFaqHighlight(index);
          } else {
            await _scrollToSection(_faqSectionKey);
          }
        });
    }
  }

  void _openContentReview() {
    final issues = _contentIssuesForReview();
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
        setState(() => _tabIndex = 0);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(_capturaCardKey);
        });
      case LandingChecklistTarget.conteudoHero:
        setState(() {
          _tabIndex = 1;
          _heroExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(_heroSectionKey);
        });
      case LandingChecklistTarget.conteudoServicos:
        setState(() {
          _tabIndex = 1;
          _servicosExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(_servicosSectionKey);
        });
      case LandingChecklistTarget.conteudoFaq:
        setState(() {
          _tabIndex = 1;
          _faqExpanded = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToSection(_faqSectionKey);
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

  void _applyLocalTemplate(LandingCompleteTemplate template) {
    setState(() {
      _heroTitle.text = template.heroTitle;
      _heroSubtitle.text = template.heroSubtitle;
      _primaryCta.text = template.primaryCta;
      _offerCta.text = template.offerCta;
      _finalCta.text = template.finalCta;
      _contactCta.text = template.contactCta;
      _servicos = List<LandingServiceItem>.from(template.servicos);
      _faq = List<LandingFaqItem>.from(template.faq);
      _sectionOrder = List<String>.from(template.sectionOrder);
      _heroExpanded = true;
      _faqExpanded = true;
      _servicosExpanded = true;
      _ctasExpanded = false;
      _reviewFocusMode = false;
      _dirty = true;
    });
    _syncReviewCelebration();
  }

  Future<void> _applyDefaultTemplate() async {
    if (!await _confirmApplyTemplate(landingDefaultCompleteTemplate.label)) return;
    _applyLocalTemplate(landingDefaultCompleteTemplate);
    if (!mounted) return;
    FeedbackHelper.showSuccess(context, 'Modelo padrão aplicado. Revise e salve.');
    setState(() => _tabIndex = 1);
  }

  Future<void> _applyRemotePreset(LandingNichePreset preset) async {
    if (!await _confirmApplyTemplate(preset.label)) return;
    setState(() => _applyingTemplate = true);
    try {
      await ref.read(landingGrowthRepositoryProvider).applyPreset(preset.id);
      ref.invalidate(perfilProvider);
      final perfil = await ref.read(perfilRepositoryProvider).buscar();
      if (!mounted) return;
      setState(() {
        _applyPerfil(perfil);
        _reviewFocusMode = false;
        _tabIndex = 1;
        _heroExpanded = true;
        _faqExpanded = true;
        _servicosExpanded = true;
      });
      _syncReviewCelebration();
      FeedbackHelper.showSuccess(
        context,
        'Modelo "${preset.label}" aplicado em todas as seções.',
      );
      await _loadGrowth();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _applyingTemplate = false);
    }
  }

  Future<void> _tryPopAfterLeaveConfirm() async {
    final router = GoRouter.of(context);
    if (!await _confirmLeave()) return;
    router.pop();
  }

  Future<bool> _confirmContentWarnings() async {
    final issues = _contentIssuesForReview();
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
    if (publish == false) {
      _openContentReview();
    }
    return publish ?? false;
  }

  void _applyPerfil(PerfilPersonal p) {
    _heroTitle.text = p.heroTitle ?? '';
    _heroSubtitle.text = p.heroSubtitle ?? '';
    _primaryCta.text = p.primaryCta ?? '';
    _offerCta.text = p.offerCta ?? '';
    _finalCta.text = p.finalCta ?? '';
    _contactCta.text = p.contactCta ?? '';
    _slug = p.slug;
    _heroImageUrl = p.heroImageUrl;
    _bioImageUrl = p.bioImageUrl;
    _servicos = p.servicos
        .map((e) => LandingServiceItem(titulo: e.titulo, descricao: e.descricao))
        .toList();
    _faq = p.faq
        .map((e) => LandingFaqItem(pergunta: e.pergunta, resposta: e.resposta))
        .toList();
    if (p.sectionOrder.isNotEmpty) {
      _sectionOrder = normalizeLandingSectionOrder(p.sectionOrder);
    } else {
      _sectionOrder = List<String>.from(landingEditorCanonicalSections);
    }
    _loaded = true;
    _dirty = false;
    _lastReviewCount = landingContentReviewCount(
      faq: _faq
          .map((e) => (pergunta: e.pergunta, resposta: e.resposta))
          .toList(),
      primaryCta: _primaryCta.text,
      heroTitle: _heroTitle.text,
    );
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;

    final scheme = Theme.of(context).colorScheme;
    final choice = await showDialog<_LeaveChoice>(
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
              onPressed: () => Navigator.pop(ctx, _LeaveChoice.saveAndLeave),
              child: const Text('Salvar e sair'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, _LeaveChoice.stay),
              child: const Text('Continuar editando'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, _LeaveChoice.discard),
              style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              child: const Text('Sair sem salvar'),
            ),
          ],
        ),
      ),
    );

    switch (choice) {
      case _LeaveChoice.discard:
        return true;
      case _LeaveChoice.saveAndLeave:
        await _salvar();
        return !_dirty;
      case _LeaveChoice.stay:
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

  void _reorderSection(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _sectionOrder.removeAt(oldIndex);
      _sectionOrder.insert(newIndex, item);
      _dirty = true;
      _highlightedSectionKey = item;
    });
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 750), () {
      if (mounted) setState(() => _highlightedSectionKey = null);
    });
  }

  void _moveSection(int index, int delta) {
    if (delta < 0) {
      if (index <= 0) return;
      _reorderSection(index, index - 1);
      return;
    }
    if (index >= _sectionOrder.length - 1) return;
    _reorderSection(index, index + 2);
  }

  void _addServico() {
    setState(() {
      _servicos = [..._servicos, const LandingServiceItem(titulo: '', descricao: '')];
      _dirty = true;
    });
    _syncReviewCelebration();
  }

  Future<void> _removeServico(int index) async {
    if (!await _confirmDelete('serviço ${index + 1}')) return;
    setState(() {
      _servicos = [..._servicos]..removeAt(index);
      _dirty = true;
    });
    _syncReviewCelebration();
  }

  void _updateServico(int index, {String? titulo, String? descricao}) {
    final current = _servicos[index];
    setState(() {
      _servicos[index] = LandingServiceItem(
        titulo: titulo ?? current.titulo,
        descricao: descricao ?? current.descricao,
      );
      _dirty = true;
    });
    _syncReviewCelebration();
  }

  void _addFaq() {
    setState(() {
      _faq = [..._faq, const LandingFaqItem(pergunta: '', resposta: '')];
      _dirty = true;
    });
    _syncReviewCelebration();
  }

  Future<void> _removeFaq(int index) async {
    if (!await _confirmDelete('pergunta ${index + 1}')) return;
    setState(() {
      _faq = [..._faq]..removeAt(index);
      _dirty = true;
    });
    _syncReviewCelebration();
  }

  void _updateFaq(int index, {String? pergunta, String? resposta}) {
    final current = _faq[index];
    setState(() {
      _faq[index] = LandingFaqItem(
        pergunta: pergunta ?? current.pergunta,
        resposta: resposta ?? current.resposta,
      );
      _dirty = true;
    });
    _syncReviewCelebration();
  }

  List<LandingFaqItem> _faqForSave() {
    return _faq
        .where((item) =>
            item.pergunta.trim().length >= 3 && item.resposta.trim().length >= 3)
        .map(
          (item) => LandingFaqItem(
            pergunta: landingPolishShortText(item.pergunta),
            resposta: landingPolishShortText(item.resposta),
          ),
        )
        .toList();
  }

  String _polishCta(String text) {
    final polished = landingPolishShortText(text);
    return landingCtaAccentSuggestion(polished) ?? polished;
  }

  List<LandingServiceItem> _servicosForSave() {
    return _servicos
        .where((s) =>
            s.titulo.trim().isNotEmpty || s.descricao.trim().isNotEmpty)
        .map(
          (s) => LandingServiceItem(
            titulo: landingPolishShortText(s.titulo),
            descricao: s.descricao.trim(),
          ),
        )
        .toList();
  }

  void _applyPolishToControllers({
    required List<LandingServiceItem> servicos,
    required List<LandingFaqItem> faq,
    required String heroTitle,
    required String primaryCta,
    required String offerCta,
    required String finalCta,
    required String contactCta,
  }) {
    _heroTitle.text = heroTitle;
    _primaryCta.text = primaryCta;
    _offerCta.text = offerCta;
    _finalCta.text = finalCta;
    _contactCta.text = contactCta;
    _servicos = servicos;
    _faq = faq;
  }

  String? _validateBeforeSave() {
    for (var i = 0; i < _faq.length; i++) {
      final p = _faq[i].pergunta.trim();
      final r = _faq[i].resposta.trim();
      final hasAny = p.isNotEmpty || r.isNotEmpty;
      if (!hasAny) continue;
      if (p.length < 3) {
        return 'FAQ ${i + 1}: escreva uma pergunta com pelo menos 3 caracteres.';
      }
      if (r.length < 3) {
        return 'FAQ ${i + 1}: escreva uma resposta com pelo menos 3 caracteres.';
      }
    }
    if (_heroTitle.text.trim().isEmpty) {
      return 'Informe o título principal da sua página.';
    }
    if (_primaryCta.text.trim().isEmpty) {
      return 'Informe o texto do botão principal.';
    }
    return null;
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
        _uploadingHero = true;
      } else {
        _uploadingBio = true;
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
          _heroImageUrl = url;
        } else {
          _bioImageUrl = url;
        }
        _dirty = true;
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
            _uploadingHero = false;
          } else {
            _uploadingBio = false;
          }
        });
      }
    }
  }

  Future<void> _salvar() async {
    final validation = _validateBeforeSave();
    if (validation != null) {
      FeedbackHelper.showWarn(context, validation);
      return;
    }
    if (!await _confirmContentWarnings()) return;

    setState(() => _saving = true);
    try {
      final normalizedOrder = normalizeLandingSectionOrder(_sectionOrder);
      final heroTitle = landingPolishShortText(_heroTitle.text.trim());
      final primaryCta = _polishCta(_primaryCta.text.trim());
      final offerCta = _polishCta(_offerCta.text.trim());
      final finalCta = _polishCta(_finalCta.text.trim());
      final contactCta = _polishCta(_contactCta.text.trim());
      final servicos = _servicosForSave();
      final faq = _faqForSave();
      await ref.read(perfilRepositoryProvider).atualizarLanding(
            heroTitle: heroTitle,
            heroSubtitle: _heroSubtitle.text.trim(),
            primaryCta: primaryCta,
            sectionOrder: normalizedOrder,
            servicos: servicos,
            faq: faq,
            heroImageUrl: _heroImageUrl,
            bioImageUrl: _bioImageUrl,
            offerCta: offerCta,
            finalCta: finalCta,
            contactCta: contactCta,
          );
      ref.invalidate(perfilProvider);
      if (!mounted) return;
      setState(() {
        _sectionOrder = normalizedOrder;
        _dirty = false;
        _applyPolishToControllers(
          servicos: servicos,
          faq: faq,
          heroTitle: heroTitle,
          primaryCta: primaryCta,
          offerCta: offerCta,
          finalCta: finalCta,
          contactCta: contactCta,
        );
      });
      _syncReviewCelebration();
      FeedbackHelper.showSuccess(context, 'Landing publicada com sucesso.');
      await _loadGrowth();
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showSnackBar(
        context,
        SnackBar(content: Text(friendlyError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _imageUploadCard({
    required String title,
    required String hint,
    required String? imageUrl,
    required bool uploading,
    required VoidCallback onUpload,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TokensStrip.rLg),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 8),
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(TokensStrip.rMd),
                child: Image.network(
                  imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      height: 120,
                      child: Center(
                        child: FxLoading(
                          size: 24,
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 120,
                    child: Center(child: Icon(Icons.broken_image_outlined)),
                  ),
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(TokensStrip.rMd),
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
                ),
                child: const Icon(Icons.image_outlined, size: 36),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: uploading ? null : onUpload,
              icon: uploading
                  ? const FxLoading(size: 18, strokeWidth: 2)
                  : const Icon(Icons.upload_outlined),
              label: Text(uploading ? 'Enviando…' : 'Enviar imagem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? hint, VoidCallback? onAdd}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: _sectionTitleStyle)),
            if (onAdd != null)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Adicionar'),
              ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ],
    );
  }

  Widget _linksTab(String? slug) {
    if (slug == null || slug.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(TokensStrip.s4),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Defina seu slug no perfil para gerar os links da sua página.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final landingUrl = Env.landingPageUrl(slug);
    final capturaUrl = Env.capturaPageUrl(slug);

    return ListView(
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        LandingLinkCard(
          icon: Icons.public_rounded,
          title: 'Página completa na internet',
          subtitle:
              'Site com foto, planos e depoimentos — ideal para Instagram, WhatsApp e bio.',
          displayLabel: Env.landingPageDisplayLabel(slug),
          copyUrl: landingUrl,
          onOpen: () => openLandingLink(context, url: landingUrl),
          onCopy: () => copyLandingLink(
            context,
            url: landingUrl,
            successMessage: 'Link da página copiado.',
          ),
        ),
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _capturaCardKey,
          child: LandingLinkCard(
            icon: Icons.bolt_rounded,
            title: 'Formulário rápido de contato',
            subtitle:
                'Só nome e WhatsApp — use em anúncios quando quiser captar lead direto.',
            displayLabel: Env.capturaPageDisplayLabel(slug),
            copyUrl: capturaUrl,
            onOpen: () => openLandingLink(context, url: capturaUrl),
            onCopy: () => copyLandingLink(
              context,
              url: capturaUrl,
              successMessage: 'Link do formulário copiado.',
            ),
          ),
        ),
        if (_checklistLoading) ...[
          const SizedBox(height: 16),
          const LandingChecklistSkeleton(),
        ] else if (_checklist.isNotEmpty) ...[
          const SizedBox(height: 16),
          LandingChecklistCard(
            items: _checklist,
            contentIssueCount: _contentReviewCount(),
            contentReviewScope: _contentReviewScope(),
            contentReviewedCount: _contentReviewedCount(),
            onReviewContent: () => _enterReviewFocus(),
            onItemTap: _onChecklistTap,
          ),
        ],
        const SizedBox(height: 16),
        LandingSectionTemplatesPanel(
          sectionOrder: _sectionOrder,
          presets: _presets,
          applying: _applyingTemplate || _saving,
          onApplyDefault: _applyDefaultTemplate,
          onApplyPreset: _applyRemotePreset,
        ),
      ],
    );
  }

  Widget _conteudoTab() {
    final focusFaq = _reviewFocusMode ? _focusFaqIndices() : null;
    final showHero = !_reviewFocusMode || _focusHeroIssue();
    final showSecondarySections = !_reviewFocusMode;
    final visibleFaqIndices = focusFaq == null
        ? List<int>.generate(_faq.length, (i) => i)
        : (focusFaq.toList()..sort());
    final hiddenFaqCount = _faq.length - visibleFaqIndices.length;

    return ListView(
      controller: _conteudoScroll,
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        if (_reviewFocusMode)
          LandingReviewFocusBanner(
            pendingCount: _contentReviewCount(),
            onExit: _exitReviewFocus,
          ),
        if (_reviewFocusMode) const SizedBox(height: 12),
        if (showHero)
          KeyedSubtree(
            key: _heroSectionKey,
            child: LandingCollapsibleSection(
            title: 'Abertura da página',
            hint: 'Primeira impressão — título, texto e botão principal.',
            expanded: _heroExpanded,
            onExpandedChanged: (value) => setState(() => _heroExpanded = value),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _generatingHero
                      ? null
                      : () async {
                          setState(() => _generatingHero = true);
                          try {
                            final copy = await ref
                                .read(landingGrowthRepositoryProvider)
                                .generateHero();
                            _heroTitle.text = copy.heroTitle;
                            _heroSubtitle.text = copy.heroSubtitle;
                            _primaryCta.text = copy.primaryCta;
                            if (!mounted) return;
                            FeedbackHelper.showSuccess(
                              context,
                              'Textos sugeridos pela IA.',
                            );
                            setState(() => _dirty = true);
                          } catch (e) {
                            if (!mounted) return;
                            FeedbackHelper.showError(context, friendlyError(e));
                          } finally {
                            if (mounted) setState(() => _generatingHero = false);
                          }
                        },
                  icon: _generatingHero
                      ? const FxLoading(size: 16, strokeWidth: 2)
                      : const Icon(Icons.auto_awesome_outlined),
                  label: const Text('Sugerir textos com IA'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _heroTitle,
                  decoration: const InputDecoration(
                    labelText: 'Título principal',
                    helperText: 'Aparece em destaque no topo da página.',
                  ),
                  maxLength: 180,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _heroSubtitle,
                  decoration: const InputDecoration(
                    labelText: 'Texto de apoio',
                    helperText: 'Explique em uma frase como você ajuda.',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final accentFix = landingCtaAccentSuggestion(_primaryCta.text);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _primaryCta,
                          decoration: const InputDecoration(
                            labelText: 'Texto do botão principal',
                            helperText: 'Ex.: Quero começar · Agendar avaliação',
                          ),
                        ),
                        if (accentFix != null) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () {
                                _primaryCta.text = accentFix;
                                _primaryCta.selection = TextSelection.collapsed(
                                  offset: accentFix.length,
                                );
                                _markDirty();
                              },
                              icon: const Icon(Icons.spellcheck, size: 18),
                              label: const Text('Corrigir acento em "avaliação"'),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _imageUploadCard(
                  title: 'Foto de capa',
                  hint: 'Grande imagem no topo — treino, estúdio ou você em ação.',
                  imageUrl: _heroImageUrl,
                  uploading: _uploadingHero,
                  onUpload: () => _uploadImage(hero: true),
                ),
                const SizedBox(height: 12),
                _imageUploadCard(
                  title: 'Foto na seção sobre',
                  hint: 'Retrato ou foto profissional na área "Sobre você".',
                  imageUrl: _bioImageUrl,
                  uploading: _uploadingBio,
                  onUpload: () => _uploadImage(hero: false),
                ),
              ],
            ),
          ),
        ),
        if (showHero) const SizedBox(height: 12),
        if (showSecondarySections)
          KeyedSubtree(
            key: _ctasSectionKey,
            child: LandingCollapsibleSection(
            title: 'Outros botões',
            hint: 'Textos extras que aparecem em planos, rodapé e contato.',
            expanded: _ctasExpanded,
            onExpandedChanged: (value) => setState(() => _ctasExpanded = value),
            child: Column(
              children: [
                TextField(
                  controller: _offerCta,
                  decoration: const InputDecoration(
                    labelText: 'Botão nos planos',
                    helperText: 'Ex.: Escolher plano · Quero esse plano',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _finalCta,
                  decoration: const InputDecoration(
                    labelText: 'Botão fixo no rodapé',
                    helperText: 'Barra que acompanha a rolagem no celular.',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contactCta,
                  decoration: const InputDecoration(
                    labelText: 'Botão na área de contato',
                    helperText: 'Ex.: Falar comigo · Chamar no WhatsApp',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showSecondarySections) const SizedBox(height: 12),
        if (showSecondarySections)
          KeyedSubtree(
            key: _servicosSectionKey,
            child: LandingCollapsibleSection(
            title: 'Serviços',
            hint: 'Formatos que você oferece — online, presencial ou híbrido.',
            expanded: _servicosExpanded,
            onExpandedChanged: (value) => setState(() => _servicosExpanded = value),
            onAdd: _addServico,
            child: Column(
              children: [
                if (_servicos.isEmpty)
                  Text(
                    'Nenhum serviço ainda. Toque em Adicionar para incluir.',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                for (var i = 0; i < _servicos.length; i++) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Serviço ${i + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeServico(i),
                                tooltip: 'Remover serviço',
                              ),
                            ],
                          ),
                          TextFormField(
                            key: ValueKey('servico-titulo-$i'),
                            initialValue: _servicos[i].titulo,
                            decoration: InputDecoration(
                              labelText: 'Nome do serviço',
                              helperText: landingPolishPreviewHint(_servicos[i].titulo),
                              helperMaxLines: 2,
                            ),
                            onChanged: (v) => _updateServico(i, titulo: v),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey('servico-desc-$i'),
                            initialValue: _servicos[i].descricao,
                            decoration:
                                const InputDecoration(labelText: 'Descrição curta'),
                            maxLines: 3,
                            onChanged: (v) => _updateServico(i, descricao: v),
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
        if (showSecondarySections) const SizedBox(height: 12),
        KeyedSubtree(
          key: _faqSectionKey,
          child: LandingCollapsibleSection(
            title: 'Dúvidas frequentes',
            hint: _reviewFocusMode
                ? 'Mostrando só perguntas que precisam de revisão.'
                : 'Respostas que removem objeções antes do cliente chamar.',
            expanded: _faqExpanded,
            onExpandedChanged: (value) => setState(() => _faqExpanded = value),
            onAdd: _reviewFocusMode ? null : _addFaq,
            child: Column(
              children: [
                if (_faq.isEmpty)
                  Text(
                    'Nenhuma pergunta ainda. Ex.: "Preciso treinar todos os dias?"',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                  ),
                if (_reviewFocusMode && hiddenFaqCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      hiddenFaqCount == 1
                          ? '1 pergunta ok — oculta no modo foco.'
                          : '$hiddenFaqCount perguntas ok — ocultas no modo foco.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                for (final i in visibleFaqIndices) ...[
                  KeyedSubtree(
                    key: _faqKeyFor(i),
                    child: LandingHighlightCard(
                      highlighted: _highlightedFaqIndex == i ||
                          landingFaqItemHasIssue(faq: _faqPayload(), index: i),
                      issueHint: landingFaqItemHasIssue(faq: _faqPayload(), index: i)
                          ? 'Revise o texto desta pergunta'
                          : null,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pergunta ${i + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeFaq(i),
                                tooltip: 'Remover pergunta',
                              ),
                            ],
                          ),
                          TextFormField(
                            key: ValueKey('faq-pergunta-$i'),
                            initialValue: _faq[i].pergunta,
                            decoration: InputDecoration(
                              labelText: 'Pergunta',
                              helperText: landingPolishPreviewHint(_faq[i].pergunta),
                              helperMaxLines: 2,
                            ),
                            onChanged: (v) => _updateFaq(i, pergunta: v),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey('faq-resposta-$i'),
                            initialValue: _faq[i].resposta,
                            decoration: InputDecoration(
                              labelText: 'Resposta',
                              helperText: landingPolishPreviewHint(_faq[i].resposta),
                              helperMaxLines: 2,
                            ),
                            maxLines: 3,
                            onChanged: (v) => _updateFaq(i, resposta: v),
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
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _ordemTab() {
    return ListView(
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        _sectionHeader(
          'Ordem das seções',
          hint:
              'Arraste pelo ícone ≡ ou use as setas. A abertura sempre fica no topo da página.',
        ),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sectionOrder.length,
          onReorder: _reorderSection,
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(animation.value);
                final scheme = Theme.of(context).colorScheme;
                return Material(
                  elevation: 4 + 8 * t,
                  shadowColor: scheme.primary.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(TokensStrip.rMd),
                  color: scheme.surface,
                  child: child,
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, i) {
            return LandingSectionOrderTile(
              key: ValueKey('section-${_sectionOrder[i]}-$i'),
              index: i,
              sectionKey: _sectionOrder[i],
              highlighted: _highlightedSectionKey == _sectionOrder[i],
              canMoveUp: i > 0,
              canMoveDown: i < _sectionOrder.length - 1,
              onMoveUp: () => _moveSection(i, -1),
              onMoveDown: () => _moveSection(i, 1),
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
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
        if (!_loaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _applyPerfil(perfil));
          });
        }

        return PopScope(
          canPop: !_dirty,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _tryPopAfterLeaveConfirm();
          },
          child: FxShellScaffold(
            appBar: FxShellAppBar(
              title: 'Editor da landing',
              subtitle: _dirty ? 'Alterações pendentes' : null,
              onBack: _tryPopAfterLeaveConfirm,
            ),
            bottomNavigationBar: LandingStickySaveBar(
              dirty: _dirty,
              saving: _saving,
              onSave: _salvar,
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_loaded)
                  LandingContentWarningBanner(
                    reviewCount: _contentReviewCount(),
                    onReview: () => _enterReviewFocus(),
                  ),
                LandingEditorTabBar(
                  index: _tabIndex,
                  onChanged: (value) => setState(() => _tabIndex = value),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: switch (_tabIndex) {
                      0 => KeyedSubtree(
                          key: const ValueKey('tab-links'),
                          child: _linksTab(_slug),
                        ),
                      1 => KeyedSubtree(
                          key: const ValueKey('tab-conteudo'),
                          child: _conteudoTab(),
                        ),
                      _ => KeyedSubtree(
                          key: const ValueKey('tab-ordem'),
                          child: _ordemTab(),
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

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

class LandingEditorScreen extends ConsumerStatefulWidget {
  const LandingEditorScreen({super.key});

  @override
  ConsumerState<LandingEditorScreen> createState() =>
      _LandingEditorScreenState();
}

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
  Timer? _highlightTimer;
  List<LandingNichePreset> _presets = [];
  List<LandingChecklistItem> _checklist = [];

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
    setState(() {
      _dirty = true;
    });
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
    _conteudoScroll.dispose();
    super.dispose();
  }

  List<String> _contentWarnings() {
    return landingContentWarnings(
      faq: _faq
          .map((e) => (pergunta: e.pergunta, resposta: e.resposta))
          .toList(),
      primaryCta: _primaryCta.text,
      heroTitle: _heroTitle.text,
    );
  }

  Future<void> _scrollToSection(GlobalKey key) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
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

  Future<bool> _confirmContentWarnings() async {
    final warnings = _contentWarnings();
    if (warnings.isEmpty) return true;

    final publish = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publicar mesmo assim?'),
        content: Text(
          '${warnings.join('\n\n')}\n\nSua página pode parecer incompleta para quem visita.',
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
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Você editou a landing e ainda não salvou. Se sair agora, perde as mudanças.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair sem salvar'),
          ),
        ],
      ),
    );
    return leave ?? false;
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
  }

  Future<void> _removeServico(int index) async {
    if (!await _confirmDelete('serviço ${index + 1}')) return;
    setState(() {
      _servicos = [..._servicos]..removeAt(index);
      _dirty = true;
    });
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
  }

  void _addFaq() {
    setState(() {
      _faq = [..._faq, const LandingFaqItem(pergunta: '', resposta: '')];
      _dirty = true;
    });
  }

  Future<void> _removeFaq(int index) async {
    if (!await _confirmDelete('pergunta ${index + 1}')) return;
    setState(() {
      _faq = [..._faq]..removeAt(index);
      _dirty = true;
    });
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
  }

  List<LandingFaqItem> _faqForSave() {
    return _faq
        .where((item) =>
            item.pergunta.trim().length >= 3 && item.resposta.trim().length >= 3)
        .toList();
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
      await ref.read(perfilRepositoryProvider).atualizarLanding(
            heroTitle: _heroTitle.text.trim(),
            heroSubtitle: _heroSubtitle.text.trim(),
            primaryCta: _primaryCta.text.trim(),
            sectionOrder: normalizedOrder,
            servicos: _servicos
                .where((s) =>
                    s.titulo.trim().isNotEmpty || s.descricao.trim().isNotEmpty)
                .toList(),
            faq: _faqForSave(),
            heroImageUrl: _heroImageUrl,
            bioImageUrl: _bioImageUrl,
            offerCta: _offerCta.text.trim(),
            finalCta: _finalCta.text.trim(),
            contactCta: _contactCta.text.trim(),
          );
      ref.invalidate(perfilProvider);
      if (!mounted) return;
      setState(() {
        _sectionOrder = normalizedOrder;
        _dirty = false;
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
        if (_presets.isNotEmpty) ...[
          const SizedBox(height: 20),
          _sectionHeader(
            'Modelos por nicho',
            hint: 'Preenche textos iniciais conforme seu público.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presets
                .map(
                  (p) => ActionChip(
                    label: Text(p.label),
                    onPressed: _saving
                        ? null
                        : () async {
                            try {
                              await ref
                                  .read(landingGrowthRepositoryProvider)
                                  .applyPreset(p.id);
                              ref.invalidate(perfilProvider);
                              if (!context.mounted) return;
                              FeedbackHelper.showSuccess(
                                context,
                                'Modelo "${p.label}" aplicado.',
                              );
                              await _loadGrowth();
                            } catch (e) {
                              if (!context.mounted) return;
                              FeedbackHelper.showError(context, friendlyError(e));
                            }
                          },
                  ),
                )
                .toList(),
          ),
        ],
        if (_checklistLoading) ...[
          const SizedBox(height: 16),
          const LandingChecklistSkeleton(),
        ] else if (_checklist.isNotEmpty) ...[
          const SizedBox(height: 16),
          LandingChecklistCard(
            items: _checklist,
            onItemTap: _onChecklistTap,
          ),
        ],
      ],
    );
  }

  Widget _conteudoTab() {
    return ListView(
      controller: _conteudoScroll,
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
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
                            if (!context.mounted) return;
                            FeedbackHelper.showSuccess(
                              context,
                              'Textos sugeridos pela IA.',
                            );
                            setState(() => _dirty = true);
                          } catch (e) {
                            if (!context.mounted) return;
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
                TextField(
                  controller: _primaryCta,
                  decoration: const InputDecoration(
                    labelText: 'Texto do botão principal',
                    helperText: 'Ex.: Quero começar · Agendar avaliação',
                  ),
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
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
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
                            decoration:
                                const InputDecoration(labelText: 'Nome do serviço'),
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
        const SizedBox(height: 12),
        KeyedSubtree(
          key: _faqSectionKey,
          child: LandingCollapsibleSection(
            title: 'Dúvidas frequentes',
            hint: 'Respostas que removem objeções antes do cliente chamar.',
            expanded: _faqExpanded,
            onExpandedChanged: (value) => setState(() => _faqExpanded = value),
            onAdd: _addFaq,
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
                for (var i = 0; i < _faq.length; i++) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
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
                            decoration: const InputDecoration(labelText: 'Pergunta'),
                            onChanged: (v) => _updateFaq(i, pergunta: v),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey('faq-resposta-$i'),
                            initialValue: _faq[i].resposta,
                            decoration: const InputDecoration(labelText: 'Resposta'),
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
            if (await _confirmLeave() && context.mounted) {
              context.pop();
            }
          },
          child: FxShellScaffold(
            appBar: FxShellAppBar(
              title: 'Editor da landing',
              subtitle: _dirty ? 'Alterações pendentes' : null,
              onBack: () async {
                if (await _confirmLeave() && context.mounted) {
                  context.pop();
                }
              },
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
                    warnings: _contentWarnings(),
                    onReview: () {
                      setState(() {
                        _tabIndex = 1;
                        _faqExpanded = true;
                      });
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToSection(_faqSectionKey);
                      });
                    },
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

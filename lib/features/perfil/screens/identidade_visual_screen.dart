import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';

const _coresPredefinidas = [
  Color(0xFF3B5FE2),
  Color(0xFF1E3A8A),
  Color(0xFF0097A7),
  Color(0xFF22C55E),
  Color(0xFFF59E0B),
  Color(0xFFEF4444),
  Color(0xFF7C3AED),
  Color(0xFFDB2777),
  Color(0xFF0369A1),
  Color(0xFF374151),
  Color(0xFF111827),
  Color(0xFF9D174D),
];

const _landingSectionCatalog = [
  _LandingSectionOption('prova', 'Prova social', Icons.verified_outlined),
  _LandingSectionOption('metodo', 'Metodo', Icons.route_outlined),
  _LandingSectionOption('sobre', 'Bio do personal', Icons.person_outline),
  _LandingSectionOption('ofertas', 'Servicos e planos', Icons.sell_outlined),
  _LandingSectionOption('depoimentos', 'Depoimentos', Icons.reviews_outlined),
  _LandingSectionOption('app', 'App e rotina', Icons.phone_iphone_outlined),
  _LandingSectionOption(
    'especialidades',
    'Especialidades',
    Icons.workspace_premium_outlined,
  ),
  _LandingSectionOption('faq', 'FAQ', Icons.help_outline),
  _LandingSectionOption('galeria', 'Galeria', Icons.photo_library_outlined),
  _LandingSectionOption('cta', 'CTA final', Icons.ads_click_outlined),
  _LandingSectionOption('contato', 'Contato', Icons.chat_bubble_outline),
];

class _LandingSectionOption {
  final String key;
  final String label;
  final IconData icon;

  const _LandingSectionOption(this.key, this.label, this.icon);
}

class IdentidadeVisualScreen extends ConsumerStatefulWidget {
  final bool isSetup;
  const IdentidadeVisualScreen({super.key, this.isSetup = false});

  @override
  ConsumerState<IdentidadeVisualScreen> createState() =>
      _IdentidadeVisualScreenState();
}

class _IdentidadeVisualScreenState
    extends ConsumerState<IdentidadeVisualScreen> {
  final _descCtrl = TextEditingController();
  final _espCtrl = TextEditingController();
  final _instaCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _domCtrl = TextEditingController();
  final _videoCtrl = TextEditingController();
  final _trackingCtrl = TextEditingController();
  final _heroImageCtrl = TextEditingController();
  final _bioImageCtrl = TextEditingController();
  final _heroTitleCtrl = TextEditingController();
  final _heroSubtitleCtrl = TextEditingController();
  final _primaryCtaCtrl = TextEditingController();
  final _serviceTitleCtrls = List.generate(3, (_) => TextEditingController());
  final _serviceDescCtrls = List.generate(3, (_) => TextEditingController());
  final _packageNameCtrls = List.generate(3, (_) => TextEditingController());
  final _packagePriceCtrls = List.generate(3, (_) => TextEditingController());
  final _packageDescCtrls = List.generate(3, (_) => TextEditingController());
  final _faqQuestionCtrls = List.generate(4, (_) => TextEditingController());
  final _faqAnswerCtrls = List.generate(4, (_) => TextEditingController());
  Color _corPrimaria = const Color(0xFF3B5FE2);
  Color _corSecundaria = const Color(0xFF0097A7);
  bool _salvando = false;
  bool _uploadingLogo = false;
  bool _uploadingVideo = false;
  bool _uploadingHeroPhoto = false;
  bool _uploadingBioPhoto = false;
  bool _perfilLoaded = false;
  final bool _showManualVideoUrl = false;
  String? _logoUrl;
  late List<String> _sectionOrder = _defaultSectionOrder();
  final Set<String> _hiddenSections = {};

  static List<String> _defaultSectionOrder() =>
      _landingSectionCatalog.map((item) => item.key).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(perfilProvider);
    });
  }

  void _applyPerfil(PerfilPersonal perfil) {
    _descCtrl.text = perfil.descricaoProfissional ?? '';
    _espCtrl.text = perfil.especialidades ?? '';
    _instaCtrl.text = perfil.instagram ?? '';
    _sloganCtrl.text = perfil.slogan ?? '';
    _domCtrl.text = perfil.dominioCustomizado ?? '';
    _videoCtrl.text = perfil.videoUrl ?? '';
    _trackingCtrl.text = perfil.trackingId ?? '';
    final heroImageUrl = perfil.heroImageUrl?.trim() ?? '';
    _heroImageCtrl.text =
        _isAiGeneratedHeroUrl(heroImageUrl) ? '' : heroImageUrl;
    final bioImageUrl = perfil.bioImageUrl?.trim() ?? '';
    _bioImageCtrl.text = _isAiGeneratedHeroUrl(bioImageUrl) ? '' : bioImageUrl;
    _heroTitleCtrl.text = perfil.heroTitle ?? '';
    _heroSubtitleCtrl.text = perfil.heroSubtitle ?? '';
    _primaryCtaCtrl.text = perfil.primaryCta ?? '';
    final savedOrder = perfil.sectionOrder.where(_isKnownSection).toList();
    _sectionOrder =
        savedOrder.isEmpty
            ? _defaultSectionOrder()
            : _mergeSectionOrder(savedOrder);
    _hiddenSections
      ..clear()
      ..addAll(perfil.hiddenSections.where(_isKnownSection));
    _logoUrl = perfil.logoUrl;
    if (perfil.corPrimaria != null && perfil.corPrimaria!.length == 7) {
      final hex = int.tryParse(perfil.corPrimaria!.replaceFirst('#', '0xFF'));
      if (hex != null) _corPrimaria = Color(hex);
    }
    if (perfil.corSecundaria != null && perfil.corSecundaria!.length == 7) {
      final hex = int.tryParse(perfil.corSecundaria!.replaceFirst('#', '0xFF'));
      if (hex != null) _corSecundaria = Color(hex);
    }
    for (var i = 0; i < 3; i++) {
      final servico = i < perfil.servicos.length ? perfil.servicos[i] : null;
      _serviceTitleCtrls[i].text = servico?.titulo ?? '';
      _serviceDescCtrls[i].text = servico?.descricao ?? '';

      final pacote = i < perfil.pacotes.length ? perfil.pacotes[i] : null;
      _packageNameCtrls[i].text = pacote?.nome ?? '';
      _packagePriceCtrls[i].text = pacote?.preco ?? '';
      _packageDescCtrls[i].text = pacote?.descricao ?? '';
    }
    for (var i = 0; i < _faqQuestionCtrls.length; i++) {
      final item = i < perfil.faq.length ? perfil.faq[i] : null;
      _faqQuestionCtrls[i].text = item?.pergunta ?? '';
      _faqAnswerCtrls[i].text = item?.resposta ?? '';
    }
    _perfilLoaded = true;
  }

  List<Map<String, dynamic>> _buildServicosPayload() {
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < _serviceTitleCtrls.length; i++) {
      final titulo = _serviceTitleCtrls[i].text.trim();
      final descricao = _serviceDescCtrls[i].text.trim();
      if (titulo.isEmpty && descricao.isEmpty) continue;
      items.add({'titulo': titulo, 'descricao': descricao});
    }
    return items;
  }

  List<Map<String, dynamic>> _buildPacotesPayload() {
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < _packageNameCtrls.length; i++) {
      final nome = _packageNameCtrls[i].text.trim();
      final preco = _packagePriceCtrls[i].text.trim();
      final descricao = _packageDescCtrls[i].text.trim();
      if (nome.isEmpty && preco.isEmpty && descricao.isEmpty) continue;
      items.add({
        'nome': nome,
        'preco': preco,
        'descricao': descricao,
        'cta': 'Quero saber mais',
      });
    }
    return items;
  }

  List<Map<String, dynamic>> _buildFaqPayload() {
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < _faqQuestionCtrls.length; i++) {
      final pergunta = _faqQuestionCtrls[i].text.trim();
      final resposta = _faqAnswerCtrls[i].text.trim();
      if (pergunta.isEmpty && resposta.isEmpty) continue;
      items.add({'pergunta': pergunta, 'resposta': resposta});
    }
    return items;
  }

  List<String> _mergeSectionOrder(List<String> savedOrder) {
    final result = <String>[];
    for (final key in savedOrder) {
      if (_isKnownSection(key) && !result.contains(key)) result.add(key);
    }
    for (final option in _landingSectionCatalog) {
      if (!result.contains(option.key)) result.add(option.key);
    }
    return result;
  }

  bool _isKnownSection(String key) =>
      _landingSectionCatalog.any((option) => option.key == key);

  @override
  void dispose() {
    _descCtrl.dispose();
    _espCtrl.dispose();
    _instaCtrl.dispose();
    _sloganCtrl.dispose();
    _domCtrl.dispose();
    _videoCtrl.dispose();
    _trackingCtrl.dispose();
    _heroImageCtrl.dispose();
    _bioImageCtrl.dispose();
    _heroTitleCtrl.dispose();
    _heroSubtitleCtrl.dispose();
    _primaryCtaCtrl.dispose();
    for (final controller in _serviceTitleCtrls) {
      controller.dispose();
    }
    for (final controller in _serviceDescCtrls) {
      controller.dispose();
    }
    for (final controller in _packageNameCtrls) {
      controller.dispose();
    }
    for (final controller in _packagePriceCtrls) {
      controller.dispose();
    }
    for (final controller in _packageDescCtrls) {
      controller.dispose();
    }
    for (final controller in _faqQuestionCtrls) {
      controller.dispose();
    }
    for (final controller in _faqAnswerCtrls) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingLogo = true);
    try {
      final url = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'identidade',
        resourceType: 'image',
      );
      if (mounted) setState(() => _logoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _pickPresentationVideo(String plano) async {
    final file = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingVideo = true);
    try {
      final url = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'landing/apresentacao',
        resourceType: 'video',
      );
      if (mounted) {
        setState(() => _videoCtrl.text = url);
        await _salvar(
          plano,
          successMessage: 'Video de apresentacao enviado e salvo na landing.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar video: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingVideo = false);
    }
  }

  Future<void> _pickHeroPhoto(String plano) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingHeroPhoto = true);
    try {
      final url = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'landing/hero',
        resourceType: 'image',
      );
      if (mounted) {
        setState(() => _heroImageCtrl.text = url);
        await _salvar(
          plano,
          successMessage: 'Foto principal enviada e salva na landing.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingHeroPhoto = false);
    }
  }

  Future<void> _pickBioPhoto(String plano) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1400,
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingBioPhoto = true);
    try {
      final url = await MediaUploadService(
        ref.read(apiClientProvider),
      ).uploadBytes(
        bytes: await file.readAsBytes(),
        filename: file.name,
        folder: 'landing/bio',
        resourceType: 'image',
      );
      if (mounted) {
        setState(() => _bioImageCtrl.text = url);
        await _salvar(
          plano,
          successMessage: 'Foto pessoal enviada e salva na bio da landing.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao enviar foto: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingBioPhoto = false);
    }
  }

  Future<void> _salvar(
    String plano, {
    String successMessage = 'Identidade visual salva!',
  }) async {
    if (plano.toUpperCase() == 'FREE') return;
    setState(() => _salvando = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final body = <String, dynamic>{
        'descricaoProfissional': _descCtrl.text.trim(),
        'especialidades': _espCtrl.text.trim(),
        'instagram': _instaCtrl.text.trim(),
        'servicos': _buildServicosPayload(),
        'pacotes': _buildPacotesPayload(),
        'faq': _buildFaqPayload(),
        'heroTitle': _heroTitleCtrl.text.trim(),
        'heroSubtitle': _heroSubtitleCtrl.text.trim(),
        'primaryCta': _primaryCtaCtrl.text.trim(),
        'sectionOrder': _sectionOrder,
        'hiddenSections': _hiddenSections.toList(),
      };
      if (plano.toUpperCase() == 'ENTERPRISE') {
        body['corPrimaria'] =
            '#${_corPrimaria.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
        body['corSecundaria'] =
            '#${_corSecundaria.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
        body['slogan'] = _sloganCtrl.text.trim();
        if (_logoUrl != null) {
          body['logoUrl'] = _logoUrl;
        }
        if (_domCtrl.text.trim().isNotEmpty) {
          body['dominioCustomizado'] = _domCtrl.text.trim();
        }
        if (_videoCtrl.text.trim().isNotEmpty) {
          body['videoUrl'] = _videoCtrl.text.trim();
        }
        body['trackingId'] = _trackingCtrl.text.trim();
        final typedHeroUrl = _heroImageCtrl.text.trim();
        body['heroPrompt'] = '';
        body['heroImageUrl'] =
            typedHeroUrl.isEmpty || _isAiGeneratedHeroUrl(typedHeroUrl)
                ? ''
                : typedHeroUrl;
        final typedBioUrl = _bioImageCtrl.text.trim();
        body['bioImageUrl'] =
            typedBioUrl.isEmpty || _isAiGeneratedHeroUrl(typedBioUrl)
                ? ''
                : typedBioUrl;
      }
      await dio.put('/api/personal/identidade', data: body);
      if (plano.toUpperCase() == 'ENTERPRISE') {
        ref.read(primaryColorProvider.notifier).state = _corPrimaria;
        if (_logoUrl != null && _logoUrl!.isNotEmpty) {
          ref.read(logoUrlProvider.notifier).state = _logoUrl;
        }
      }
      ref.invalidate(perfilProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
        if (widget.isSetup) context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  bool _isAiGeneratedHeroUrl(String url) {
    final value = url.trim().toLowerCase();
    return value.contains('image.pollinations.ai/prompt/');
  }

  bool _isDirectVideoUrl(String url) {
    final clean = url.toLowerCase().split('?').first;
    return clean.endsWith('.mp4') ||
        clean.endsWith('.webm') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.m4v');
  }

  void _moveSection(String key, int delta) {
    final index = _sectionOrder.indexOf(key);
    if (index < 0) return;
    final next = (index + delta).clamp(0, _sectionOrder.length - 1);
    if (next == index) return;
    setState(() {
      final item = _sectionOrder.removeAt(index);
      _sectionOrder.insert(next, item);
    });
  }

  void _toggleSection(String key, bool visible) {
    setState(() {
      if (visible) {
        _hiddenSections.remove(key);
      } else {
        _hiddenSections.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final perfil = perfilAsync.value;
    if (perfil != null && !_perfilLoaded) {
      _applyPerfil(perfil);
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plano = perfil?.plano ?? 'FREE';
    final isEnterprise = plano.toUpperCase() == 'ENTERPRISE';
    final isPremiumOrAbove = [
      'PREMIUM',
      'ENTERPRISE',
    ].contains(plano.toUpperCase());
    final themePrimary = Theme.of(context).colorScheme.primary;
    final themePrimarySoft = BrandPalette.soft(themePrimary, dark: isDark);

    final slug = perfil?.slug;
    final nomePersonal = perfil?.nome ?? '';
    final heroPhotoUrl = _heroImageCtrl.text.trim();
    final heroPhotoReady = heroPhotoUrl.isNotEmpty;
    final bioPhotoUrl = _bioImageCtrl.text.trim();
    final bioPhotoReady = bioPhotoUrl.isNotEmpty;
    final servicesCount = _buildServicosPayload().length;
    final packagesCount = _buildPacotesPayload().length;
    final faqCount = _buildFaqPayload().length;

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isSetup ? 'Configurar meu app' : 'Identidade Visual',
        ),
        automaticallyImplyLeading: !widget.isSetup,
        leading:
            widget.isSetup
                ? null
                : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => safePopOrGo(context, '/dashboard/personal'),
                ),
        actions: [
          if (isPremiumOrAbove)
            TextButton(
              onPressed: _salvando ? null : () => _salvar(plano),
              child:
                  _salvando
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(
                        'Salvar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FREE PAYWALL
            if (!isPremiumOrAbove) ...[
              _PaywallCard(
                icon: Icons.web,
                title: '🔒 Recurso Premium',
                subtitle:
                    'Crie sua landing page pública e apareça para novos alunos.',
                buttonText: 'Assinar Premium',
                onTap: () => context.go('/assinatura'),
                isDark: isDark,
              ),
              const SizedBox(height: 24),
            ],

            // SECTION A — Landing page content (PREMIUM+)
            _SectionHeader(text: 'Sua landing page', isDark: isDark),
            const SizedBox(height: 8),
            _LandingCoachCard(
              isDark: isDark,
              title: 'Direcao criativa',
              tips: const [
                'Escolha uma promessa clara: emagrecimento, performance, hipertrofia ou saude.',
                'Use fotos e videos reais para passar confianca antes do aluno chamar.',
                'Deixe preco, servicos e duvidas frequentes simples de comparar.',
                'Escolha uma direcao editorial: a landing fica unica pela foto real, promessa, cores, video e oferta do personal.',
              ],
            ),
            const SizedBox(height: 12),

            // Slug display
            if (slug != null && isPremiumOrAbove) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 16,
                      color:
                          isDark
                              ? EagleTokens.darkInkMute
                              : EagleTokens.inkMute,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'focux.app/p/$slug',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: 'https://focux.app/p/$slug'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link copiado!')),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Ver minha landing page'),
                  onPressed: () => context.go('/p/$slug'),
                ),
              ),
              const SizedBox(height: 16),
            ],

            AbsorbPointer(
              absorbing: !isPremiumOrAbove,
              child: Opacity(
                opacity: isPremiumOrAbove ? 1.0 : 0.35,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _descCtrl,
                      enabled: isPremiumOrAbove,
                      maxLines: 3,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Descrição profissional',
                        hintText: 'Descreva sua trajetória e metodologia...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _espCtrl,
                      enabled: isPremiumOrAbove,
                      decoration: const InputDecoration(
                        labelText: 'Especialidades',
                        hintText: 'Ex: Musculação, Funcional, Emagrecimento',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _instaCtrl,
                      enabled: isPremiumOrAbove,
                      decoration: const InputDecoration(
                        labelText: 'Instagram',
                        prefixText: '@',
                        hintText: 'seuperfil',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _LandingEditorCard(
                      isDark: isDark,
                      title: 'Controle editorial',
                      subtitle:
                          'Personalize a primeira dobra e escolha a ordem das secoes para sua landing nao parecer template.',
                      child: _LandingEditorialControls(
                        isPremiumOrAbove: isPremiumOrAbove,
                        isDark: isDark,
                        primary: themePrimary,
                        heroTitleCtrl: _heroTitleCtrl,
                        heroSubtitleCtrl: _heroSubtitleCtrl,
                        primaryCtaCtrl: _primaryCtaCtrl,
                        sectionOrder: _sectionOrder,
                        hiddenSections: _hiddenSections,
                        onMove: _moveSection,
                        onToggle: _toggleSection,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LandingEditorCard(
                      isDark: isDark,
                      title: 'Servicos em destaque',
                      subtitle:
                          'Mostre o que voce entrega na pratica. Isso alimenta a secao publica da landing.',
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < _serviceTitleCtrls.length;
                            i++
                          ) ...[
                            TextFormField(
                              controller: _serviceTitleCtrls[i],
                              enabled: isPremiumOrAbove,
                              decoration: InputDecoration(
                                labelText: 'Servico ${i + 1}',
                                hintText: 'Ex: Consultoria online',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _serviceDescCtrls[i],
                              enabled: isPremiumOrAbove,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Descricao',
                                hintText:
                                    'Explique o formato, frequencia e para quem esse servico faz sentido.',
                                alignLabelWithHint: true,
                              ),
                            ),
                            if (i != _serviceTitleCtrls.length - 1)
                              const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LandingEditorCard(
                      isDark: isDark,
                      title: 'Pacotes e valores',
                      subtitle:
                          'Cadastre ate 3 opcoes de entrada para o aluno entender seu ticket.',
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < _packageNameCtrls.length;
                            i++
                          ) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _packageNameCtrls[i],
                                    enabled: isPremiumOrAbove,
                                    decoration: InputDecoration(
                                      labelText: 'Pacote ${i + 1}',
                                      hintText: 'Ex: Plano mensal',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 132,
                                  child: TextFormField(
                                    controller: _packagePriceCtrls[i],
                                    enabled: isPremiumOrAbove,
                                    decoration: const InputDecoration(
                                      labelText: 'Preco',
                                      hintText: 'R\$ 297',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _packageDescCtrls[i],
                              enabled: isPremiumOrAbove,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Descricao do pacote',
                                hintText:
                                    'Ex: Treino personalizado, ajustes semanais e suporte no chat.',
                                alignLabelWithHint: true,
                              ),
                            ),
                            if (i != _packageNameCtrls.length - 1)
                              const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LandingEditorCard(
                      isDark: isDark,
                      title: 'FAQ de venda',
                      subtitle:
                          'Responda as duvidas que mais travam a decisao antes do aluno chamar voce.',
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < _faqQuestionCtrls.length;
                            i++
                          ) ...[
                            TextFormField(
                              controller: _faqQuestionCtrls[i],
                              enabled: isPremiumOrAbove,
                              decoration: InputDecoration(
                                labelText: 'Pergunta ${i + 1}',
                                hintText: 'Ex: Preciso treinar todos os dias?',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _faqAnswerCtrls[i],
                              enabled: isPremiumOrAbove,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Resposta',
                                hintText:
                                    'Explique de forma simples, direta e segura.',
                                alignLabelWithHint: true,
                              ),
                            ),
                            if (i != _faqQuestionCtrls.length - 1)
                              const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // SECTION B — Brand / Enterprise
            _SectionHeader(text: 'Identidade Visual', isDark: isDark),
            const SizedBox(height: 8),

            if (!isEnterprise) ...[
              _PaywallCard(
                icon: Icons.palette_outlined,
                title: '🔒 Recurso Enterprise',
                subtitle:
                    'Aplique sua marca no app dos seus alunos. Cores, logo e slogan 100% seus.',
                buttonText: 'Assinar Enterprise',
                onTap: () => context.go('/assinatura'),
                isDark: isDark,
              ),
              const SizedBox(height: 16),
            ],

            AbsorbPointer(
              absorbing: !isEnterprise,
              child: Opacity(
                opacity: isEnterprise ? 1.0 : 0.35,
                child: Column(
                  children: [
                    // Logo upload
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor:
                                isDark
                                    ? EagleTokens.darkCard
                                    : themePrimarySoft,
                            backgroundImage:
                                _logoUrl != null
                                    ? NetworkImage(_logoUrl!)
                                    : null,
                            child:
                                _logoUrl == null
                                    ? Text(
                                      nomePersonal.isNotEmpty
                                          ? nomePersonal[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isDark
                                                ? EagleTokens.darkInk
                                                : themePrimary,
                                      ),
                                    )
                                    : null,
                          ),
                          GestureDetector(
                            onTap: isEnterprise ? _pickLogo : null,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color:
                                    isEnterprise ? _corPrimaria : themePrimary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isDark
                                          ? EagleTokens.darkBg
                                          : EagleTokens.paper,
                                  width: 2,
                                ),
                              ),
                              child:
                                  _uploadingLogo
                                      ? const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.camera_alt,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Slogan
                    TextFormField(
                      controller: _sloganCtrl,
                      enabled: isEnterprise,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Slogan',
                        hintText:
                            'Ex: Transformando vidas através do movimento',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cor principal
                    Text(
                      'Cor principal',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _ColorPicker(
                      selected: _corPrimaria,
                      onSelect:
                          isEnterprise
                              ? (c) => setState(() => _corPrimaria = c)
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Cor secundária
                    Text(
                      'Cor secundária',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _ColorPicker(
                      selected: _corSecundaria,
                      onSelect:
                          isEnterprise
                              ? (c) => setState(() => _corSecundaria = c)
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _domCtrl,
                      enabled: isEnterprise,
                      decoration: const InputDecoration(
                        labelText: 'Domínio customizado',
                        hintText: 'Ex: treino.seudominio.com.br',
                        helperText:
                            'Configure um CNAME apontando para focux.app',
                        helperMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LandingEditorCard(
                      isDark: isDark,
                      title: 'Video de apresentacao',
                      subtitle:
                          'Suba um video curto seu. Ele aparece como player dentro da primeira tela da landing.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showManualVideoUrl) ...[
                            TextFormField(
                              controller: _videoCtrl,
                              enabled: isEnterprise,
                              decoration: const InputDecoration(
                                labelText: 'URL do vídeo de apresentação',
                                hintText: 'https://cdn.focux.app/video.mp4',
                                helperText:
                                    'Use MP4/WebM para player embutido. YouTube/Vimeo abrem em link externo.',
                                helperMaxLines: 2,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          OutlinedButton.icon(
                            onPressed:
                                isEnterprise && !_uploadingVideo
                                    ? () => _pickPresentationVideo(plano)
                                    : null,
                            icon:
                                _uploadingVideo
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.video_call_outlined),
                            label: Text(
                              _uploadingVideo
                                  ? 'Enviando video...'
                                  : _videoCtrl.text.trim().isEmpty
                                  ? 'Subir video de apresentacao'
                                  : 'Trocar video de apresentacao',
                            ),
                          ),
                          if (_videoCtrl.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _LandingMediaStatusCard(
                              isDark: isDark,
                              icon: Icons.play_circle_outline,
                              title: 'Video enviado para a landing',
                              subtitle:
                                  _isDirectVideoUrl(_videoCtrl.text.trim())
                                      ? 'Vai abrir em player embutido na primeira tela.'
                                      : 'Arquivo enviado. Se nao aparecer como player, envie em MP4, WebM, MOV ou M4V.',
                              url: _videoCtrl.text.trim(),
                              showUrl: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LandingEditorCard(
                      isDark: isDark,
                      title: 'Foto principal da landing',
                      subtitle:
                          'Suba uma foto real sua, do seu estudio ou de um atendimento. Essa foto vira o impacto visual da primeira tela.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroPhotoPreview(
                            isDark: isDark,
                            url: heroPhotoUrl,
                            primary: _corPrimaria,
                            secondary: _corSecundaria,
                            name: nomePersonal,
                            slogan: _sloganCtrl.text.trim(),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                isEnterprise && !_uploadingHeroPhoto
                                    ? () => _pickHeroPhoto(plano)
                                    : null,
                            icon:
                                _uploadingHeroPhoto
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.add_photo_alternate),
                            label: Text(
                              _uploadingHeroPhoto
                                  ? 'Enviando foto...'
                                  : heroPhotoReady
                                  ? 'Trocar foto principal'
                                  : 'Subir foto principal',
                            ),
                          ),
                          if (heroPhotoReady) ...[
                            const SizedBox(height: 10),
                            _LandingMediaStatusCard(
                              isDark: isDark,
                              icon: Icons.photo_camera_back_outlined,
                              title: 'Foto conectada ao hero',
                              subtitle:
                                  'A landing usa esta foto com recorte premium, overlay e assinatura visual da marca.',
                              url: heroPhotoUrl,
                              showUrl: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LandingEditorCard(
                      isDark: isDark,
                      title: 'Foto pessoal da bio',
                      subtitle:
                          'Suba uma foto sua separada para a secao Sobre. Ideal: retrato profissional, voce atendendo aluno ou imagem de autoridade, sem repetir a foto de capa.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _BioPhotoPreview(
                            isDark: isDark,
                            url: bioPhotoUrl,
                            primary: _corPrimaria,
                            name: nomePersonal,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed:
                                isEnterprise && !_uploadingBioPhoto
                                    ? () => _pickBioPhoto(plano)
                                    : null,
                            icon:
                                _uploadingBioPhoto
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(Icons.person_pin_outlined),
                            label: Text(
                              _uploadingBioPhoto
                                  ? 'Enviando foto...'
                                  : bioPhotoReady
                                  ? 'Trocar foto da bio'
                                  : 'Subir foto da bio',
                            ),
                          ),
                          if (bioPhotoReady) ...[
                            const SizedBox(height: 10),
                            _LandingMediaStatusCard(
                              isDark: isDark,
                              icon: Icons.person_outline,
                              title: 'Foto conectada a bio',
                              subtitle:
                                  'A secao Sobre usa esta foto separada para contar quem e o personal sem repetir a capa.',
                              url: bioPhotoUrl,
                              showUrl: false,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LandingEditorCard(
                      isDark: isDark,
                      title: 'Publicacao e campanha',
                      subtitle:
                          'Use tracking para saber de onde veio o aluno. O dominio customizado fica acima, junto da marca.',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _trackingCtrl,
                            enabled: isEnterprise,
                            decoration: const InputDecoration(
                              labelText: 'Tracking de campanha',
                              hintText: 'Ex: campanha-instagram-abril',
                              helperText:
                                  'Entra nos links de cadastro da landing para medir origem.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LandingPremiumPlanner(
                      isDark: isDark,
                      primary: _corPrimaria,
                      secondary: _corSecundaria,
                      name: nomePersonal,
                      slogan: _sloganCtrl.text.trim(),
                      specialty: _espCtrl.text.trim(),
                      heroPhotoReady: heroPhotoReady,
                      bioPhotoReady: bioPhotoReady,
                      videoReady: _videoCtrl.text.trim().isNotEmpty,
                      aboutReady: _descCtrl.text.trim().isNotEmpty,
                      servicesCount: servicesCount,
                      packagesCount: packagesCount,
                      faqCount: faqCount,
                    ),
                    const SizedBox(height: 20),

                    // Preview
                    _PremiumLandingPreviewCard(
                      primary: _corPrimaria,
                      secondary: _corSecundaria,
                      logoUrl: _logoUrl,
                      heroPhotoUrl: heroPhotoUrl,
                      name: nomePersonal,
                      slogan: _sloganCtrl.text.trim(),
                      specialty: _espCtrl.text.trim(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            if (isPremiumOrAbove)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _salvando ? null : () => _salvar(plano),
                  style:
                      isEnterprise
                          ? FilledButton.styleFrom(
                            backgroundColor: _corPrimaria,
                          )
                          : null,
                  child:
                      _salvando
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            widget.isSetup
                                ? 'Finalizar configuração'
                                : 'Salvar',
                          ),
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _LandingEditorialControls extends StatelessWidget {
  final bool isPremiumOrAbove;
  final bool isDark;
  final Color primary;
  final TextEditingController heroTitleCtrl;
  final TextEditingController heroSubtitleCtrl;
  final TextEditingController primaryCtaCtrl;
  final List<String> sectionOrder;
  final Set<String> hiddenSections;
  final void Function(String key, int delta) onMove;
  final void Function(String key, bool visible) onToggle;

  const _LandingEditorialControls({
    required this.isPremiumOrAbove,
    required this.isDark,
    required this.primary,
    required this.heroTitleCtrl,
    required this.heroSubtitleCtrl,
    required this.primaryCtaCtrl,
    required this.sectionOrder,
    required this.hiddenSections,
    required this.onMove,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final optionsByKey = {
      for (final option in _landingSectionCatalog) option.key: option,
    };
    final orderedOptions =
        sectionOrder
            .where(optionsByKey.containsKey)
            .map((key) => optionsByKey[key]!)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: heroTitleCtrl,
          enabled: isPremiumOrAbove,
          maxLength: 90,
          decoration: const InputDecoration(
            labelText: 'Titulo principal do hero',
            hintText: 'Ex: O corpo forte que combina com sua rotina',
            helperText: 'Se ficar vazio, a Focux cria uma headline pelo nicho.',
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: heroSubtitleCtrl,
          enabled: isPremiumOrAbove,
          maxLines: 3,
          maxLength: 320,
          decoration: const InputDecoration(
            labelText: 'Texto de apoio',
            hintText:
                'Ex: Treino, check-ins e ajustes para evoluir com clareza.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: primaryCtaCtrl,
          enabled: isPremiumOrAbove,
          maxLength: 36,
          decoration: const InputDecoration(
            labelText: 'Botao principal',
            hintText: 'Ex: Quero minha avaliacao',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ordem e visibilidade',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Hero e rodape ficam fixos. Reordene o restante para destacar o que mais vende seu trabalho.',
          style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < orderedOptions.length; i++) ...[
          _LandingSectionControlTile(
            option: orderedOptions[i],
            index: i,
            total: orderedOptions.length,
            visible: !hiddenSections.contains(orderedOptions[i].key),
            primary: primary,
            isDark: isDark,
            enabled: isPremiumOrAbove,
            onMove: onMove,
            onToggle: onToggle,
          ),
          if (i != orderedOptions.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _LandingSectionControlTile extends StatelessWidget {
  final _LandingSectionOption option;
  final int index;
  final int total;
  final bool visible;
  final Color primary;
  final bool isDark;
  final bool enabled;
  final void Function(String key, int delta) onMove;
  final void Function(String key, bool visible) onToggle;

  const _LandingSectionControlTile({
    required this.option,
    required this.index,
    required this.total,
    required this.visible,
    required this.primary,
    required this.isDark,
    required this.enabled,
    required this.onMove,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(option.icon, color: visible ? primary : mute, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              option.label,
              style: TextStyle(
                color: visible ? ink : mute,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Subir',
            onPressed:
                enabled && index > 0 ? () => onMove(option.key, -1) : null,
            icon: const Icon(Icons.keyboard_arrow_up),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: 'Descer',
            onPressed:
                enabled && index < total - 1
                    ? () => onMove(option.key, 1)
                    : null,
            icon: const Icon(Icons.keyboard_arrow_down),
            visualDensity: VisualDensity.compact,
          ),
          Switch.adaptive(
            value: visible,
            activeColor: primary,
            onChanged: enabled ? (value) => onToggle(option.key, value) : null,
          ),
        ],
      ),
    );
  }
}

class _PaywallCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onTap;
  final bool isDark;

  const _PaywallCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: onTap, child: Text(buttonText)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionHeader({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _LandingCoachCard extends StatelessWidget {
  final String title;
  final List<String> tips;
  final bool isDark;

  const _LandingCoachCard({
    required this.title,
    required this.tips,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: primary, size: 15),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tip,
                      style: TextStyle(color: mute, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeroPhotoPreview extends StatelessWidget {
  final bool isDark;
  final String url;
  final Color primary;
  final Color secondary;
  final String name;
  final String slogan;

  const _HeroPhotoPreview({
    required this.isDark,
    required this.url,
    required this.primary,
    required this.secondary,
    required this.name,
    required this.slogan,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = url.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => _PremiumHeroPreviewCanvas(
                      primary: primary,
                      secondary: secondary,
                    ),
              )
            else
              _PremiumHeroPreviewCanvas(primary: primary, secondary: secondary),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF050814).withValues(alpha: 0.88),
                    const Color(0xFF050814).withValues(alpha: 0.44),
                    primary.withValues(alpha: 0.20),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPhoto ? 'FOTO REAL DA LANDING' : 'ASSINATURA PREMIUM',
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    slogan.isNotEmpty ? slogan : name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.02,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasPhoto
                        ? 'Recorte com overlay, contraste e identidade visual.'
                        : 'Envie uma foto para deixar a primeira dobra humana.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontSize: 12,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BioPhotoPreview extends StatelessWidget {
  final bool isDark;
  final String url;
  final Color primary;
  final String name;

  const _BioPhotoPreview({
    required this.isDark,
    required this.url,
    required this.primary,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = url.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 94,
              height: 118,
              child:
                  hasPhoto
                      ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => _BioPhotoFallback(primary: primary),
                      )
                      : _BioPhotoFallback(primary: primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPhoto ? 'BIO COM FOTO PROPRIA' : 'FOTO DE BIO PENDENTE',
                  style: TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name.isNotEmpty ? name : 'Seu nome na landing',
                  style: TextStyle(
                    color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  hasPhoto
                      ? 'A secao Sobre vai usar este retrato, separado da foto de capa.'
                      : 'Use uma foto pessoal para a bio nao repetir o hero da landing.',
                  style: TextStyle(
                    color:
                        isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BioPhotoFallback extends StatelessWidget {
  final Color primary;

  const _BioPhotoFallback({required this.primary});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary.withValues(alpha: 0.28), const Color(0xFF111827)],
        ),
      ),
      child: Icon(
        Icons.person_pin_outlined,
        color: Colors.white.withValues(alpha: 0.72),
        size: 34,
      ),
    );
  }
}

class _PremiumHeroPreviewCanvas extends StatelessWidget {
  final Color primary;
  final Color secondary;

  const _PremiumHeroPreviewCanvas({
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PremiumHeroPreviewPainter(
        primary: primary,
        secondary: secondary,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _PremiumHeroPreviewPainter extends CustomPainter {
  final Color primary;
  final Color secondary;

  const _PremiumHeroPreviewPainter({
    required this.primary,
    required this.secondary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final background =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF050814),
              Color.lerp(primary, const Color(0xFF050814), 0.64)!,
              Color.lerp(secondary, const Color(0xFF111827), 0.62)!,
            ],
          ).createShader(rect);
    canvas.drawRect(rect, background);

    final grid =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..strokeWidth = 1;
    for (var x = -size.height; x < size.width + size.height; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), grid);
    }

    final ribbon =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..color = primary.withValues(alpha: 0.42);
    final path =
        Path()
          ..moveTo(size.width * 0.62, -20)
          ..cubicTo(
            size.width * 0.96,
            size.height * 0.20,
            size.width * 0.58,
            size.height * 0.62,
            size.width * 0.88,
            size.height + 20,
          );
    canvas.drawPath(path, ribbon);

    final glow =
        Paint()
          ..shader = RadialGradient(
            colors: [
              primary.withValues(alpha: 0.34),
              primary.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.80, size.height * 0.22),
              radius: size.width * 0.38,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.80, size.height * 0.22),
      size.width * 0.38,
      glow,
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumHeroPreviewPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }
}

class _LandingPremiumPlanner extends StatelessWidget {
  final bool isDark;
  final Color primary;
  final Color secondary;
  final String name;
  final String slogan;
  final String specialty;
  final bool heroPhotoReady;
  final bool bioPhotoReady;
  final bool videoReady;
  final bool aboutReady;
  final int servicesCount;
  final int packagesCount;
  final int faqCount;

  const _LandingPremiumPlanner({
    required this.isDark,
    required this.primary,
    required this.secondary,
    required this.name,
    required this.slogan,
    required this.specialty,
    required this.heroPhotoReady,
    required this.bioPhotoReady,
    required this.videoReady,
    required this.aboutReady,
    required this.servicesCount,
    required this.packagesCount,
    required this.faqCount,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final items = [
      _PlannerItem(
        title: 'Promessa clara',
        detail:
            slogan.isNotEmpty
                ? slogan
                : 'Defina uma frase curta que diga o resultado que voce entrega.',
        done: slogan.isNotEmpty,
        icon: Icons.campaign_outlined,
      ),
      _PlannerItem(
        title: 'Foto real de autoridade',
        detail:
            heroPhotoReady
                ? 'Foto principal pronta para a primeira dobra.'
                : 'Suba uma foto sua, do estudio ou de um atendimento real.',
        done: heroPhotoReady,
        icon: Icons.photo_camera_back_outlined,
      ),
      _PlannerItem(
        title: 'Foto pessoal da bio',
        detail:
            bioPhotoReady
                ? 'Retrato conectado a secao Sobre.'
                : 'Suba um retrato separado para nao repetir a capa.',
        done: bioPhotoReady,
        icon: Icons.person_pin_outlined,
      ),
      _PlannerItem(
        title: 'Video de apresentacao',
        detail:
            videoReady
                ? 'Player conectado ao hero da landing.'
                : 'Grave 30 a 90 segundos explicando para quem e seu metodo.',
        done: videoReady,
        icon: Icons.play_circle_outline,
      ),
      _PlannerItem(
        title: 'Oferta comparavel',
        detail:
            '$servicesCount servicos, $packagesCount planos e $faqCount FAQs.',
        done: servicesCount >= 2 && packagesCount >= 1 && faqCount >= 2,
        icon: Icons.sell_outlined,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primary, secondary]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Direcao premium da landing',
                      style: TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      specialty.isNotEmpty
                          ? 'Posicionamento: ${specialty.split(',').first.trim()}'
                          : 'Escolha um nicho principal para a pagina nao ficar generica.',
                      style: TextStyle(color: mute, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                items
                    .map(
                      (item) => SizedBox(
                        width: 150,
                        child: _PlannerTile(
                          item: item,
                          primary: primary,
                          isDark: isDark,
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          Text(
            'Base de design: foto real + contraste forte + prova visivel + oferta clara. Isso deixa cada personal diferente sem depender de gerador externo.',
            style: TextStyle(color: mute, fontSize: 12.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _PlannerItem {
  final String title;
  final String detail;
  final bool done;
  final IconData icon;

  const _PlannerItem({
    required this.title,
    required this.detail,
    required this.done,
    required this.icon,
  });
}

class _PlannerTile extends StatelessWidget {
  final _PlannerItem item;
  final Color primary;
  final bool isDark;

  const _PlannerTile({
    required this.item,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    final color = item.done ? const Color(0xFF22C55E) : primary;
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                item.done ? Icons.check_circle : item.icon,
                color: color,
                size: 18,
              ),
              const Spacer(),
              Text(
                item.done ? 'OK' : 'FALTA',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 9.5,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: TextStyle(color: ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            item.detail,
            style: TextStyle(color: mute, fontSize: 11.5, height: 1.35),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PremiumLandingPreviewCard extends StatelessWidget {
  final Color primary;
  final Color secondary;
  final String? logoUrl;
  final String heroPhotoUrl;
  final String name;
  final String slogan;
  final String specialty;

  const _PremiumLandingPreviewCard({
    required this.primary,
    required this.secondary,
    required this.logoUrl,
    required this.heroPhotoUrl,
    required this.name,
    required this.slogan,
    required this.specialty,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeroPhoto = heroPhotoUrl.trim().isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasHeroPhoto)
              Image.network(
                heroPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => _PremiumHeroPreviewCanvas(
                      primary: primary,
                      secondary: secondary,
                    ),
              )
            else
              _PremiumHeroPreviewCanvas(primary: primary, secondary: secondary),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF050814).withValues(alpha: 0.20),
                    const Color(0xFF050814).withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              top: 18,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    backgroundImage:
                        logoUrl != null && logoUrl!.isNotEmpty
                            ? NetworkImage(logoUrl!)
                            : null,
                    child:
                        logoUrl == null || logoUrl!.isEmpty
                            ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'P',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'QUERO TREINAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    specialty.isNotEmpty
                        ? specialty.split(',').first.trim().toUpperCase()
                        : 'PERSONAL TRAINER',
                    style: TextStyle(
                      color: primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slogan.isNotEmpty
                        ? slogan
                        : 'Treino com metodo, presenca e resultado.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PreviewPill(
                        label: hasHeroPhoto ? 'Foto real' : 'Assinatura visual',
                      ),
                      const _PreviewPill(label: 'Video no hero'),
                      const _PreviewPill(label: 'Servicos e valores'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPill extends StatelessWidget {
  final String label;

  const _PreviewPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LandingMediaStatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
  final bool isDark;
  final bool showUrl;

  const _LandingMediaStatusCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.isDark,
    this.showUrl = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: mute, fontSize: 12, height: 1.3),
                ),
                if (showUrl) ...[
                  const SizedBox(height: 6),
                  SelectableText(
                    url,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingEditorCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool isDark;

  const _LandingEditorCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color>? onSelect;
  const _ColorPicker({required this.selected, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _coresPredefinidas.map((c) {
            final isSelected = c.toARGB32() == selected.toARGB32();
            return GestureDetector(
              onTap: onSelect != null ? () => onSelect!(c) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border:
                      isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ]
                          : null,
                ),
                child:
                    isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
              ),
            );
          }).toList(),
    );
  }
}

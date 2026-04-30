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
  final _heroPromptCtrl = TextEditingController();
  final _heroImageCtrl = TextEditingController();
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
  bool _applyingHeroImage = false;
  bool _perfilLoaded = false;
  bool _hydratingPerfil = false;
  final bool _showManualVideoUrl = false;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _heroPromptCtrl.addListener(_onHeroPromptChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(perfilProvider);
    });
  }

  void _onHeroPromptChanged() {
    if (_hydratingPerfil) return;
    if (mounted) setState(() {});
  }

  void _applyPerfil(PerfilPersonal perfil) {
    _hydratingPerfil = true;
    _descCtrl.text = perfil.descricaoProfissional ?? '';
    _espCtrl.text = perfil.especialidades ?? '';
    _instaCtrl.text = perfil.instagram ?? '';
    _sloganCtrl.text = perfil.slogan ?? '';
    _domCtrl.text = perfil.dominioCustomizado ?? '';
    _videoCtrl.text = perfil.videoUrl ?? '';
    _trackingCtrl.text = perfil.trackingId ?? '';
    _heroPromptCtrl.text = perfil.heroPrompt ?? '';
    _heroImageCtrl.text = perfil.heroImageUrl ?? '';
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
    _hydratingPerfil = false;
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

  @override
  void dispose() {
    _heroPromptCtrl.removeListener(_onHeroPromptChanged);
    _descCtrl.dispose();
    _espCtrl.dispose();
    _instaCtrl.dispose();
    _sloganCtrl.dispose();
    _domCtrl.dispose();
    _videoCtrl.dispose();
    _trackingCtrl.dispose();
    _heroPromptCtrl.dispose();
    _heroImageCtrl.dispose();
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
        body['heroPrompt'] = _heroPromptCtrl.text.trim();
        body['heroImageUrl'] =
            typedHeroUrl.isEmpty || _isAiGeneratedHeroUrl(typedHeroUrl)
                ? ''
                : typedHeroUrl;
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

  Future<void> _applyHeroAsBackground(String plano, String url) async {
    if (_applyingHeroImage) return;
    setState(() {
      _applyingHeroImage = true;
      _heroImageCtrl.clear();
    });
    try {
      await _salvar(
        plano,
        successMessage: 'Imagem IA aplicada como fundo da landing.',
      );
    } finally {
      if (mounted) setState(() => _applyingHeroImage = false);
    }
  }

  String _buildGeneratedHeroUrl({PerfilPersonal? perfil}) {
    final prompt = _buildGeneratedHeroPrompt(perfil);
    if (prompt.isEmpty) return '';
    final encoded = Uri.encodeComponent(prompt);
    final slugOrId =
        perfil?.slug ?? perfil?.id.toString() ?? _currentPerfilSeedSource;
    final seed = _stablePositiveSeed(slugOrId);
    return 'https://image.pollinations.ai/prompt/$encoded'
        '?width=1600&height=1000&model=flux&nologo=true&seed=$seed';
  }

  String get _currentPerfilSeedSource {
    final perfil = ref.read(perfilProvider).value;
    return perfil?.slug ?? perfil?.id.toString() ?? 'focux-landing';
  }

  String _buildGeneratedHeroPrompt(PerfilPersonal? perfil) {
    final brief = _heroPromptCtrl.text.trim();
    final nome =
        (perfil?.nome ?? '').trim().isNotEmpty
            ? perfil!.nome.trim()
            : 'personal trainer';
    final especialidades =
        _espCtrl.text.trim().isNotEmpty
            ? _espCtrl.text.trim()
            : (perfil?.especialidades ?? perfil?.especialidade ?? '').trim();
    final primary =
        '#${_corPrimaria.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    final secondary =
        '#${_corSecundaria.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    final base =
        brief.isNotEmpty
            ? brief
            : 'personal trainer premium, treino personalizado, visual sofisticado';
    return '$base, landing page premium para $nome, '
        '${especialidades.isEmpty ? 'fitness transformation' : especialidades}, '
        'realistic cinematic fitness photography, elegant mobile first hero background, '
        'deep contrast, premium studio lighting, brand colors $primary and $secondary, '
        'clear space for headline, no text, no logo, no watermark';
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

  int _stablePositiveSeed(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash == 0 ? 1015133771 : hash;
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
    final generatedHeroUrl = perfil?.generatedHeroImageUrl?.trim();
    final heroStatus = perfil?.heroImageStatus?.trim();
    final heroBrief = perfil?.heroImageBrief?.trim();
    final draftGeneratedHeroUrl = _buildGeneratedHeroUrl(perfil: perfil);
    final typedHeroUrl = _heroImageCtrl.text.trim();
    final previewHeroUrl =
        typedHeroUrl.isEmpty || _isAiGeneratedHeroUrl(typedHeroUrl)
            ? draftGeneratedHeroUrl
            : typedHeroUrl;
    final hasUnsavedHeroBrief =
        (_heroPromptCtrl.text.trim()) != (perfil?.heroPrompt ?? '').trim();

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
                'Use a imagem IA como fundo da primeira dobra: ela precisa combinar com sua cor, nicho e tom de venda.',
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
                      title: 'Imagem IA unica da landing',
                      subtitle:
                          'Descreva o estilo da primeira tela. A IA cria uma imagem premium para virar fundo principal da landing.',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _heroPromptCtrl,
                            enabled: isEnterprise,
                            maxLines: 3,
                            maxLength: 500,
                            decoration: const InputDecoration(
                              labelText: 'Briefing para IA',
                              hintText:
                                  'Ex: personal feminino em estudio premium, luz natural, treino funcional, tom sofisticado.',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (previewHeroUrl.isNotEmpty) ...[
                            _GeneratedHeroAssetCard(
                              isDark: isDark,
                              url: previewHeroUrl,
                              status:
                                  hasUnsavedHeroBrief
                                      ? 'PREVIEW'
                                      : (heroStatus ?? 'PREVIEW'),
                              brief:
                                  hasUnsavedHeroBrief
                                      ? _heroPromptCtrl.text.trim()
                                      : (heroBrief ??
                                          _heroPromptCtrl.text.trim()),
                              applying: _applyingHeroImage || _salvando,
                              onUseAsBackground:
                                  isEnterprise
                                      ? () => _applyHeroAsBackground(
                                        plano,
                                        previewHeroUrl,
                                      )
                                      : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _heroImageCtrl,
                            enabled: isEnterprise,
                            decoration: const InputDecoration(
                              labelText: 'URL manual de imagem',
                              hintText: 'https://cdn.focux.app/landing/...',
                              helperText:
                                  'Opcional: use apenas se quiser substituir a IA por uma imagem propria.',
                              helperMaxLines: 2,
                            ),
                          ),
                          if (generatedHeroUrl != null &&
                              generatedHeroUrl.isNotEmpty &&
                              generatedHeroUrl != previewHeroUrl) ...[
                            const SizedBox(height: 8),
                            _LandingMediaStatusCard(
                              isDark: isDark,
                              icon: Icons.history,
                              title: 'Imagem IA salva anteriormente',
                              subtitle:
                                  'Voce mudou o briefing. Aplique a nova imagem para atualizar a landing.',
                              url: generatedHeroUrl,
                            ),
                          ],
                          const SizedBox(height: 12),
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
                    const SizedBox(height: 20),

                    // Preview
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_corPrimaria, _corSecundaria],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.3,
                            ),
                            backgroundImage:
                                _logoUrl != null
                                    ? NetworkImage(_logoUrl!)
                                    : null,
                            child:
                                _logoUrl == null
                                    ? Text(
                                      nomePersonal.isNotEmpty
                                          ? nomePersonal[0].toUpperCase()
                                          : 'P',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nomePersonal,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                if (_sloganCtrl.text.isNotEmpty)
                                  Text(
                                    _sloganCtrl.text,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

class _GeneratedHeroAssetCard extends StatelessWidget {
  final String url;
  final String? status;
  final String? brief;
  final bool applying;
  final VoidCallback? onUseAsBackground;
  final bool isDark;

  const _GeneratedHeroAssetCard({
    required this.url,
    required this.status,
    required this.brief,
    required this.applying,
    required this.onUseAsBackground,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final ink = isDark ? EagleTokens.darkInk : EagleTokens.ink;
    final mute = isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCardHi : EagleTokens.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    url,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder:
                        (_, __, ___) => Container(
                          color: primary.withValues(alpha: 0.10),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: primary,
                          ),
                        ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.42),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    bottom: 10,
                    child: Text(
                      'Preview do fundo principal',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.image_outlined, color: primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Imagem IA gerada',
                  style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
              if (status != null && status!.isNotEmpty)
                Text(
                  status!,
                  style: TextStyle(
                    color: mute,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (brief != null && brief!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              brief!,
              style: TextStyle(color: mute, fontSize: 12.5, height: 1.35),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          SelectableText(
            url,
            style: TextStyle(
              color: primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL da imagem copiada.')),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copiar link'),
              ),
              FilledButton.icon(
                onPressed: applying ? null : onUseAsBackground,
                icon:
                    applying
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.wallpaper_outlined, size: 16),
                label: Text(
                  applying ? 'Aplicando...' : 'Aplicar como fundo premium',
                ),
              ),
            ],
          ),
        ],
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

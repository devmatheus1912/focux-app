import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../features/auth/providers/auth_provider.dart';
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
  Color _corPrimaria = const Color(0xFF3B5FE2);
  Color _corSecundaria = const Color(0xFF0097A7);
  bool _salvando = false;
  bool _uploadingLogo = false;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(perfilProvider);
      final perfil = ref.read(perfilProvider).value;
      if (perfil != null) {
        _descCtrl.text = perfil.descricaoProfissional ?? '';
        _espCtrl.text = perfil.especialidades ?? '';
        _instaCtrl.text = perfil.instagram ?? '';
        _sloganCtrl.text = perfil.slogan ?? '';
        _domCtrl.text = perfil.dominioCustomizado ?? '';
        _videoCtrl.text = perfil.videoUrl ?? '';
        _logoUrl = perfil.logoUrl;
        if (perfil.corPrimaria != null && perfil.corPrimaria!.length == 7) {
          final hex =
              int.tryParse(perfil.corPrimaria!.replaceFirst('#', '0xFF'));
          if (hex != null) setState(() => _corPrimaria = Color(hex));
        }
        if (perfil.corSecundaria != null && perfil.corSecundaria!.length == 7) {
          final hex =
              int.tryParse(perfil.corSecundaria!.replaceFirst('#', '0xFF'));
          if (hex != null) setState(() => _corSecundaria = Color(hex));
        }
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _espCtrl.dispose();
    _instaCtrl.dispose();
    _sloganCtrl.dispose();
    _domCtrl.dispose();
    _videoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 800);
    if (file == null || !mounted) return;
    setState(() => _uploadingLogo = true);
    try {
      final url = await MediaUploadService(ref.read(apiClientProvider))
          .uploadBytes(
            bytes: await file.readAsBytes(),
            filename: file.name,
            folder: 'identidade',
            resourceType: 'image',
          );
      if (mounted) setState(() => _logoUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _salvar(String plano) async {
    if (plano.toUpperCase() == 'FREE') return;
    setState(() => _salvando = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final body = <String, dynamic>{
        'descricaoProfissional': _descCtrl.text.trim(),
        'especialidades': _espCtrl.text.trim(),
        'instagram': _instaCtrl.text.trim(),
      };
      if (plano.toUpperCase() == 'ENTERPRISE') {
        body['corPrimaria'] =
            '#${_corPrimaria.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
        body['corSecundaria'] =
            '#${_corSecundaria.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
        body['slogan'] = _sloganCtrl.text.trim();
        if (_logoUrl != null) body['logoUrl'] = _logoUrl;
        if (_domCtrl.text.trim().isNotEmpty) body['dominioCustomizado'] = _domCtrl.text.trim();
        if (_videoCtrl.text.trim().isNotEmpty) body['videoUrl'] = _videoCtrl.text.trim();
      }
      await dio.put('/api/personal/identidade', data: body);
      ref.invalidate(perfilProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identidade visual salva!')),
        );
        if (widget.isSetup) context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plano = perfilAsync.value?.plano ?? 'FREE';
    final isEnterprise = plano.toUpperCase() == 'ENTERPRISE';
    final isPremiumOrAbove = ['PREMIUM', 'ENTERPRISE'].contains(plano.toUpperCase());

    final slug = perfilAsync.value?.slug;
    final nomePersonal = perfilAsync.value?.nome ?? '';

    return Scaffold(
      backgroundColor: isDark ? EagleTokens.darkBg : EagleTokens.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            widget.isSetup ? 'Configurar meu app' : 'Identidade Visual'),
        automaticallyImplyLeading: !widget.isSetup,
        leading: widget.isSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard/personal');
                  }
                },
              ),
        actions: [
          if (isPremiumOrAbove)
            TextButton(
              onPressed: _salvando ? null : () => _salvar(plano),
              child: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Salvar',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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

            // Slug display
            if (slug != null && isPremiumOrAbove) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark ? EagleTokens.darkCard : EagleTokens.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDark
                          ? EagleTokens.darkLine
                          : EagleTokens.lineSoft),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link,
                        size: 16,
                        color: isDark
                            ? EagleTokens.darkInkMute
                            : EagleTokens.inkMute),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'focux.app/p/$slug',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? EagleTokens.darkInk
                              : EagleTokens.ink,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text: 'https://focux.app/p/$slug'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Link copiado!')),
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
                        hintText:
                            'Descreva sua trajetória e metodologia...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _espCtrl,
                      enabled: isPremiumOrAbove,
                      decoration: const InputDecoration(
                        labelText: 'Especialidades',
                        hintText:
                            'Ex: Musculação, Funcional, Emagrecimento',
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
                            backgroundColor: isDark
                                ? EagleTokens.darkCard
                                : EagleTokens.brandSoft,
                            backgroundImage: _logoUrl != null
                                ? NetworkImage(_logoUrl!)
                                : null,
                            child: _logoUrl == null
                                ? Text(
                                    nomePersonal.isNotEmpty
                                        ? nomePersonal[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? EagleTokens.darkInk
                                          : EagleTokens.brand,
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
                                color: EagleTokens.brand,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: isDark
                                        ? EagleTokens.darkBg
                                        : EagleTokens.paper,
                                    width: 2),
                              ),
                              child: _uploadingLogo
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Icon(Icons.camera_alt,
                                      size: 14, color: Colors.white),
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
                    Text('Cor principal',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _ColorPicker(
                      selected: _corPrimaria,
                      onSelect: isEnterprise
                          ? (c) => setState(() => _corPrimaria = c)
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Cor secundária
                    Text('Cor secundária',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    _ColorPicker(
                      selected: _corSecundaria,
                      onSelect: isEnterprise
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
                        helperText: 'Configure um CNAME apontando para focux.app',
                        helperMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _videoCtrl,
                      enabled: isEnterprise,
                      decoration: const InputDecoration(
                        labelText: 'URL do vídeo de apresentação',
                        hintText: 'https://youtube.com/watch?v=...',
                        helperText: 'Aparece na sua landing page. YouTube, Vimeo ou qualquer link.',
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
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.3),
                            backgroundImage: _logoUrl != null
                                ? NetworkImage(_logoUrl!)
                                : null,
                            child: _logoUrl == null
                                ? Text(
                                    nomePersonal.isNotEmpty
                                        ? nomePersonal[0].toUpperCase()
                                        : 'P',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(nomePersonal,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                                if (_sloganCtrl.text.isNotEmpty)
                                  Text(
                                    _sloganCtrl.text,
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.75),
                                        fontSize: 12),
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
                  style: isEnterprise
                      ? FilledButton.styleFrom(
                          backgroundColor: _corPrimaria)
                      : null,
                  child: _salvando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))
                      : Text(widget.isSetup
                          ? 'Finalizar configuração'
                          : 'Salvar'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: EagleTokens.brand.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: EagleTokens.brand, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark
                  ? EagleTokens.darkInkMute
                  : EagleTokens.inkMute,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onTap,
              child: Text(buttonText),
            ),
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

class _ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color>? onSelect;
  const _ColorPicker({required this.selected, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _coresPredefinidas.map((c) {
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
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: c.withValues(alpha: 0.6), blurRadius: 8)
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

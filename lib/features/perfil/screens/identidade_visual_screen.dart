import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';

class IdentidadeVisualScreen extends ConsumerStatefulWidget {
  const IdentidadeVisualScreen({super.key, this.isSetup = false});

  final bool isSetup;

  @override
  ConsumerState<IdentidadeVisualScreen> createState() =>
      _IdentidadeVisualScreenState();
}

class _IdentidadeVisualScreenState extends ConsumerState<IdentidadeVisualScreen> {
  final _descCtrl = TextEditingController();
  final _espCtrl = TextEditingController();
  final _instaCtrl = TextEditingController();
  final _sloganCtrl = TextEditingController();
  final _domCtrl = TextEditingController();

  late CuratedBrandPalette _palette = CuratedBrandPalette.focuxDefault;
  bool _salvando = false;
  bool _uploadingLogo = false;
  bool _perfilLoaded = false;
  String? _logoUrl;

  Color get _corPrimaria => _palette.primary;
  Color get _corSecundaria => _palette.secondary;

  @override
  void initState() {
    super.initState();
    _sloganCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(perfilProvider);
    });
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _espCtrl.dispose();
    _instaCtrl.dispose();
    _sloganCtrl.dispose();
    _domCtrl.dispose();
    super.dispose();
  }

  void _applyPerfil(PerfilPersonal perfil) {
    _descCtrl.text = perfil.descricaoProfissional ?? '';
    _espCtrl.text = perfil.especialidades ?? '';
    _instaCtrl.text = perfil.instagram ?? '';
    _sloganCtrl.text = perfil.slogan ?? '';
    _domCtrl.text = perfil.dominioCustomizado ?? '';
    _logoUrl = perfil.logoUrl;

    var primary = BrandPalette.defaultPrimary;
    var secondary = BrandPalette.defaultSecondary;
    if (perfil.corPrimaria != null && perfil.corPrimaria!.length == 7) {
      final hex = int.tryParse(perfil.corPrimaria!.replaceFirst('#', '0xFF'));
      if (hex != null) primary = Color(hex);
    }
    if (perfil.corSecundaria != null && perfil.corSecundaria!.length == 7) {
      final hex = int.tryParse(perfil.corSecundaria!.replaceFirst('#', '0xFF'));
      if (hex != null) secondary = Color(hex);
    }

    primary = CuratedBrandPalette.safePrimary(primary);
    secondary = CuratedBrandPalette.safeSecondaryFor(primary, secondary);
    _palette = CuratedBrandPalette.resolve(primary, secondary);
    _perfilLoaded = true;
  }

  Future<void> _pickLogo() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1024,
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
        FeedbackHelper.showSuccess(context, 'Erro upload: $e');
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _restoreDefaultBrandColors(String plano) async {
    if (plano.toUpperCase() != 'ENTERPRISE') return;
    setState(() => _palette = CuratedBrandPalette.focuxDefault);
    await _salvar(
      plano,
      successMessage: 'Cores padrão do Focux restauradas!',
    );
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
      };
      if (plano.toUpperCase() == 'ENTERPRISE') {
        body['corPrimaria'] = BrandPalette.toHex(_corPrimaria);
        body['corSecundaria'] = BrandPalette.toHex(_corSecundaria);
        body['slogan'] = _sloganCtrl.text.trim();
        if (_logoUrl != null) body['logoUrl'] = _logoUrl;
        if (_domCtrl.text.trim().isNotEmpty) {
          body['dominioCustomizado'] = _domCtrl.text.trim();
        }
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
        FeedbackHelper.showSnackBar(
          context,
          SnackBar(content: Text(successMessage)),
        );
        if (widget.isSetup) context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Erro: $e');
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final perfil = perfilAsync.value;
    if (perfil != null && !_perfilLoaded) {
      _applyPerfil(perfil);
    }

    final chrome = ShellChrome.of(context);
    final plano = perfil?.plano ?? 'FREE';
    final isEnterprise = plano.toUpperCase() == 'ENTERPRISE';
    final isPremiumOrAbove =
        ['PREMIUM', 'ENTERPRISE'].contains(plano.toUpperCase());
    final nomePersonal = perfil?.nome ?? '';

    return FxShellScaffold(
      useMesh: true,
      appBar: FxShellAppBar(
        title: widget.isSetup ? 'Configurar meu app' : 'Identidade Visual',
        subtitle: isEnterprise ? 'White-label premium' : 'Marca no app',
        onBack:
            widget.isSetup
                ? null
                : () => safePopOrGo(context, '/dashboard/personal'),
        leading:
            widget.isSetup
                ? const SizedBox(width: 8)
                : null,
      ),
      bottomNavigationBar:
          isPremiumOrAbove
              ? _SaveBar(
                salvando: _salvando,
                primary: isEnterprise ? _corPrimaria : null,
                secondary: isEnterprise ? _corSecundaria : null,
                label:
                    widget.isSetup ? 'Finalizar configuração' : 'Salvar marca',
                onPressed: () => _salvar(plano),
              )
              : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!isPremiumOrAbove) ...[
                  _PaywallCard(
                    onTap: () => context.go('/assinatura'),
                    chrome: chrome,
                  ),
                  const SizedBox(height: 18),
                ],
                AbsorbPointer(
                  absorbing: !isPremiumOrAbove,
                  child: Opacity(
                    opacity: isPremiumOrAbove ? 1 : 0.38,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LiveBrandHero(
                          primary: _corPrimaria,
                          secondary: _corSecundaria,
                          name: nomePersonal,
                          slogan: _sloganCtrl.text.trim(),
                          logoUrl: _logoUrl,
                          paletteName: _palette.name,
                        ),
                        const SizedBox(height: 16),
                        ShellSurface(
                          accent: _corPrimaria,
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PanelTitle(
                                icon: Icons.auto_awesome_outlined,
                                title: 'Logo e slogan',
                                subtitle:
                                    'Aparece no app, login e áreas do aluno.',
                                accent: _corPrimaria,
                                mute: chrome.mute,
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: _LogoUploadRing(
                                  nome: nomePersonal,
                                  logoUrl: _logoUrl,
                                  primary: _corPrimaria,
                                  secondary: _corSecundaria,
                                  uploading: _uploadingLogo,
                                  onTap: isEnterprise ? _pickLogo : null,
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _sloganCtrl,
                                enabled: isEnterprise,
                                maxLength: 200,
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                decoration: FxInputDeco.build(
                                  context,
                                  'Slogan',
                                  icon: Icons.format_quote_outlined,
                                  hint: 'Transformando vidas através do movimento',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        ShellSurface(
                          accent: _corPrimaria,
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PanelTitle(
                                icon: Icons.palette_outlined,
                                title: 'Paleta premium',
                                subtitle:
                                    'Pares curados com contraste seguro — nunca quebra o app.',
                                accent: _corPrimaria,
                                mute: chrome.mute,
                              ),
                              const SizedBox(height: 14),
                              _CuratedPaletteGrid(
                                selected: _palette,
                                onSelect:
                                    isEnterprise
                                        ? (p) {
                                          HapticFeedback.selectionClick();
                                          setState(() => _palette = p);
                                        }
                                        : null,
                              ),
                              if (isEnterprise) ...[
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed:
                                        () => _restoreDefaultBrandColors(plano),
                                    icon: Icon(
                                      Icons.restore_rounded,
                                      size: 18,
                                      color: _corPrimaria,
                                    ),
                                    label: Text(
                                      'Restaurar cores padrão do Focux',
                                      style: TextStyle(
                                        color: _corPrimaria,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isEnterprise) ...[
                          const SizedBox(height: 14),
                          ShellSurface(
                            padding: const EdgeInsets.all(18),
                            child: TextFormField(
                              controller: _domCtrl,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              decoration: FxInputDeco.build(
                                context,
                                'Domínio customizado',
                                icon: Icons.language_outlined,
                                hint: 'app.seudominio.com.br',
                              ).copyWith(
                                helperText: 'Opcional — white-label avançado',
                                helperMaxLines: 2,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        ShellSurface(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PanelTitle(
                                icon: Icons.badge_outlined,
                                title: 'Perfil profissional',
                                subtitle:
                                    'Bio e canais usados no app e convites.',
                                accent: _corPrimaria,
                                mute: chrome.mute,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _descCtrl,
                                enabled: isPremiumOrAbove,
                                maxLines: 3,
                                maxLength: 500,
                                style: GoogleFonts.outfit(fontSize: 14),
                                decoration: FxInputDeco.build(
                                  context,
                                  'Descrição profissional',
                                  hint: 'Trajetória, metodologia, diferencial...',
                                ).copyWith(alignLabelWithHint: true),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _espCtrl,
                                enabled: isPremiumOrAbove,
                                style: GoogleFonts.outfit(fontSize: 14),
                                decoration: FxInputDeco.build(
                                  context,
                                  'Especialidades',
                                  icon: Icons.fitness_center_outlined,
                                  hint: 'Musculação, Funcional...',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _instaCtrl,
                                enabled: isPremiumOrAbove,
                                style: GoogleFonts.outfit(fontSize: 14),
                                decoration: FxInputDeco.build(
                                  context,
                                  'Instagram',
                                  icon: Icons.alternate_email,
                                  hint: 'seuperfil',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBrandHero extends StatelessWidget {
  const _LiveBrandHero({
    required this.primary,
    required this.secondary,
    required this.name,
    required this.slogan,
    required this.logoUrl,
    required this.paletteName,
  });

  final Color primary;
  final Color secondary;
  final String name;
  final String slogan;
  final String? logoUrl;
  final String paletteName;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandPalette.deep(primary),
            primary,
            BrandPalette.softened(secondary, amount: 0.12),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.32),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondary.withValues(alpha: 0.22),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF6FE296),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Preview ao vivo · $paletteName',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      backgroundImage:
                          logoUrl != null && logoUrl!.isNotEmpty
                              ? NetworkImage(logoUrl!)
                              : null,
                      child:
                          logoUrl == null || logoUrl!.isEmpty
                              ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'P',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              )
                              : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : 'Seu app Focux',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              letterSpacing: -0.5,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            slogan.isNotEmpty
                                ? slogan
                                : 'Slogan aparece aqui em tempo real',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 12.5,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoUploadRing extends StatelessWidget {
  const _LogoUploadRing({
    required this.nome,
    required this.logoUrl,
    required this.primary,
    required this.secondary,
    required this.uploading,
    this.onTap,
  });

  final String nome;
  final String? logoUrl;
  final Color primary;
  final Color secondary;
  final bool uploading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [primary, secondary, primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.28),
                  blurRadius: 22,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ShellChrome.of(context).cardFill,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child:
                logoUrl != null && logoUrl!.isNotEmpty
                    ? Image.network(logoUrl!, fit: BoxFit.cover)
                    : Center(
                      child: Text(
                        nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                    ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child:
                  uploading
                      ? const Padding(
                        padding: EdgeInsets.all(7),
                        child: FxLoading(strokeWidth: 2, color: Colors.white),
                      )
                      : const Icon(
                        Icons.photo_camera_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CuratedPaletteGrid extends StatelessWidget {
  const _CuratedPaletteGrid({
    required this.selected,
    this.onSelect,
  });

  final CuratedBrandPalette selected;
  final ValueChanged<CuratedBrandPalette>? onSelect;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.05,
      ),
      itemCount: CuratedBrandPalette.premium.length,
      itemBuilder: (context, index) {
        final palette = CuratedBrandPalette.premium[index];
        final isSelected = palette.id == selected.id;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSelect == null ? null : () => onSelect!(palette),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: chrome.cardFill,
                border: Border.all(
                  color:
                      isSelected
                          ? palette.primary
                          : chrome.line.withValues(alpha: 0.9),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: palette.primary.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ]
                        : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  BrandPalette.deep(palette.primary),
                                  palette.primary,
                                  palette.secondary,
                                ],
                                stops: const [0.0, 0.42, 1.0],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.14),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.08),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Align(
                              alignment: Alignment.topRight,
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: palette.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    palette.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: chrome.ink,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    palette.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      color: chrome.mute,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.mute,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.3,
                  color: ShellChrome.of(context).ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: mute,
                  fontSize: 11.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.salvando,
    required this.label,
    required this.onPressed,
    this.primary,
    this.secondary,
  });

  final bool salvando;
  final String label;
  final VoidCallback onPressed;
  final Color? primary;
  final Color? secondary;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final accent = primary ?? Theme.of(context).colorScheme.primary;
    final accentDeep = BrandPalette.deep(accent);
    final accentEnd = secondary ?? BrandPalette.softened(accent, amount: 0.06);
    final onAccent = CuratedBrandPalette.readableOn(accent);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: BoxDecoration(
        color: chrome.sheetFill.withValues(alpha: 0.94),
        border: Border(top: BorderSide(color: chrome.line)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [accentDeep, accent, accentEnd],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: salvando ? null : onPressed,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child:
                      salvando
                          ? SizedBox(
                            height: 22,
                            width: 22,
                            child: FxLoading(
                              strokeWidth: 2,
                              color: onAccent,
                            ),
                          )
                          : Text(
                            label,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: -0.2,
                              color: onAccent,
                            ),
                          ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaywallCard extends StatelessWidget {
  const _PaywallCard({
    required this.onTap,
    required this.chrome,
  });

  final VoidCallback onTap;
  final ShellPalette chrome;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ShellSurface(
      accent: primary,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Recurso Premium',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: chrome.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Logo, slogan e paletas curadas para deixar seu app com cara de marca premium.',
            style: TextStyle(
              color: chrome.mute,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(onPressed: onTap, child: const Text('Assinar Premium')),
        ],
      ),
    );
  }
}

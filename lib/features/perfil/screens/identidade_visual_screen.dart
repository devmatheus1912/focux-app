import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/feedback_helper.dart';
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final plano = perfil?.plano ?? 'FREE';
    final isEnterprise = plano.toUpperCase() == 'ENTERPRISE';
    final isPremiumOrAbove =
        ['PREMIUM', 'ENTERPRISE'].contains(plano.toUpperCase());
    final themePrimary = Theme.of(context).colorScheme.primary;
    final themePrimarySoft = BrandPalette.soft(themePrimary, dark: isDark);
    final nomePersonal = perfil?.nome ?? '';

    return Scaffold(
      backgroundColor: Colors.transparent,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isPremiumOrAbove) ...[
              _PaywallCard(
                title: 'Recurso Premium',
                subtitle:
                    'Personalize logo, slogan e paleta premium do seu app.',
                onTap: () => context.go('/assinatura'),
                isDark: isDark,
              ),
              const SizedBox(height: 24),
            ],

            _SectionHeader(text: 'Sua marca no app', isDark: isDark),
            const SizedBox(height: 8),
            Text(
              'Paleta curada para manter contraste, legibilidade e visual premium em todo o app.',
              style: TextStyle(
                color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            AbsorbPointer(
              absorbing: !isPremiumOrAbove,
              child: Opacity(
                opacity: isPremiumOrAbove ? 1 : 0.35,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor:
                                isDark
                                    ? EagleTokens.darkCard
                                    : themePrimarySoft,
                            backgroundImage:
                                _logoUrl != null ? NetworkImage(_logoUrl!) : null,
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
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: GestureDetector(
                              onTap: isEnterprise ? _pickLogo : null,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color:
                                      isEnterprise
                                          ? _corPrimaria
                                          : themePrimary,
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
                                          child: FxLoading(
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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _sloganCtrl,
                      enabled: isEnterprise,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Slogan',
                        hintText: 'Ex: Transformando vidas através do movimento',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Paleta premium',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cada opção combina cor principal e secundária com contraste seguro.',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? EagleTokens.darkInkMute
                                : EagleTokens.inkMute,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CuratedPaletteGrid(
                      selected: _palette,
                      enabled: isEnterprise,
                      onSelect:
                          isEnterprise
                              ? (palette) => setState(() => _palette = palette)
                              : null,
                    ),
                    if (isEnterprise) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _restoreDefaultBrandColors(plano),
                          icon: const Icon(Icons.restore_rounded, size: 18),
                          label: const Text('Restaurar cores padrão do Focux'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _BrandPreviewCard(
                      primary: _corPrimaria,
                      secondary: _corSecundaria,
                      name: nomePersonal,
                      slogan: _sloganCtrl.text.trim(),
                      logoUrl: _logoUrl,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _domCtrl,
                      enabled: isEnterprise,
                      decoration: const InputDecoration(
                        labelText: 'Domínio customizado',
                        hintText: 'Ex: app.seudominio.com.br',
                        helperText: 'Opcional — para white-label avançado',
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(text: 'Perfil profissional', isDark: isDark),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descCtrl,
                      enabled: isPremiumOrAbove,
                      maxLines: 2,
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
                            child: FxLoading(strokeWidth: 2),
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

class _CuratedPaletteGrid extends StatelessWidget {
  const _CuratedPaletteGrid({
    required this.selected,
    required this.enabled,
    this.onSelect,
  });

  final CuratedBrandPalette selected;
  final bool enabled;
  final ValueChanged<CuratedBrandPalette>? onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final line = isDark ? EagleTokens.darkLine : EagleTokens.lineSoft;

    return Column(
      children:
          CuratedBrandPalette.premium.map((palette) {
            final isSelected = palette.id == selected.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSelect == null ? null : () => onSelect!(palette),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? EagleTokens.darkCard : EagleTokens.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color:
                            isSelected
                                ? palette.primary
                                : line,
                        width: isSelected ? 1.6 : 1,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: palette.primary.withValues(alpha: 0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ]
                              : null,
                    ),
                    child: Row(
                      children: [
                        _PaletteSwatchPair(
                          primary: palette.primary,
                          secondary: palette.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                palette.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color:
                                      isDark
                                          ? EagleTokens.darkInk
                                          : EagleTokens.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                palette.subtitle,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color:
                                      isDark
                                          ? EagleTokens.darkInkMute
                                          : EagleTokens.inkMute,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: palette.primary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _PaletteSwatchPair extends StatelessWidget {
  const _PaletteSwatchPair({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 36,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Expanded(child: ColoredBox(color: primary)),
            Expanded(child: ColoredBox(color: secondary)),
          ],
        ),
      ),
    );
  }
}

class _BrandPreviewCard extends StatelessWidget {
  const _BrandPreviewCard({
    required this.primary,
    required this.secondary,
    required this.name,
    required this.slogan,
    required this.logoUrl,
  });

  final Color primary;
  final Color secondary;
  final String name;
  final String slogan;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primary, secondary],
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Seu app',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slogan.isNotEmpty ? slogan : 'Preview da sua marca',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 11.5,
                      height: 1.25,
                    ),
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

class _PaywallCard extends StatelessWidget {
  const _PaywallCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? EagleTokens.darkCard : EagleTokens.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline, color: primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: isDark ? EagleTokens.darkInk : EagleTokens.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onTap, child: const Text('Assinar Premium')),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.text, required this.isDark});

  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: isDark ? EagleTokens.darkInkMute : EagleTokens.inkMute,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/brand_slogan_display.dart';
import '../../subscription/utils/landing_editor_access.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

part 'identidade_visual_screen_widgets.part.dart';

class IdentidadeVisualScreen extends ConsumerStatefulWidget {
  const IdentidadeVisualScreen({super.key, this.isSetup = false});

  final bool isSetup;

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
    super.dispose();
  }

  void _applyPerfil(PerfilPersonal perfil) {
    _descCtrl.text = perfil.descricaoProfissional ?? '';
    _espCtrl.text = perfil.especialidades ?? '';
    _instaCtrl.text = perfil.instagram ?? '';
    _sloganCtrl.text = perfil.slogan ?? '';
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
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _restoreDefaultBrandColors(String plano) async {
    if (plano.toUpperCase() != 'ENTERPRISE') return;
    setState(() => _palette = CuratedBrandPalette.focuxDefault);
    await _salvar(plano, successMessage: 'Cores padrão do Focux restauradas!');
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
        FeedbackHelper.showInfo(context, successMessage);
        if (widget.isSetup) context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
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

    if (perfil == null) {
      return fxScreenA11yScope(
        label: 'Identidade Visual',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: widget.isSetup ? 'Configurar meu app' : 'Identidade Visual',
            onBack:
                widget.isSetup
                    ? null
                    : () => safePopOrGo(context, '/dashboard/personal'),
            leading: widget.isSetup ? const SizedBox(width: 8) : null,
          ),
          body:
              perfilAsync.hasError
                  ? FxErrorState(
                    chromeOnDark: ShellChrome.of(context).isDark,
                    primary: Theme.of(context).colorScheme.primary,
                    message: friendlyError(perfilAsync.error!),
                    onRetry: () => ref.invalidate(perfilProvider),
                  )
                  : const SkeletonList(count: 6),
        ),
      );
    }

    final chrome = ShellChrome.of(context);
    final plano = perfil.plano;
    final planUpper = plano.toUpperCase();
    final isEnterprise =
        planUpper == 'ENTERPRISE' || planUpper == 'ENTERPRISE_PRO';
    final isPremiumOrAbove = [
      'PREMIUM',
      'ENTERPRISE',
      'ENTERPRISE_PRO',
    ].contains(planUpper);
    final nomePersonal = perfil.nome;

    return fxScreenA11yScope(
      label: 'Identidade Visual',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: widget.isSetup ? 'Configurar meu app' : 'Identidade Visual',
          subtitle: isEnterprise ? 'Sua marca no app' : 'Marca no app',
          onBack:
              widget.isSetup
                  ? null
                  : () => safePopOrGo(context, '/dashboard/personal'),
          leading: widget.isSetup ? const SizedBox(width: 8) : null,
        ),
        bottomNavigationBar:
            isPremiumOrAbove
                ? _SaveBar(
                  salvando: _salvando,
                  label:
                      widget.isSetup
                          ? 'Finalizar configuração'
                          : 'Salvar marca',
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
                          const SizedBox(height: 12),
                          if (isEnterprise)
                            OutlinedButton.icon(
                              onPressed:
                                  () =>
                                      openLandingEditorOrUpgrade(context, ref),
                              icon: const Icon(Icons.language_outlined),
                              label: const Text(
                                'Editor da landing (Enterprise Pro)',
                              ),
                            ),
                          const SizedBox(height: TokensStrip.s4),
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
                                _BrandField(
                                  label: 'Slogan',
                                  controller: _sloganCtrl,
                                  enabled: isEnterprise,
                                  accent: _corPrimaria,
                                  icon: Icons.format_quote_outlined,
                                  hint:
                                      'Transformando vidas através do movimento',
                                  maxLength: 200,
                                  maxLines: 2,
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
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Material(
                                      color: fxTransparent,
                                      child: InkWell(
                                        onTap:
                                            () => _restoreDefaultBrandColors(
                                              plano,
                                            ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _corPrimaria.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: _corPrimaria.withValues(
                                                alpha: 0.18,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.restore_rounded,
                                                size: 16,
                                                color: _corPrimaria,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Restaurar cores padrão',
                                                style: FocuxHubTypography.chip(
                                                  _corPrimaria,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          ShellSurface(
                            accent: _corPrimaria,
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
                                const SizedBox(height: 18),
                                _BrandField(
                                  label: 'Descrição profissional',
                                  controller: _descCtrl,
                                  enabled: isPremiumOrAbove,
                                  accent: _corPrimaria,
                                  hint:
                                      'Trajetória, metodologia, diferencial...',
                                  maxLines: 4,
                                  maxLength: 500,
                                ),
                                const SizedBox(height: 14),
                                _BrandField(
                                  label: 'Especialidades',
                                  controller: _espCtrl,
                                  enabled: isPremiumOrAbove,
                                  accent: _corPrimaria,
                                  icon: Icons.fitness_center_outlined,
                                  hint:
                                      'Musculação, Funcional, Emagrecimento...',
                                ),
                                const SizedBox(height: 14),
                                _BrandField(
                                  label: 'Instagram',
                                  controller: _instaCtrl,
                                  enabled: isPremiumOrAbove,
                                  accent: _corPrimaria,
                                  icon: Icons.alternate_email,
                                  hint: '@seuperfil',
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
      ),
    );
  }
}

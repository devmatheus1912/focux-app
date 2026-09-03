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
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/brand_slogan_display.dart';
import '../utils/identidade_visual_display.dart';
import '../../subscription/utils/landing_editor_access.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';

part 'identidade_visual_screen_actions.part.dart';
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
    final hasWhiteLabel = identidadeHasWhiteLabel(
      featureWhiteLabel: ref.watch(planoFeaturesProvider).valueOrNull?.whiteLabel,
      plano: plano,
    );
    final nomePersonal = perfil.nome;

    return fxScreenA11yScope(
      label: 'Identidade Visual',
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: widget.isSetup ? 'Configurar meu app' : 'Identidade Visual',
          subtitle: hasWhiteLabel ? 'Sua marca no app' : 'Marca no app',
          onBack:
              widget.isSetup
                  ? null
                  : () => safePopOrGo(context, '/dashboard/personal'),
          leading: widget.isSetup ? const SizedBox(width: 8) : null,
          actions: [
            FxHelpIconButton(
              tooltip: identidadeHelpTitle(),
              onTap: () => _abrirIdentidadeAjuda(context),
            ),
            const SizedBox(width: TokensStrip.s2),
          ],
        ),
        bottomNavigationBar:
            hasWhiteLabel
                ? _SaveBar(
                  salvando: _salvando,
                  label: identidadeSalvarLabel(isSetup: widget.isSetup),
                  onPressed: () => _pedirSalvar(hasWhiteLabel: hasWhiteLabel),
                )
                : null,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                FxSettingsLayout.pageInset,
                4,
                FxSettingsLayout.pageInset,
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (!hasWhiteLabel) ...[
                    _PaywallCard(
                      onTap: () => context.go('/assinatura'),
                      chrome: chrome,
                    ),
                    const SizedBox(height: 18),
                  ],
                  AbsorbPointer(
                    absorbing: !hasWhiteLabel,
                    child: Opacity(
                      opacity: hasWhiteLabel ? 1 : 0.38,
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
                          if (hasWhiteLabel)
                            FxSettingsGroup(
                              children: [
                                FxSettingsTile(
                                  fxIcon: 'article',
                                  label: identidadeLandingEditorLabel(),
                                  value: 'Landing',
                                  showDivider: false,
                                  onTap:
                                      () => openLandingEditorOrUpgrade(
                                        context,
                                        ref,
                                      ),
                                ),
                              ],
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
                                    onTap:
                                        hasWhiteLabel ? _pedirTrocarLogo : null,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _BrandField(
                                  label: 'Slogan',
                                  controller: _sloganCtrl,
                                  enabled: hasWhiteLabel,
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
                                      hasWhiteLabel
                                          ? (p) {
                                            HapticFeedback.selectionClick();
                                            setState(() => _palette = p);
                                          }
                                          : null,
                                ),
                                if (hasWhiteLabel) ...[
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed:
                                        () => _pedirRestaurarCores(
                                          hasWhiteLabel: hasWhiteLabel,
                                        ),
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(
                                        FxSettingsLayout.rowMinHeight,
                                        FxSettingsLayout.rowMinHeight,
                                      ),
                                      alignment: Alignment.centerLeft,
                                    ),
                                    child: Text(
                                      identidadeRestaurarCoresLabel(),
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
                                  enabled: hasWhiteLabel,
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
                                  enabled: hasWhiteLabel,
                                  accent: _corPrimaria,
                                  icon: Icons.fitness_center_outlined,
                                  hint:
                                      'Musculação, Funcional, Emagrecimento...',
                                ),
                                const SizedBox(height: 14),
                                _BrandField(
                                  label: 'Instagram',
                                  controller: _instaCtrl,
                                  enabled: hasWhiteLabel,
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

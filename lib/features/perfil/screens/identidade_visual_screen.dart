import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/curated_brand_palettes.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../data/perfil_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/brand_slogan_display.dart';
import '../utils/identidade_visual_display.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_typography.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/skeleton_loader.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_screen_a11y.dart';
import '../../../core/theme/brand_style.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_choice_strip.dart';
import '../widgets/identidade_previa_app.dart';
import '../widgets/identidade_capa_tile.dart';
import '../widgets/identidade_paletas_grade.dart';

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
  final _sloganCtrl = TextEditingController();

  late CuratedBrandPalette _palette = CuratedBrandPalette.focuxDefault;
  bool _salvando = false;
  bool _uploadingLogo = false;
  bool _uploadingCapa = false;
  BrandStyle _estilo = BrandStyle.classico;
  String? _capaUrl;
  BrandStyle _baselineEstilo = BrandStyle.classico;
  String? _baselineCapa;
  int _previa = 0;
  bool _perfilLoaded = false;
  bool _viewTracked = false;
  DateTime? _fetchedAt;
  String? _logoUrl;
  String _baselineSlogan = '';
  String? _baselineLogo;
  CuratedBrandPalette? _baselinePalette;

  Color get _corPrimaria => _palette.primary;
  Color get _corSecundaria => _palette.secondary;

  @override
  void initState() {
    super.initState();
    _sloganCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _sloganCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  bool get _dirty => identidadeIsDirty(
    perfilLoaded: _perfilLoaded,
    slogan: _sloganCtrl.text,
    baselineSlogan: _baselineSlogan,
    logoUrl: _logoUrl,
    baselineLogo: _baselineLogo,
    palette: _palette,
    baselinePalette: _baselinePalette,
    estilo: _estilo,
    baselineEstilo: _baselineEstilo,
    capaUrl: _capaUrl,
    baselineCapa: _baselineCapa,
  );

  void _snapshotBaseline() {
    _baselineSlogan = _sloganCtrl.text;
    _baselineLogo = _logoUrl;
    _baselinePalette = _palette;
    _baselineEstilo = _estilo;
    _baselineCapa = _capaUrl;
  }

  Future<void> _pedirSair() async {
    FxKeyboardDismissScope.dismiss();
    if (_dirty) {
      final leave = await showFxConfirmSheet(
        context,
        title: identidadeDiscardTitle(),
        message: identidadeDiscardMessage(),
        confirmLabel: identidadeDiscardConfirm(),
      );
      if (!leave || !mounted) return;
    }
    safePopOrGo(context, '/perfil');
  }

  Future<void> _refresh() async {
    setState(() => _perfilLoaded = false);
    ref.invalidate(perfilProvider);
    unawaited(
      AnalyticsService.instance.track(ProductEvents.identidadeRefreshed),
    );
  }

  void _applyPerfil(PerfilPersonal perfil) {
    _sloganCtrl.text = perfil.slogan ?? '';
    _logoUrl = perfil.logoUrl;
    _estilo = BrandStyle.fromApi(perfil.estiloMarca);
    _capaUrl = perfil.capaUrl;

    // Cyan legado no perfil → Focux Original (azul petróleo), não slate teal.
    var primary = BrandPalette.resolveStoredPrimary(perfil.corPrimaria);
    var secondary = BrandPalette.resolveStoredSecondary(perfil.corSecundaria);

    primary = CuratedBrandPalette.safePrimary(primary);
    secondary = CuratedBrandPalette.safeSecondaryFor(primary, secondary);
    _palette = CuratedBrandPalette.resolve(primary, secondary);    _perfilLoaded = true;
    _fetchedAt = DateTime.now();
    _snapshotBaseline();
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final perfil = perfilAsync.value;
    if (perfil != null && !_perfilLoaded) {
      _applyPerfil(perfil);
    }

    if (perfil != null && !_viewTracked) {
      _viewTracked = true;
      unawaited(
        AnalyticsService.instance.track(
          ProductEvents.identidadeViewed,
          props: {'setup': widget.isSetup},
        ),
      );
    }

    if (perfil == null) {
      return fxScreenA11yScope(
        label: 'Identidade Visual',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: widget.isSetup ? 'Configurar meu app' : 'Identidade Visual',
            onBack: _pedirSair,
          ),
          body:
              perfilAsync.hasError
                  ? FxErrorState(
                    chromeOnDark: ShellChrome.of(context).isDark,
                    primary: Theme.of(context).colorScheme.primary,
                    message: friendlyError(perfilAsync.error!),
                    onRetry: _refresh,
                  )
                  : const SkeletonList(count: 6),
        ),
      );
    }

    final chrome = ShellChrome.of(context);
    final chromeAccent = _palette.chromeFor(dark: chrome.isDark);
    final plano = perfil.plano;
    final hasWhiteLabel = identidadeHasWhiteLabel(
      featureWhiteLabel:
          ref.watch(planoFeaturesProvider).value?.whiteLabel,
      plano: plano,
    );
    final nomePersonal = perfil.nome;
    final reduceMotion = TokensStrip.prefersReducedMotion(context);

    return FxFormPopGuard(
      dirty: _dirty,
      onCancel: _pedirSair,
      child: fxScreenA11yScope(
        label: 'Identidade Visual',
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: widget.isSetup ? 'Configurar meu app' : 'Identidade Visual',
            subtitle: identidadeAppBarSubtitle(
              hasWhiteLabel: hasWhiteLabel,
              fetchedAt: _fetchedAt,
            ),
            onBack: _pedirSair,
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
                  ? FxFormStickyBar(
                    child: FxLiquidPrimaryButton(
                      label: identidadeSalvarLabel(isSetup: widget.isSetup),
                      loading: _salvando,
                      loadingLabel: identidadeSalvandoLabel(),
                      onPressed:
                          _salvando
                              ? null
                              : () =>
                                  _pedirSalvar(hasWhiteLabel: hasWhiteLabel),
                    ),
                  )
                  : null,
          body: FxKeyboardDismissScope(
            child: RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: _refresh,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                            onTap: () => context.push('/assinatura'),
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
                                Text(
                                  identidadeAlunoVisibilityLabel(),
                                  style: FocuxHubTypography.chip(chrome.mute)
                                      .copyWith(letterSpacing: 0.2),
                                ),
                                const SizedBox(height: TokensStrip.s2),
                                FxChoiceStrip<int>(
                                  itens: [
                                    FxChoiceItem(
                                      value: 0,
                                      label: identidadePreviaHomeClaro(),
                                    ),
                                    FxChoiceItem(
                                      value: 1,
                                      label: identidadePreviaHomeEscuro(),
                                    ),
                                    FxChoiceItem(
                                      value: 2,
                                      label: identidadePreviaLogin(),
                                    ),
                                  ],
                                  selecionado: _previa,
                                  onSelecionar: (v) => setState(() => _previa = v),
                                ),
                                const SizedBox(height: TokensStrip.s3),
                                if (_previa == 2)
                                  _PaletteThemePreviewPair(
                                    palette: _palette,
                                    name: nomePersonal,
                                    slogan: _sloganCtrl.text.trim(),
                                    logoUrl: _logoUrl,
                                    reduceMotion: reduceMotion,
                                  )
                                else
                                  IdentidadePreviaApp(
                                    palette: _palette,
                                    estilo: _estilo,
                                    escuro: _previa == 1,
                                    nomePersonal: nomePersonal,
                                    slogan: _sloganCtrl.text.trim(),
                                    logoUrl: _logoUrl,
                                    capaUrl: _capaUrl,
                                  ),
                                const SizedBox(height: TokensStrip.s4),
                                ShellSurface(
                                  accent: chromeAccent,
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _PanelTitle(
                                        icon: Icons.auto_awesome_motion_outlined,
                                        title: 'Estilo',
                                        subtitle: identidadeEstiloSubtitle(),
                                        accent: chromeAccent,
                                        mute: chrome.mute,
                                      ),
                                      const SizedBox(height: 14),
                                      FxChoiceStrip<BrandStyle>(
                                        itens: [
                                          for (final e in BrandStyle.values)
                                            FxChoiceItem(
                                              value: e,
                                              label: identidadeEstiloLabel(e),
                                            ),
                                        ],
                                        selecionado: _estilo,
                                        onSelecionar:
                                            hasWhiteLabel
                                                ? (e) {
                                                  HapticFeedback.selectionClick();
                                                  setState(() => _estilo = e);
                                                }
                                                : (_) {},
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        identidadeEstiloDescricao(_estilo),
                                        style: FocuxHubTypography.bodyMuted(
                                          color: chrome.mute,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ShellSurface(
                                  accent: chromeAccent,
                                  padding: const EdgeInsets.all(18),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _PanelTitle(
                                        icon: Icons.auto_awesome_outlined,
                                        title: 'Imagens e slogan',
                                        subtitle: identidadeImagensSubtitle(),
                                        accent: chromeAccent,
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
                                              hasWhiteLabel
                                                  ? _pedirTrocarLogo
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'CAPA',
                                        style: FocuxHubTypography.chip(
                                          chrome.mute,
                                        ).copyWith(letterSpacing: 1.2),
                                      ),
                                      const SizedBox(height: 8),
                                      IdentidadeCapaTile(
                                        url: _capaUrl,
                                        uploading: _uploadingCapa,
                                        onEscolher:
                                            hasWhiteLabel ? _pickCapa : null,
                                        onRemover:
                                            hasWhiteLabel
                                                ? () => setState(
                                                  () => _capaUrl = null,
                                                )
                                                : null,
                                      ),
                                      const SizedBox(height: 18),
                                      _BrandField(
                                        label: 'Slogan',
                                        controller: _sloganCtrl,
                                        enabled: hasWhiteLabel,
                                        accent: chromeAccent,
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
                                  accent: chromeAccent,
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    18,
                                    18,
                                    14,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _PanelTitle(
                                        icon: Icons.palette_outlined,
                                        title: 'Paleta premium',
                                        subtitle: identidadePaletteSubtitle(),
                                        accent: chromeAccent,
                                        mute: chrome.mute,
                                      ),
                                      const SizedBox(height: 14),
                                      IdentidadePaletasGrade(
                                        selecionada: _palette,
                                        onSelect:
                                            hasWhiteLabel
                                                ? (p) {
                                                  HapticFeedback.selectionClick();
                                                  setState(() => _palette = p);
                                                }
                                                : null,
                                      ),
                                      if (identidadeAvisoContraste(_palette)
                                          case final aviso?) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.visibility_outlined,
                                              size: 16,
                                              color: chrome.mute,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                aviso,
                                                style:
                                                    FocuxHubTypography.bodyMuted(
                                                      color: chrome.mute,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (hasWhiteLabel) ...[
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: FxActionLink(
                                            label:
                                                identidadeRestaurarCoresLabel(),
                                            onTap:
                                                () => _pedirRestaurarCores(
                                                  hasWhiteLabel: hasWhiteLabel,
                                                ),
                                          ),
                                        ),
                                      ],
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
          ),
        ),
      ),
    );
  }
}

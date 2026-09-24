import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/api/media_upload_service.dart';
import '../../../core/config/env.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/br_phone.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/ux/fx_hub_freshness.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/landing_studio_repository.dart';
import '../utils/landing_link_actions.dart';
import '../utils/landing_studio_guidance.dart';
import 'landing_preview_screen.dart';

part 'landing_editor_screen_actions.part.dart';
part 'landing_studio_screen_entrevista.part.dart';
part 'landing_studio_screen_revisao.part.dart';

/// Landing studio v2 — S5: entrevista → gerar → revisar → publicar.
///
/// Substitui o editor de seções/CTAs/presets. Rota legada:
/// `/perfil/landing-editor`.
class LandingEditorScreen extends ConsumerStatefulWidget {
  const LandingEditorScreen({super.key});

  @override
  ConsumerState<LandingEditorScreen> createState() =>
      _LandingEditorScreenState();
}

class _LandingEditorScreenState extends ConsumerState<LandingEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  // Entrevista
  late final TextEditingController _nomeMarca;
  late final TextEditingController _nicho;
  late final TextEditingController _promessa;
  late final TextEditingController _antiPersona;
  late final TextEditingController _prova;
  late final TextEditingController _ofertaNome;
  late final TextEditingController _ofertaInclui;
  late final TextEditingController _ofertaPreco;
  late final TextEditingController _cta;
  late final TextEditingController _duvida1;
  late final TextEditingController _duvida2;
  late final TextEditingController _duvida3;
  late final TextEditingController _whatsapp;
  late final TextEditingController _instagram;

  // Gerado (revisão)
  late final TextEditingController _heroTitle;
  late final TextEditingController _heroSubtitle;
  late final TextEditingController _primaryCta;
  late final TextEditingController _bio;
  late final TextEditingController _fechamento;

  bool _loading = true;
  bool _busy = false;
  bool _uploadingHero = false;
  bool _uploadingBio = false;
  String? _error;
  bool _needsProof = false;
  bool _podePublicar = false;
  int _step = 0; // 0 entrevista · 1 revisar
  String? _slug;
  String? _publicUrl;
  bool _publicado = false;
  String? _heroImageUrl;
  String? _bioImageUrl;
  bool _dirty = false;
  DateTime? _fetchedAt;
  List<LandingMetodoPasso> _metodo = const [];
  List<LandingStudioServico> _servicos = const [];
  List<LandingStudioFaq> _faq = const [];

  List<TextEditingController> get _allControllers => [
    _nomeMarca,
    _nicho,
    _promessa,
    _antiPersona,
    _prova,
    _ofertaNome,
    _ofertaInclui,
    _ofertaPreco,
    _cta,
    _duvida1,
    _duvida2,
    _duvida3,
    _whatsapp,
    _instagram,
    _heroTitle,
    _heroSubtitle,
    _primaryCta,
    _bio,
    _fechamento,
  ];

  @override
  void initState() {
    super.initState();
    _nomeMarca = TextEditingController();
    _nicho = TextEditingController();
    _promessa = TextEditingController();
    _antiPersona = TextEditingController();
    _prova = TextEditingController();
    _ofertaNome = TextEditingController();
    _ofertaInclui = TextEditingController();
    _ofertaPreco = TextEditingController();
    _cta = TextEditingController();
    _duvida1 = TextEditingController();
    _duvida2 = TextEditingController();
    _duvida3 = TextEditingController();
    _whatsapp = TextEditingController();
    _instagram = TextEditingController();
    _heroTitle = TextEditingController();
    _heroSubtitle = TextEditingController();
    _primaryCta = TextEditingController();
    _bio = TextEditingController();
    _fechamento = TextEditingController();
    for (final c in _allControllers) {
      c.addListener(_markDirty);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _markDirty() {
    if (!_dirty && mounted) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.removeListener(_markDirty);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return fxScreenA11yScope(
      label: 'Landing page',
      child: FeatureGate(
        featureName: 'Landing page completa',
        capability: 'landingCompleta',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        child: FxFormPopGuard(
          dirty: _dirty || _step == 1,
          onCancel: _onBack,
          child: FxShellScaffold(
            useMesh: true,
            appBar: FxShellAppBar(
              title: 'Landing page',
              subtitle: _appBarSubtitle,
              onBack: _onBack,
              actions: [
                FxHelpIconButton(
                  tooltip: 'Como funciona a landing',
                  onTap: () {
                    unawaited(
                      AnalyticsService.instance.track(
                        ProductEvents.landingHelpOpened,
                      ),
                    );
                    showFxHelpSheet(
                      context,
                      title: 'Landing page',
                      subtitle: 'Página pública que captura leads.',
                      tips: const [
                        FxHelpTip(
                          'Entrevista rápida',
                          'Responda em linguagem simples. O Focux escreve a página.',
                          icon: 'mic',
                        ),
                        FxHelpTip(
                          'Gerar',
                          'O backend monta título, método, FAQ e fechamento.',
                          icon: 'sparkles',
                        ),
                        FxHelpTip(
                          'Publicar',
                          'Revise textos e fotos. O link fica em focuxpersonal.com/p/…',
                          icon: 'link',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: TokensStrip.s2),
              ],
            ),
            bottomNavigationBar: _loading
                ? null
                : FxFormStickyBar(
                    child: _step == 1
                        ? Row(
                            children: [
                              Expanded(
                                child: FxLiquidSecondaryButton(
                                  label: 'Entrevista',
                                  onPressed: _busy
                                      ? null
                                      : () => setState(() => _step = 0),
                                ),
                              ),
                              const SizedBox(width: TokensStrip.s2),
                              Expanded(
                                flex: 2,
                                child: FxLiquidPrimaryButton(
                                  label: _busy
                                      ? 'Publicando…'
                                      : (_publicado
                                          ? 'Republicar'
                                          : 'Publicar'),
                                  loading: _busy,
                                  loadingLabel: 'Publicando…',
                                  onPressed:
                                      _canPublish ? _publicar : null,
                                ),
                              ),
                            ],
                          )
                        : FxLiquidPrimaryButton(
                            label: _busy ? 'Gerando…' : 'Gerar página',
                            loading: _busy,
                            loadingLabel: 'Gerando…',
                            onPressed: _canGenerate ? _gerar : null,
                          ),
                  ),
            body: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                onRefresh: () => _load(fromRefresh: true),
                child: _buildBody(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(TokensStrip.s4),
        children: const [SkeletonList(count: 6)],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          FxErrorState(
            chromeOnDark: ShellChrome.of(context).isDark,
            primary: Theme.of(context).colorScheme.primary,
            message: _error!,
            onRetry: _load,
          ),
        ],
      );
    }
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.deferToChild,
      child: Form(
        key: _formKey,
        child: _step == 0
            ? _LandingStudioEntrevistaBody(state: this)
            : _LandingStudioRevisaoBody(state: this),
      ),
    );
  }
}

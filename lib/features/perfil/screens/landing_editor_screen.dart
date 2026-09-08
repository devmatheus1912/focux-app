import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/landing_studio_repository.dart';
import '../utils/landing_studio_guidance.dart';

part 'landing_studio_screen_body.part.dart';

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
  String? _accentColor;
  bool _dirty = false;
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

  LandingEntrevista _entrevistaFromFields() {
    return LandingEntrevista(
      nomeMarca: _nomeMarca.text,
      nicho: _nicho.text,
      promessa: _promessa.text,
      antiPersona: _antiPersona.text,
      prova: _prova.text,
      ofertaNome: _ofertaNome.text,
      ofertaInclui: _ofertaInclui.text,
      ofertaPreco: _ofertaPreco.text,
      cta: _cta.text,
      duvidas: [
        _duvida1.text,
        _duvida2.text,
        _duvida3.text,
      ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      whatsapp: BrPhone.normalizeOrNull(_whatsapp.text) ?? _whatsapp.text.trim(),
      instagram: _instagram.text.trim().replaceFirst('@', ''),
    );
  }

  void _applyState(LandingStudioState state, {bool preferReview = false}) {
    final e = state.entrevista;
    _nomeMarca.text = e.nomeMarca;
    _nicho.text = e.nicho;
    _promessa.text = e.promessa;
    _antiPersona.text = e.antiPersona;
    _prova.text = e.prova;
    _ofertaNome.text = e.ofertaNome;
    _ofertaInclui.text = e.ofertaInclui;
    _ofertaPreco.text = e.ofertaPreco;
    _cta.text = e.cta;
    _duvida1.text = e.duvidas.isNotEmpty ? e.duvidas[0] : '';
    _duvida2.text = e.duvidas.length > 1 ? e.duvidas[1] : '';
    _duvida3.text = e.duvidas.length > 2 ? e.duvidas[2] : '';
    _whatsapp.text = BrPhone.formatDisplay(e.whatsapp);
    _instagram.text = e.instagram;

    _applyGerado(state.gerado);
    _heroImageUrl = state.midia.heroImageUrl;
    _bioImageUrl = state.midia.bioImageUrl;
    _accentColor = state.midia.accentColor;
    _slug = state.slug;
    _publicUrl = state.publicUrl;
    _publicado = state.publicado;
    _needsProof = state.needsProof || state.gerado.needsProof;
    _podePublicar = state.podePublicar || state.gerado.hasPublishableCopy;
    _step =
        preferReview || state.gerado.hasPublishableCopy
            ? 1
            : 0;
    _dirty = false;
  }

  void _applyGerado(LandingGerado g) {
    _heroTitle.text = g.heroTitle;
    _heroSubtitle.text = g.heroSubtitle;
    _primaryCta.text = g.primaryCta;
    _bio.text = g.bio;
    _fechamento.text = g.fechamento;
    _needsProof = g.needsProof;
    _podePublicar = g.hasPublishableCopy;
    _metodo = List.of(g.metodo);
    _servicos = List.of(g.servicos);
    _faq = List.of(g.faq);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = await ref.read(landingStudioRepositoryProvider).getState();
      if (!mounted) return;
      setState(() {
        _applyState(state);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = friendlyError(e);
      });
    }
  }

  Future<void> _gerar() async {
    FocusScope.of(context).unfocus();
    final entrevista = _entrevistaFromFields();
    if (!entrevista.isReadyToGenerate) {
      FeedbackHelper.showWarn(
        context,
        'Preencha marca, nicho, promessa e CTA.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(landingStudioRepositoryProvider);
      await repo.saveEntrevista(entrevista);
      final state = await repo.gerar();
      if (!mounted) return;
      setState(() {
        _applyGerado(state.gerado);
        if (state.publicUrl != null) _publicUrl = state.publicUrl;
        if (state.slug != null) _slug = state.slug;
        _needsProof = state.needsProof || state.gerado.needsProof;
        _podePublicar = state.podePublicar || state.gerado.hasPublishableCopy;
        _step = 1;
        _dirty = false;
        _busy = false;
      });
      FeedbackHelper.showSuccess(
        context,
        'Página gerada. Revise e publique.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _uploadImage({required bool hero}) async {
    FocusScope.of(context).unfocus();
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 88,
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
      final bytes = await file.readAsBytes();
      final url = await MediaUploadService(ref.read(apiClientProvider))
          .uploadBytes(
            bytes: bytes,
            filename: file.name,
            folder: 'landing',
            resourceType: 'image',
          );
      if (!mounted) return;
      final primary = Theme.of(context).colorScheme.primary;
      final accent =
          _accentColor?.isNotEmpty == true
              ? _accentColor
              : BrandPalette.toHex(BrandPalette.softened(primary));
      final midia = await ref.read(landingStudioRepositoryProvider).saveMidia(
            heroImageUrl: hero ? url : _heroImageUrl,
            bioImageUrl: hero ? _bioImageUrl : url,
            accentColor: accent,
          );
      if (!mounted) return;
      setState(() {
        _heroImageUrl = midia.heroImageUrl ?? (hero ? url : _heroImageUrl);
        _bioImageUrl = midia.bioImageUrl ?? (hero ? _bioImageUrl : url);
        _accentColor = midia.accentColor ?? accent;
        _uploadingHero = false;
        _uploadingBio = false;
        _dirty = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingHero = false;
        _uploadingBio = false;
      });
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  LandingGerado _geradoFromFields() {
    return LandingGerado(
      heroTitle: _heroTitle.text,
      heroSubtitle: _heroSubtitle.text,
      primaryCta: _primaryCta.text,
      bio: _bio.text,
      metodo: _metodo,
      servicos: _servicos,
      faq: _faq,
      fechamento: _fechamento.text,
      needsProof: _needsProof,
    );
  }

  Future<void> _publicar() async {
    FocusScope.of(context).unfocus();
    if (_heroTitle.text.trim().isEmpty || _primaryCta.text.trim().isEmpty) {
      FeedbackHelper.showWarn(
        context,
        'Título e CTA são obrigatórios para publicar.',
      );
      return;
    }
    setState(() => _busy = true);
    final primary = Theme.of(context).colorScheme.primary;
    try {
      final repo = ref.read(landingStudioRepositoryProvider);
      await repo.saveEntrevista(_entrevistaFromFields());
      final accent =
          _accentColor?.isNotEmpty == true
              ? _accentColor
              : BrandPalette.toHex(BrandPalette.softened(primary));
      await repo.saveMidia(
        heroImageUrl: _heroImageUrl,
        bioImageUrl: _bioImageUrl,
        accentColor: accent,
      );
      final state = await repo.publicar(gerado: _geradoFromFields());
      if (!mounted) return;
      setState(() {
        _slug = state.slug ?? _slug;
        _publicUrl = state.publicUrl ?? _publicUrl;
        _publicado = true;
        _podePublicar = state.podePublicar;
        _needsProof = state.needsProof;
        _busy = false;
        _dirty = false;
      });
      HapticFeedback.mediumImpact();
      FeedbackHelper.showSuccess(
        context,
        'Landing no ar · ${_publicUrlLabel()}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  String _publicUrlLabel() {
    final slug = (_slug ?? '').trim();
    if (slug.isNotEmpty) return Env.landingPageDisplayLabel(slug);
    final url = (_publicUrl ?? '').trim();
    if (url.isNotEmpty) {
      final host = Uri.tryParse(url)?.host;
      if (host != null && host.isNotEmpty) {
        return url.replaceFirst(RegExp(r'^https?://'), '');
      }
      return url;
    }
    return 'focuxpersonal.com/p/…';
  }

  String? _resolvedPublicUrl() {
    final fromState = (_publicUrl ?? '').trim();
    if (fromState.isNotEmpty) {
      // Prefer canonical brand host when BE still returns Railway.
      final slug = (_slug ?? '').trim();
      if (slug.isNotEmpty) return Env.landingPageUrl(slug);
      return fromState;
    }
    final slug = (_slug ?? '').trim();
    if (slug.isNotEmpty) return Env.landingPageUrl(slug);
    return null;
  }

  Future<void> _copyLink() async {
    final url = _resolvedPublicUrl();
    if (url == null) {
      FeedbackHelper.showWarn(
        context,
        'Publique a landing para gerar o endereço.',
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    FeedbackHelper.showSuccess(context, 'Link copiado');
  }

  Future<void> _openPublicOrPreview() async {
    final url = _resolvedPublicUrl();
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    // Sem URL pública ainda: preview autenticado no BE.
    try {
      final html =
          await ref.read(landingStudioRepositoryProvider).previewHtml();
      if (!mounted) return;
      if (html.trim().isEmpty) {
        FeedbackHelper.showWarn(context, 'Preview indisponível ainda.');
        return;
      }
      await showFxConfirmSheet(
        context,
        title: 'Preview pronto',
        message:
            'A vitrine é HTML do backend. Publique para abrir o link canônico focuxpersonal.com.',
        confirmLabel: 'Ok',
      );
    } catch (e) {
      if (!mounted) return;
      FeedbackHelper.showError(context, friendlyError(e));
    }
  }

  Future<void> _onBack() async {
    FocusScope.of(context).unfocus();
    if (_step == 1 && !_busy) {
      setState(() => _step = 0);
      return;
    }
    if (_dirty) {
      final leave = await showFxConfirmSheet(
        context,
        title: 'Sair sem salvar?',
        message: 'As alterações desta tela ainda não foram publicadas.',
        confirmLabel: 'Sair',
        destructive: true,
      );
      if (!leave || !mounted) return;
    }
    if (!mounted) return;
    safePopOrGo(context, '/perfil');
  }

  bool get _canGenerate {
    final e = _entrevistaFromFields();
    return e.isReadyToGenerate && !_busy && !_loading;
  }

  bool get _isProfessionalReady => LandingStudioGuidance.isProfessionalReady(
    heroImageUrl: _heroImageUrl,
    ofertaPreco: _ofertaPreco.text,
    needsProof: _needsProof,
    provaTexto: _prova.text,
    bioImageUrl: _bioImageUrl,
    heroTitle: _heroTitle.text,
    primaryCta: _primaryCta.text,
    whatsapp: _whatsapp.text,
  );

  List<String> get _publishMissing => LandingStudioGuidance.missingForPublish(
    heroImageUrl: _heroImageUrl,
    ofertaPreco: _ofertaPreco.text,
    needsProof: _needsProof,
    provaTexto: _prova.text,
    bioImageUrl: _bioImageUrl,
    heroTitle: _heroTitle.text,
    primaryCta: _primaryCta.text,
    whatsapp: _whatsapp.text,
    podePublicar: _podePublicar,
  );

  bool get _canPublish {
    if (_busy || _uploadingHero || _uploadingBio) return false;
    if (!_podePublicar) return false;
    return _heroTitle.text.trim().isNotEmpty &&
        _primaryCta.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return fxScreenA11yScope(
      label: 'Landing page',
      child: FeatureGate(
        featureName: 'Landing page completa',
        capability: 'landingCompleta',
        requiredPlan: SubscriptionPlan.ENTERPRISE,
        child: FxShellScaffold(
          useMesh: true,
          appBar: FxShellAppBar(
            title: 'Landing page',
            subtitle:
                _step == 0
                    ? 'Passo 1 · Entrevista'
                    : _publicado
                    ? 'No ar · revisar e republicar'
                    : 'Passo 2 · Revisar e publicar',
            onBack: _onBack,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como funciona a landing',
                onTap: () => showFxHelpSheet(
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
                ),
              ),
              const SizedBox(width: TokensStrip.s2),
            ],
          ),
          bottomNavigationBar: _loading
              ? null
              : AnimatedPadding(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(bottom: viewInsets.bottom),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensStrip.s4,
                        TokensStrip.s2,
                        TokensStrip.s4,
                        TokensStrip.s3,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_step == 1) ...[
                            FxLiquidSecondaryButton(
                              label: 'Voltar à entrevista',
                              onPressed: _busy
                                  ? null
                                  : () => setState(() => _step = 0),
                            ),
                            const SizedBox(height: TokensStrip.s2),
                          ],
                          FxLiquidPrimaryButton(
                            label:
                                _busy
                                    ? (_step == 0
                                        ? 'Gerando…'
                                        : 'Publicando…')
                                    : (_step == 0
                                        ? 'Gerar página'
                                        : (_publicado
                                            ? 'Republicar'
                                            : 'Publicar')),
                            loading: _busy,
                            loadingLabel:
                                _step == 0 ? 'Gerando…' : 'Publicando…',
                            onPressed:
                                _step == 0
                                    ? (_canGenerate ? _gerar : null)
                                    : (_canPublish ? _publicar : null),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          body: SafeArea(
            bottom: false,
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(TokensStrip.s4),
        child: SkeletonList(count: 6),
      );
    }
    if (_error != null) {
      return FxErrorState(
        chromeOnDark: ShellChrome.of(context).isDark,
        primary: Theme.of(context).colorScheme.primary,
        message: _error!,
        onRetry: _load,
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

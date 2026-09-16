import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/router/safe_navigation.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_confirm_sheet.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_form_chrome.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/white_label_repository.dart';
import '../utils/white_label_display.dart';

class WhiteLabelSettingsScreen extends ConsumerStatefulWidget {
  const WhiteLabelSettingsScreen({super.key});

  @override
  ConsumerState<WhiteLabelSettingsScreen> createState() =>
      _WhiteLabelSettingsScreenState();
}

class _WhiteLabelSettingsScreenState
    extends ConsumerState<WhiteLabelSettingsScreen> {
  final _appNameCtrl = TextEditingController();
  final _domainCtrl = TextEditingController();
  bool _ocultarFocux = false;
  String _landingModo = 'CAPTURA';
  bool _salvando = false;
  bool _verificando = false;
  bool _loaded = false;
  String _baseAppName = '';
  String _baseDomain = '';
  bool _baseOcultar = false;
  String _baseLanding = 'CAPTURA';

  @override
  void initState() {
    super.initState();
    _appNameCtrl.addListener(_onFieldChanged);
    _domainCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appNameCtrl.removeListener(_onFieldChanged);
    _domainCtrl.removeListener(_onFieldChanged);
    _appNameCtrl.dispose();
    _domainCtrl.dispose();
    super.dispose();
  }

  void _apply(WhiteLabelConfig config) {
    if (_loaded) return;
    _appNameCtrl.text = config.appDisplayName ?? '';
    _domainCtrl.text = config.dominioCustomizado ?? '';
    _ocultarFocux = config.ocultarMarcaFocux;
    _landingModo = config.landingModo;
    _baseAppName = _appNameCtrl.text;
    _baseDomain = _domainCtrl.text;
    _baseOcultar = _ocultarFocux;
    _baseLanding = _landingModo;
    _loaded = true;
  }

  bool get _isDirty =>
      _loaded &&
      (_appNameCtrl.text != _baseAppName ||
          _domainCtrl.text != _baseDomain ||
          _ocultarFocux != _baseOcultar ||
          _landingModo != _baseLanding);

  Future<void> _cancel() async {
    FxKeyboardDismissScope.dismiss();
    if (_isDirty) {
      final ok = await showFxConfirmSheet(
        context,
        title: 'Descartar alterações?',
        message: 'O que você alterou não será salvo.',
        confirmLabel: 'Descartar',
      );
      if (!ok || !mounted) return;
    }
    safePopOrGo(context, '/perfil');
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      await ref
          .read(whiteLabelRepositoryProvider)
          .save(
            appDisplayName: _appNameCtrl.text.trim(),
            ocultarMarcaFocux: _ocultarFocux,
            dominioCustomizado: _domainCtrl.text.trim(),
            landingModo: _landingModo,
          );
      _baseAppName = _appNameCtrl.text;
      _baseDomain = _domainCtrl.text;
      _baseOcultar = _ocultarFocux;
      _baseLanding = _landingModo;
      ref.invalidate(whiteLabelConfigProvider);
      if (mounted) FeedbackHelper.showSuccess(context, 'Configurações salvas');
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _verificarDominio() async {
    setState(() => _verificando = true);
    try {
      await ref.read(whiteLabelRepositoryProvider).verifyDomain();
      ref.invalidate(whiteLabelConfigProvider);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Domínio marcado como verificado');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Verifique o DNS antes de confirmar');
      }
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(whiteLabelConfigProvider);
    final config = configAsync.valueOrNull;
    if (config != null) _apply(config);
    final chrome = ShellChrome.of(context);

    final gated = FeatureGate(
      featureName: 'Marca própria',
      requiredPlan: SubscriptionPlan.ENTERPRISE,
      capability: 'whiteLabel',
      child: FxFormPopGuard(
        dirty: _isDirty,
        onCancel: _cancel,
        child: FxShellScaffold(
          useMesh: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Marca própria',
            onBack: () {
              _cancel();
            },
          ),
          bottomNavigationBar:
              config == null
                  ? null
                  : FxFormStickyBar(
                    child: Semantics(
                      button: true,
                      enabled: !_salvando,
                      label: 'Salvar configurações de marca própria',
                      child: FxLiquidPrimaryButton(
                        label: 'Salvar configurações',
                        loading: _salvando,
                        loadingLabel: 'Salvando…',
                        onPressed: _salvando ? null : _salvar,
                      ),
                    ),
                  ),
          body: FxContentWidthLimiter(
            child:
                config == null
                    ? (configAsync.hasError
                        ? FxErrorState(
                          chromeOnDark:
                              Theme.of(context).brightness == Brightness.dark,
                          primary: Theme.of(context).colorScheme.primary,
                          message: friendlyError(configAsync.error!),
                          onRetry: () =>
                              ref.invalidate(whiteLabelConfigProvider),
                        )
                        : const SkeletonList(count: 5))
                    : ListView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        FxSettingsLayout.pageInset,
                        TokensStrip.s2,
                        FxSettingsLayout.pageInset,
                        88,
                      ),
                      children: [
                        FxSettingsGroup(
                          header: 'App do aluno',
                          caption:
                              'Login, splash e cards sociais usam só a sua marca.',
                          children: [
                            Semantics(
                              toggled: _ocultarFocux,
                              label: 'Ocultar marca Focux',
                              child: SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _ocultarFocux,
                                onChanged:
                                    (v) => setState(() => _ocultarFocux = v),
                                title: const Text('Ocultar marca Focux'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: TokensStrip.s3,
                              ),
                              child: TextField(
                                controller: _appNameCtrl,
                                decoration: FxInputDeco.build(
                                  context,
                                  'Nome do app (aluno)',
                                  hint: 'Ex: Studio João Silva',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: FxSettingsLayout.groupGap),
                        FxSettingsGroup(
                          header: 'Domínio customizado',
                          caption: whiteLabelCnameHint(_domainCtrl.text),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                top: TokensStrip.s2,
                                bottom: TokensStrip.s2,
                              ),
                              child: TextField(
                                controller: _domainCtrl,
                                decoration: FxInputDeco.build(
                                  context,
                                  'Domínio',
                                  hint: 'treino.seudominio.com.br',
                                ),
                                autocorrect: false,
                                keyboardType: TextInputType.url,
                              ),
                            ),
                            if (config.dominioVerificado)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: TokensStrip.s2,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      color: EagleTokens.success,
                                      size: 18,
                                    ),
                                    const SizedBox(width: TokensStrip.s2),
                                    Text(
                                      'Domínio verificado',
                                      style: FocuxHubTypography.bodyMuted(
                                        color: EagleTokens.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (whiteLabelDnsSteps(
                              config.dnsInstrucoes,
                            ).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: TokensStrip.s2,
                                ),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(
                                    TokensStrip.s3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: chrome.cardFill,
                                    borderRadius: BorderRadius.circular(
                                      TokensStrip.rCard,
                                    ),
                                    border: Border.all(color: chrome.line),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'DNS',
                                        style: FocuxHubTypography.chip(
                                          chrome.mute,
                                        ),
                                      ),
                                      const SizedBox(height: TokensStrip.s2),
                                      for (final step in whiteLabelDnsSteps(
                                        config.dnsInstrucoes,
                                      ))
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          child: Text(
                                            '• $step',
                                            style:
                                                FocuxHubTypography.bodyMuted(
                                                  color: chrome.mute,
                                                  height: 1.4,
                                                ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            if (whiteLabelCanVerifyDomain(
                              domainDraft: _domainCtrl.text,
                              dominioVerificado: config.dominioVerificado,
                            ))
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: TokensStrip.s2,
                                ),
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _verificando ? null : _verificarDominio,
                                  icon:
                                      _verificando
                                          ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: FxLoading(strokeWidth: 2),
                                          )
                                          : const Icon(Icons.dns_outlined),
                                  label: const Text('Verificar domínio'),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: FxSettingsLayout.groupGap),
                        FxSettingsGroup(
                          header: 'Como você vende',
                          caption:
                              _landingModo == 'CAPTURA'
                                  ? 'Destaque o link curto de captura no dashboard e anúncios.'
                                  : 'Destaque a página completa com foto, planos e depoimentos.',
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: TokensStrip.s2,
                              ),
                              child: Semantics(
                                label: 'Modo de venda da landing',
                                child: SegmentedButton<String>(
                                  showSelectedIcon: false,
                                  segments: const [
                                    ButtonSegment(
                                      value: 'CAPTURA',
                                      label: Text('Formulário rápido'),
                                    ),
                                    ButtonSegment(
                                      value: 'SITE',
                                      label: Text('Página completa'),
                                    ),
                                  ],
                                  selected: {_landingModo},
                                  onSelectionChanged:
                                      (s) => setState(
                                        () => _landingModo = s.first,
                                      ),
                                ),
                              ),
                            ),
                            if (config.slug != null &&
                                config.slug!.isNotEmpty) ...[
                              _linkTile(
                                title: 'Página completa',
                                hint: 'Ideal para Instagram, WhatsApp e bio.',
                                displayLabel: Env.landingPageDisplayLabel(
                                  config.slug!,
                                ),
                                copyUrl:
                                    config.publicLandingUrl.isNotEmpty
                                        ? config.publicLandingUrl
                                        : Env.landingPageUrl(config.slug!),
                              ),
                              _linkTile(
                                title: 'Formulário rápido',
                                hint: 'Só nome e WhatsApp — use em anúncios.',
                                displayLabel: Env.capturaPageDisplayLabel(
                                  config.slug!,
                                ),
                                copyUrl:
                                    config.publicCapturaUrl.isNotEmpty
                                        ? config.publicCapturaUrl
                                        : Env.capturaPageUrl(config.slug!),
                              ),
                            ] else
                              _linkTile(
                                title: 'Página completa',
                                hint:
                                    'Configure seu link público no perfil primeiro.',
                                displayLabel: 'focuxpersonal.com/p/seu-nome',
                                copyUrl: config.publicLandingUrl,
                              ),
                          ],
                        ),
                        const SizedBox(height: FxSettingsLayout.groupGap),
                        FxSettingsGroup(
                          header:
                              'Checklist (${config.checklistScore}/${config.checklist.length})',
                          children: [
                            for (final item in config.checklist)
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: item.done,
                                onChanged: null,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  item.label,
                                  style: FocuxHubTypography.body(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );

    return fxScreenA11yScope(label: 'Marca própria', child: gated);
  }

  Widget _linkTile({
    required String title,
    required String hint,
    required String displayLabel,
    required String copyUrl,
  }) {
    if (copyUrl.isEmpty && displayLabel.isEmpty) return const SizedBox.shrink();
    final chrome = ShellChrome.of(context);
    final urlToCopy = copyUrl.isNotEmpty ? copyUrl : displayLabel;

    return Container(
      margin: const EdgeInsets.only(bottom: TokensStrip.s2),
      decoration: fxListCardDecoration(context, radius: TokensStrip.rCard),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: FocuxHubTypography.body(
                color: Theme.of(context).colorScheme.onSurface,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: chrome.cardFill,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayLabel,
                style: FocuxHubTypography.bodyMuted(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: TokensStrip.s2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed:
                    urlToCopy.isEmpty
                        ? null
                        : () {
                          Clipboard.setData(ClipboardData(text: urlToCopy));
                          FeedbackHelper.showSuccess(context, 'Link copiado');
                        },
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copiar link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

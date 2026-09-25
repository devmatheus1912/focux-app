import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_settings_group.dart';
import '../../../core/widgets/fx_settings_tile.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../alunos/widgets/aluno_form_choices.dart';
import '../../planos/providers/plano_features_provider.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/utils/landing_editor_access.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
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
  bool _dominioDisponivel = false;
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
    _dominioDisponivel = config.dominioDisponivel;
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
    FxKeyboardDismissScope.dismiss();
    setState(() => _salvando = true);
    try {
      await ref
          .read(whiteLabelRepositoryProvider)
          .save(
            appDisplayName: _appNameCtrl.text.trim(),
            ocultarMarcaFocux: _ocultarFocux,
            dominioCustomizado:
                _dominioDisponivel ? _domainCtrl.text.trim() : null,
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
    FxKeyboardDismissScope.dismiss();
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

  Future<void> _onLandingModoSelect(String v) async {
    if (whiteLabelNeedsLandingCompleta(v)) {
      final features = ref.read(planoFeaturesProvider).valueOrNull;
      if (features?.landingCompleta != true) {
        if (!mounted) return;
        await UpgradePromptSheet.show(
          context: context,
          featureName: 'Landing page completa',
          capability: 'landingCompleta',
          requiredPlan: SubscriptionPlan.ENTERPRISE,
          source: 'marca_landing_site',
        );
        return;
      }
    }
    setState(() => _landingModo = v);
  }

  Future<void> _onChecklistTap(WhiteLabelChecklistItem item) async {
    if (item.done) return;
    final route = whiteLabelChecklistRoute(item.id);
    if (route == null) return;
    if (route == '/perfil/landing-editor') {
      await openLandingEditorOrUpgrade(context, ref);
      return;
    }
    if (mounted) context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(whiteLabelConfigProvider);
    final config = configAsync.valueOrNull;
    if (config != null) _apply(config);
    final chrome = ShellChrome.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSave = _isDirty && !_salvando;

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
            actions: [
              FxHelpIconButton(
                tooltip: 'Como funciona a marca própria',
                onTap: () => showFxHelpSheet(
                  context,
                  title: 'Marca própria',
                  subtitle: 'Seu nome no app do aluno e nos links de venda.',
                  tips: const [
                    FxHelpTip(
                      'App do aluno',
                      'Depois do login o aluno vê sua marca. Login e ícone da loja seguem Focux.',
                    ),
                    FxHelpTip(
                      'Links',
                      'Toque num link para copiar e mande no WhatsApp ou Instagram.',
                    ),
                    FxHelpTip(
                      'Checklist',
                      'Itens pendentes abrem a tela certa para completar.',
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar:
              config == null
                  ? null
                  : FxFormStickyBar(
                    child: Semantics(
                      button: true,
                      enabled: canSave,
                      label: 'Salvar configurações de marca própria',
                      child: FxLiquidPrimaryButton(
                        label: 'Salvar',
                        loading: _salvando,
                        loadingLabel: 'Salvando…',
                        onPressed: canSave ? _salvar : null,
                      ),
                    ),
                  ),
          body: FxKeyboardDismissScope(
            child: FxContentWidthLimiter(
              child:
                  config == null
                      ? (configAsync.hasError
                          ? FxErrorState(
                            chromeOnDark: isDark,
                            primary: Theme.of(context).colorScheme.primary,
                            message: friendlyError(configAsync.error!),
                            onRetry: () =>
                                ref.invalidate(whiteLabelConfigProvider),
                          )
                          : const SkeletonList(count: 4))
                      : ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          FxSettingsLayout.pageInset,
                          TokensStrip.s2,
                          FxSettingsLayout.pageInset,
                          120,
                        ),
                        children: [
                          FxSettingsGroup(
                            header: 'App do aluno',
                            caption:
                                'Depois do login o aluno vê a sua marca. Tela de login e ícone da loja continuam Focux.',
                            children: [
                              FxSettingsTile(
                                icon: Icons.visibility_off_outlined,
                                label: 'Ocultar marca Focux',
                                value: '',
                                showDivider: true,
                                accessory: Switch.adaptive(
                                  value: _ocultarFocux,
                                  onChanged:
                                      (v) => setState(() => _ocultarFocux = v),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: TokensStrip.s1,
                                  bottom: TokensStrip.s1,
                                ),
                                child: TextField(
                                  controller: _appNameCtrl,
                                  textInputAction: TextInputAction.next,
                                  onTapOutside:
                                      (_) => FxKeyboardDismissScope.dismiss(),
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
                          if (!config.dominioDisponivel)
                            const FxSettingsGroup(
                              header: 'Domínio próprio',
                              caption: whiteLabelDominioEmBreveCaption,
                              children: [
                                FxSettingsTile(
                                  icon: Icons.language_outlined,
                                  label: 'Seu domínio',
                                  value: 'Em breve',
                                  showDivider: false,
                                ),
                              ],
                            )
                          else
                          FxSettingsGroup(
                            header: 'Domínio próprio',
                            caption: whiteLabelCnameHint(
                              _domainCtrl.text,
                              verificacaoToken: config.dominioVerificacaoToken,
                            ),
                            footer:
                                whiteLabelDnsSteps(config.dnsInstrucoes).isEmpty
                                    ? null
                                    : Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: FxSettingsLayout.groupPadH,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          for (final step in whiteLabelDnsSteps(
                                            config.dnsInstrucoes,
                                          ))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 4,
                                              ),
                                              child: Text(
                                                '• ${whiteLabelDnsStepShort(step)}',
                                                style:
                                                    FocuxHubTypography.bodyMuted(
                                                      color: chrome.mute,
                                                      height: 1.3,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: TokensStrip.s1,
                                  bottom: TokensStrip.s1,
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
                                  textInputAction: TextInputAction.done,
                                  onTapOutside:
                                      (_) => FxKeyboardDismissScope.dismiss(),
                                  onSubmitted:
                                      (_) => FxKeyboardDismissScope.dismiss(),
                                ),
                              ),
                              if (config.dominioVerificado)
                                FxSettingsTile(
                                  icon: Icons.verified_rounded,
                                  label: 'Domínio verificado',
                                  value: '',
                                  accent: EagleTokens.success,
                                  showDivider: false,
                                ),
                              if (whiteLabelCanVerifyDomain(
                                domainDraft: _domainCtrl.text,
                                dominioSalvo: config.dominioCustomizado,
                                dominioVerificado: config.dominioVerificado,
                              ))
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: TokensStrip.s1,
                                    bottom: TokensStrip.s1,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _verificando
                                              ? null
                                              : _verificarDominio,
                                      icon:
                                          _verificando
                                              ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: FxLoading(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                              : const Icon(Icons.dns_outlined),
                                      label: const Text('Verificar domínio'),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: FxSettingsLayout.groupGap),
                          FxSettingsGroup(
                            header: 'Como você vende',
                            caption: whiteLabelLandingCaption(_landingModo),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: TokensStrip.s1,
                                ),
                                child: Semantics(
                                  label: 'Modo de venda da landing',
                                  child: AlunoSegmentedChoice(
                                    options: whiteLabelLandingModos,
                                    selected: _landingModo,
                                    isDark: isDark,
                                    onSelect: (v) {
                                      _onLandingModoSelect(v);
                                    },
                                  ),
                                ),
                              ),
                              if (config.slug != null &&
                                  config.slug!.isNotEmpty) ...[
                                _linkTile(
                                  chrome: chrome,
                                  title: 'Página completa',
                                  displayLabel: Env.landingPageDisplayLabel(
                                    config.slug!,
                                  ),
                                  copyUrl:
                                      config.publicLandingUrl.isNotEmpty
                                          ? config.publicLandingUrl
                                          : Env.landingPageUrl(config.slug!),
                                  showDivider: true,
                                ),
                                _linkTile(
                                  chrome: chrome,
                                  title: 'Formulário rápido',
                                  displayLabel: Env.capturaPageDisplayLabel(
                                    config.slug!,
                                  ),
                                  copyUrl:
                                      config.publicCapturaUrl.isNotEmpty
                                          ? config.publicCapturaUrl
                                          : Env.capturaPageUrl(config.slug!),
                                  showDivider: false,
                                ),
                              ] else
                                _linkTile(
                                  chrome: chrome,
                                  title: 'Página completa',
                                  displayLabel: 'focuxpersonal.com/p/seu-nome',
                                  copyUrl: config.publicLandingUrl,
                                  showDivider: false,
                                ),
                            ],
                          ),
                          const SizedBox(height: FxSettingsLayout.groupGap),
                          Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.only(
                                bottom: TokensStrip.s2,
                              ),
                              title: Text(
                                'Checklist (${config.checklistScore}/${config.checklist.length})',
                                style: FocuxHubTypography.body(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'O que falta para vender pelo link',
                                style: FocuxHubTypography.bodyMuted(
                                  color: chrome.mute,
                                ),
                              ),
                              children: [
                                FxSettingsGroup(
                                  children: [
                                    for (var i = 0;
                                        i < config.checklist.length;
                                        i++)
                                      FxSettingsTile(
                                        icon:
                                            config.checklist[i].done
                                                ? Icons.check_circle_outline
                                                : Icons.radio_button_unchecked,
                                        label: config.checklist[i].label,
                                        value: whiteLabelChecklistValue(
                                          config.checklist[i].done,
                                        ),
                                        accent:
                                            config.checklist[i].done
                                                ? EagleTokens.success
                                                : null,
                                        showDivider:
                                            i < config.checklist.length - 1,
                                        onTap:
                                            config.checklist[i].done ||
                                                    whiteLabelChecklistRoute(
                                                          config
                                                              .checklist[i]
                                                              .id,
                                                        ) ==
                                                        null
                                                ? null
                                                : () => _onChecklistTap(
                                                  config.checklist[i],
                                                ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: TokensStrip.s4),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );

    return fxScreenA11yScope(label: 'Marca própria', child: gated);
  }

  Widget _linkTile({
    required ShellPalette chrome,
    required String title,
    required String displayLabel,
    required String copyUrl,
    required bool showDivider,
  }) {
    if (copyUrl.isEmpty && displayLabel.isEmpty) return const SizedBox.shrink();
    final urlToCopy = copyUrl.isNotEmpty ? copyUrl : displayLabel;

    return FxSettingsTile(
      icon: Icons.link_outlined,
      label: title,
      value: displayLabel,
      mute: chrome.mute,
      line: chrome.line,
      showDivider: showDivider,
      onTap:
          urlToCopy.isEmpty
              ? null
              : () {
                Clipboard.setData(ClipboardData(text: urlToCopy));
                FeedbackHelper.showSuccess(context, 'Link copiado');
              },
    );
  }
}

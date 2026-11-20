import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

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
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_help.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_loading.dart';
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
import '../../../core/theme/brand_palette.dart';
import '../data/white_label_repository.dart';
import '../providers/perfil_provider.dart';
import '../utils/white_label_display.dart';
import '../../../core/theme/fx_icons.dart';

/// Marca própria. Cada mudança salva sozinha: chave e seletor na hora, nome
/// e domínio ao sair do campo. Erro ao salvar volta o valor e avisa.
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
  final _appNameFocus = FocusNode();
  final _domainFocus = FocusNode();
  bool _ocultarFocux = false;
  String _landingModo = 'CAPTURA';
  bool _salvando = false;
  bool _verificando = false;
  bool _loaded = false;
  bool _dominioDisponivel = false;
  bool _verTudo = false;

  /// O que o servidor tem: volta para cá se salvar falhar.
  String _baseAppName = '';
  String _baseDomain = '';
  bool _baseOcultar = false;
  String _baseLanding = 'CAPTURA';

  @override
  void initState() {
    super.initState();
    _appNameCtrl.addListener(_onFieldChanged);
    _appNameFocus.addListener(_aoSairDoCampo);
    _domainFocus.addListener(_aoSairDoCampo);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  void _aoSairDoCampo() {
    if (!_appNameFocus.hasFocus && !_domainFocus.hasFocus) _salvarSeMudou();
  }

  @override
  void dispose() {
    _appNameCtrl.removeListener(_onFieldChanged);
    _appNameFocus.removeListener(_aoSairDoCampo);
    _domainFocus.removeListener(_aoSairDoCampo);
    _appNameCtrl.dispose();
    _domainCtrl.dispose();
    _appNameFocus.dispose();
    _domainFocus.dispose();
    super.dispose();
  }

  void _apply(WhiteLabelConfig config) {
    if (_loaded) return;
    _appNameCtrl.text = config.appDisplayName ?? '';
    _domainCtrl.text = config.dominioCustomizado ?? '';
    _ocultarFocux = config.ocultarMarcaFocux;
    _landingModo = config.landingModo;
    _dominioDisponivel = config.dominioDisponivel;
    _guardarBase();
    _loaded = true;
  }

  void _guardarBase() {
    _baseAppName = _appNameCtrl.text;
    _baseDomain = _domainCtrl.text;
    _baseOcultar = _ocultarFocux;
    _baseLanding = _landingModo;
  }

  bool get _mudou =>
      _loaded &&
      (_appNameCtrl.text.trim() != _baseAppName.trim() ||
          _domainCtrl.text.trim() != _baseDomain.trim() ||
          _ocultarFocux != _baseOcultar ||
          _landingModo != _baseLanding);

  Future<void> _salvarSeMudou() async {
    if (!_mudou || _salvando) return;
    setState(() => _salvando = true);
    try {
      // Sem nome do app, "tirar Focux" não tem o que pôr no lugar.
      final nome = _appNameCtrl.text.trim();
      if (nome.isEmpty) _ocultarFocux = false;
      await ref
          .read(whiteLabelRepositoryProvider)
          .save(
            appDisplayName: nome,
            ocultarMarcaFocux: _ocultarFocux,
            dominioCustomizado:
                _dominioDisponivel ? _domainCtrl.text.trim() : null,
            landingModo: _landingModo,
          );
      _guardarBase();
      ref.invalidate(whiteLabelConfigProvider);
      if (mounted) FeedbackHelper.showSuccess(context, 'Salvo');
    } catch (e) {
      if (mounted) {
        setState(() {
          _appNameCtrl.text = _baseAppName;
          _domainCtrl.text = _baseDomain;
          _ocultarFocux = _baseOcultar;
          _landingModo = _baseLanding;
        });
        FeedbackHelper.showError(context, friendlyError(e));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _sair() async {
    FxKeyboardDismissScope.dismiss();
    await _salvarSeMudou();
    if (mounted) safePopOrGo(context, '/perfil');
  }

  Future<void> _verificarDominio() async {
    FxKeyboardDismissScope.dismiss();
    await _salvarSeMudou();
    if (!mounted) return;
    setState(() => _verificando = true);
    try {
      await ref.read(whiteLabelRepositoryProvider).verifyDomain();
      ref.invalidate(whiteLabelConfigProvider);
      if (mounted) {
        FeedbackHelper.showSuccess(context, 'Domínio verificado');
      }
    } catch (e) {
      if (mounted) {
        FeedbackHelper.showError(context, 'Confira o DNS e tente de novo');
      }
    } finally {
      if (mounted) setState(() => _verificando = false);
    }
  }

  Future<void> _onLandingModoSelect(String v) async {
    if (whiteLabelNeedsLandingCompleta(v)) {
      final features = ref.read(planoFeaturesProvider).value;
      if (features?.landingCompleta != true) {
        if (!mounted) return;
        await UpgradePromptSheet.show(
          context: context,
          featureName: 'Página completa',
          capability: 'landingCompleta',
          requiredPlan: SubscriptionPlan.ENTERPRISE,
          source: 'marca_landing_site',
        );
        return;
      }
    }
    setState(() => _landingModo = v);
    await _salvarSeMudou();
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
    final config = configAsync.value;
    if (config != null) _apply(config);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gated = FeatureGate(
      featureName: 'Marca própria',
      requiredPlan: SubscriptionPlan.ENTERPRISE,
      capability: 'whiteLabel',
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _sair();
        },
        child: FxShellScaffold(
          comFundo: true,
          constrainWidth: false,
          appBar: FxShellAppBar(
            title: 'Marca própria',
            subtitle: _salvando ? 'Salvando…' : null,
            onBack: _sair,
            actions: [
              FxHelpIconButton(
                tooltip: 'Como funciona a marca própria',
                onTap:
                    () => showFxHelpSheet(
                      context,
                      title: 'Marca própria',
                      subtitle: 'Sua cor, seu logo e seu nome para o aluno.',
                      tips: const [
                        FxHelpTip(
                          'App do aluno',
                          'Depois do login o aluno vê sua cor e seu logo. Login e ícone da loja seguem Focux.',
                        ),
                        FxHelpTip(
                          'Links',
                          'Copie ou compartilhe direto no WhatsApp ou no Instagram.',
                        ),
                        FxHelpTip('Salvar', 'Cada mudança salva sozinha.'),
                      ],
                    ),
              ),
            ],
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
                            onRetry:
                                () => ref.invalidate(whiteLabelConfigProvider),
                          )
                          : const SkeletonList(count: 4))
                      : _corpo(config, isDark),
            ),
          ),
        ),
      ),
    );

    return fxScreenA11yScope(label: 'Marca própria', child: gated);
  }

  Widget _corpo(WhiteLabelConfig config, bool isDark) {
    final chrome = ShellChrome.of(context);
    final pendentes = config.checklist.where((i) => !i.done).toList();
    final corSalva = ref.watch(perfilProvider).value?.corPrimaria;
    final corDaMarca =
        corSalva == null ? null : BrandPalette.resolveStoredPrimary(corSalva);
    final temNome = _appNameCtrl.text.trim().isNotEmpty;

    final checklistCompleto = FxSettingsGroup(
      header:
          pendentes.isEmpty
              ? 'Tudo pronto para vender'
              : 'O que falta (${config.checklistScore} de ${config.checklist.length})',
      children: [
        for (var i = 0; i < config.checklist.length; i++)
          FxSettingsTile(
            icon:
                config.checklist[i].done ? FxIcons.concluido : FxIcons.circulo,
            label: config.checklist[i].label,
            value: whiteLabelChecklistValue(config.checklist[i].done),
            accent: config.checklist[i].done ? EagleTokens.success : null,
            mute: chrome.mute,
            line: chrome.line,
            showDivider: i < config.checklist.length - 1,
            onTap:
                config.checklist[i].done ||
                        whiteLabelChecklistRoute(config.checklist[i].id) == null
                    ? null
                    : () => _onChecklistTap(config.checklist[i]),
          ),
      ],
    );

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        FxSettingsLayout.pageInset,
        TokensStrip.s2,
        FxSettingsLayout.pageInset,
        TokensStrip.s6,
      ),
      children: [
        if (pendentes.isNotEmpty) ...[
          FxSettingsGroup(
            header: whiteLabelFaltaTitulo(pendentes.length),
            children: [
              for (final item in pendentes)
                FxSettingsTile(
                  icon: FxIcons.circulo,
                  label: item.label,
                  value: '',
                  highlight: true,
                  mute: chrome.mute,
                  line: chrome.line,
                  onTap:
                      whiteLabelChecklistRoute(item.id) == null
                          ? null
                          : () => _onChecklistTap(item),
                ),
              FxSettingsTile(
                icon: FxIcons.checklist,
                label: _verTudo ? 'Esconder lista' : 'Ver tudo',
                value:
                    '${config.checklistScore} de ${config.checklist.length}',
                mute: chrome.mute,
                line: chrome.line,
                showDivider: false,
                onTap: () => setState(() => _verTudo = !_verTudo),
              ),
            ],
          ),
          if (_verTudo) checklistCompleto,
          const SizedBox(height: FxSettingsLayout.groupGap),
        ],
        FxSettingsGroup(
          header: 'App do aluno',
          caption:
              'O aluno vê sua cor e seu logo depois do login. A tela de login e o ícone na loja continuam Focux.',
          children: [
            FxSettingsTile(
              icon: FxIcons.paleta,
              label: 'Cor, logo e capa',
              value: '',
              swatch: corDaMarca,
              mute: chrome.mute,
              line: chrome.line,
              onTap: () => context.push('/identidade-visual'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
              child: TextField(
                controller: _appNameCtrl,
                focusNode: _appNameFocus,
                textInputAction: TextInputAction.done,
                onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                onSubmitted: (_) => FxKeyboardDismissScope.dismiss(),
                decoration: FxInputDeco.build(
                  context,
                  'Nome do app',
                  hint: 'Ex: Studio João Silva',
                ).copyWith(
                  helperText: 'Aparece nos convites e PDFs no lugar de Focux.',
                ),
              ),
            ),
            Semantics(
              toggled: _ocultarFocux && temNome,
              label: "Tirar 'Focux' dos convites e PDFs",
              child: FxSettingsTile(
                icon: FxIcons.ocultar,
                label: "Tirar 'Focux' dos convites e PDFs",
                subtitle: temNome ? null : 'Preencha o nome do app primeiro.',
                value: '',
                mute: chrome.mute,
                line: chrome.line,
                showDivider: false,
                accessory: Switch.adaptive(
                  value: _ocultarFocux && temNome,
                  onChanged:
                      temNome
                          ? (v) {
                            setState(() => _ocultarFocux = v);
                            _salvarSeMudou();
                          }
                          : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: FxSettingsLayout.groupGap),
        if (config.dominioDisponivel) ...[
          _dominio(config, chrome),
          const SizedBox(height: FxSettingsLayout.groupGap),
        ],
        _links(config, chrome, isDark),
        if (pendentes.isEmpty) ...[
          const SizedBox(height: FxSettingsLayout.groupGap),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Tudo pronto para vender',
                style: FocuxHubTypography.body(color: chrome.ink),
              ),
              children: [checklistCompleto],
            ),
          ),
        ],
      ],
    );
  }

  Widget _links(WhiteLabelConfig config, ShellPalette chrome, bool isDark) {
    final slug = config.slug ?? '';
    final pagina = (
      titulo: 'Página completa',
      modo: 'SITE',
      mostra:
          slug.isEmpty
              ? 'focuxpersonal.com/p/seu-nome'
              : Env.landingPageDisplayLabel(slug),
      url:
          config.publicLandingUrl.isNotEmpty
              ? config.publicLandingUrl
              : (slug.isEmpty ? '' : Env.landingPageUrl(slug)),
    );
    final formulario = (
      titulo: 'Formulário rápido',
      modo: 'CAPTURA',
      mostra: slug.isEmpty ? '' : Env.capturaPageDisplayLabel(slug),
      url:
          config.publicCapturaUrl.isNotEmpty
              ? config.publicCapturaUrl
              : (slug.isEmpty ? '' : Env.capturaPageUrl(slug)),
    );
    final links = [
      if (formulario.url.isNotEmpty) formulario,
      if (pagina.url.isNotEmpty) pagina,
    ]..sort(
      (a, b) => (a.modo == _landingModo ? 0 : 1).compareTo(
        b.modo == _landingModo ? 0 : 1,
      ),
    );

    return FxSettingsGroup(
      header: 'Seus links',
      caption: 'Qual link usar no seu perfil e anúncios?',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
          child: Semantics(
            label: 'Link principal',
            child: AlunoSegmentedChoice(
              options: whiteLabelLandingModos,
              selected: _landingModo,
              isDark: isDark,
              onSelect: _onLandingModoSelect,
            ),
          ),
        ),
        for (final (i, link) in links.indexed)
          FxSettingsTile(
            icon: FxIcons.link,
            label:
                link.modo == _landingModo
                    ? '${link.titulo} · Principal'
                    : link.titulo,
            subtitle: whiteLabelLinkCurto(link.mostra),
            value: '',
            mute: chrome.mute,
            line: chrome.line,
            showDivider: i < links.length - 1,
            accessory: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Copiar link',
                  icon: const Icon(FxIcons.copiar),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link.url));
                    HapticFeedback.selectionClick();
                    FeedbackHelper.showSuccess(context, 'Link copiado');
                  },
                ),
                IconButton(
                  tooltip: 'Compartilhar link',
                  icon: const Icon(FxIcons.compartilhar),
                  onPressed:
                      () =>
                          SharePlus.instance.share(ShareParams(text: link.url)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dominio(WhiteLabelConfig config, ShellPalette chrome) {
    final passos = whiteLabelDnsSteps(config.dnsInstrucoes);
    return FxSettingsGroup(
      header: 'Domínio próprio',
      caption: whiteLabelCnameHint(
        _domainCtrl.text,
        verificacaoToken: config.dominioVerificacaoToken,
      ),
      footer:
          passos.isEmpty
              ? null
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FxSettingsLayout.groupPadH,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, passo) in passos.indexed)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${i + 1}. ${whiteLabelDnsStepShort(passo)}',
                              style: FocuxHubTypography.bodyMuted(
                                color: chrome.mute,
                                height: 1.3,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copiar passo ${i + 1}',
                            icon: const Icon(FxIcons.copiar),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: passo));
                              FeedbackHelper.showSuccess(context, 'Copiado');
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
          child: TextField(
            controller: _domainCtrl,
            focusNode: _domainFocus,
            decoration: FxInputDeco.build(
              context,
              'Domínio',
              hint: 'treino.seudominio.com.br',
            ),
            autocorrect: false,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
            onSubmitted: (_) => FxKeyboardDismissScope.dismiss(),
          ),
        ),
        if (config.dominioVerificado)
          FxSettingsTile(
            icon: FxIcons.verificado,
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
            padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _verificando ? null : _verificarDominio,
                icon:
                    _verificando
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: FxLoading(strokeWidth: 2),
                        )
                        : const Icon(FxIcons.servidor),
                label: const Text('Verificar domínio'),
              ),
            ),
          ),
      ],
    );
  }
}

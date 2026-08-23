import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/utils/friendly_error.dart';
import '../../../core/widgets/fx_content_width_limiter.dart';
import '../../../core/widgets/feature_gate.dart';
import '../../../core/widgets/feedback_helper.dart';
import '../../../core/widgets/fx_error_state.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_loading.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../subscription/models/subscription_plan.dart';
import '../data/white_label_repository.dart';

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

  @override
  void dispose() {
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
    _loaded = true;
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
      ref.invalidate(whiteLabelConfigProvider);
      if (mounted) FeedbackHelper.showSuccess(context, 'Configurações salvas');
    } catch (e) {
      if (mounted) FeedbackHelper.showError(context, 'Não foi possível salvar');
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
      child: FxShellScaffold(
        useMesh: true,
        constrainWidth: false,
        appBar: FxShellAppBar(
          title: 'Marca própria',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
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
                        onRetry: () => ref.invalidate(whiteLabelConfigProvider),
                      )
                      : const SkeletonList(count: 5))
                  : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _sectionTitle('App do aluno'),
                  Semantics(
                    toggled: _ocultarFocux,
                    label: 'Ocultar marca Focux',
                    child: SwitchListTile(
                      value: _ocultarFocux,
                      onChanged: (v) => setState(() => _ocultarFocux = v),
                      title: const Text('Ocultar marca Focux'),
                      subtitle: const Text(
                        'Login, splash e cards sociais usam só a sua marca.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _appNameCtrl,
                    decoration: FxInputDeco.build(
                      context,
                      'Nome do app (aluno)',
                      hint: 'Ex: Studio João Silva',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Domínio customizado'),
                  TextField(
                    controller: _domainCtrl,
                    decoration: FxInputDeco.build(
                      context,
                      'Domínio',
                      hint: 'treino.seudominio.com.br',
                    ),
                    autocorrect: false,
                    keyboardType: TextInputType.url,
                  ),
                  if (config.dominioVerificado)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            color: EagleTokens.success,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Domínio verificado',
                            style: FocuxHubTypography.bodyMuted(
                              color: EagleTokens.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: chrome.cardFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: chrome.line),
                    ),
                    child: Text(
                      config.dnsInstrucoes,
                      style: FocuxHubTypography.bodyMuted(
                        color: chrome.mute,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _verificando ? null : _verificarDominio,
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
                  const SizedBox(height: 24),
                  _sectionTitle('Como você vende'),
                  Semantics(
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
                          (s) => setState(() => _landingModo = s.first),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _landingModo == 'CAPTURA'
                        ? 'Destaque o link curto de captura no dashboard e anúncios.'
                        : 'Destaque a página completa com foto, planos e depoimentos.',
                    style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                  ),
                  const SizedBox(height: 16),
                  if (config.slug != null && config.slug!.isNotEmpty) ...[
                    _linkTile(
                      title: 'Página completa',
                      hint: 'Ideal para Instagram, WhatsApp e bio.',
                      displayLabel: Env.landingPageDisplayLabel(config.slug!),
                      copyUrl:
                          config.publicLandingUrl.isNotEmpty
                              ? config.publicLandingUrl
                              : Env.landingPageUrl(config.slug!),
                    ),
                    _linkTile(
                      title: 'Formulário rápido',
                      hint: 'Só nome e WhatsApp — use em anúncios.',
                      displayLabel: Env.capturaPageDisplayLabel(config.slug!),
                      copyUrl:
                          config.publicCapturaUrl.isNotEmpty
                              ? config.publicCapturaUrl
                              : Env.capturaPageUrl(config.slug!),
                    ),
                  ] else ...[
                    _linkTile(
                      title: 'Página completa',
                      hint: 'Configure seu link público no perfil primeiro.',
                      displayLabel: 'focuxpersonal.com/p/seu-nome',
                      copyUrl: config.publicLandingUrl,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _sectionTitle(
                    'Checklist máquina de vendas (${config.checklistScore}/${config.checklist.length})',
                  ),
                  ...config.checklist.map(
                    (item) => CheckboxListTile(
                      value: item.done,
                      onChanged: null,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        item.label,
                        style: FocuxHubTypography.body(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    button: true,
                    enabled: !_salvando,
                    label: 'Salvar configurações de marca própria',
                    child: FilledButton(
                      onPressed: _salvando ? null : _salvar,
                      child:
                          _salvando
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: FxLoading(strokeWidth: 2),
                              )
                              : const Text('Salvar configurações'),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );

    return fxScreenA11yScope(label: 'Marca própria', child: gated);
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: FocuxHubTypography.sectionTitle(
        context,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );

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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: fxListCardDecoration(context, radius: 12),
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
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
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

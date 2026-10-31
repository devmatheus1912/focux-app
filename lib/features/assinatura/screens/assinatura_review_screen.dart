import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/platform/secure_screen.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_link.dart';
import '../../../core/widgets/fx_conversion.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
import '../../../core/widgets/fx_screen_a11y.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/subscription_products.dart';
import '../utils/assinatura_review_display.dart';
import '../../../l10n/pt.dart';

/// Revisão honesta antes da compra na loja (App Store / Play compliant).
class AssinaturaReviewScreen extends StatefulWidget {
  final SubscriptionPlan plan;
  final SubscriptionBillingPeriod billingPeriod;
  final String priceDisplay;
  final int? trialDias;
  final String? indicacaoNota;

  const AssinaturaReviewScreen({
    super.key,
    required this.plan,
    required this.billingPeriod,
    required this.priceDisplay,
    this.trialDias,
    this.indicacaoNota,
  });

  @override
  State<AssinaturaReviewScreen> createState() => _AssinaturaReviewScreenState();
}

class _AssinaturaReviewScreenState extends State<AssinaturaReviewScreen> {
  var _detalhes = false;

  @override
  void initState() {
    super.initState();
    _enableSecureScreen();
  }

  @override
  void dispose() {
    _disableSecureScreen();
    super.dispose();
  }

  Future<void> _enableSecureScreen() async {
    if (kIsWeb) return;
    try {
      await SecureScreen.enable();
    } catch (_) {}
  }

  Future<void> _disableSecureScreen() async {
    if (kIsWeb) return;
    try {
      await SecureScreen.disable();
    } catch (_) {}
  }

  void _confirm() {
    HapticFeedback.mediumImpact();
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = chrome.ink;
    final mute = chrome.mute;
    final accent = BrandPalette.softened(
      PaywallCatalog.accentForPlan(widget.plan),
    );
    final price = widget.priceDisplay.trim();
    final linhas = assinaturaReviewLinhas(
      now: DateTime.now(),
      period: widget.billingPeriod,
      price: price,
      trialDias: widget.trialDias,
    );
    final planLabel = assinaturaReviewPlanLabel(widget.plan);

    return fxScreenA11yScope(
      label: assinaturaReviewTitle(),
      child: FxShellScaffold(
        useMesh: true,
        appBar: FxShellAppBar(
          title: assinaturaReviewTitle(),
          onBack: () {
            FxKeyboardDismissScope.dismiss();
            if (context.canPop()) {
              context.pop(false);
            } else {
              context.go('/assinatura');
            }
          },
        ),
        bottomNavigationBar:
            price.isEmpty
                ? null
                : SafeArea(
                  minimum: const EdgeInsets.fromLTRB(
                    TokensStrip.s5,
                    TokensStrip.s2,
                    TokensStrip.s5,
                    TokensStrip.s2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        button: true,
                        label: ptS.assinaturaConfirmarPlano(planLabel),
                        child: FxLiquidPrimaryButton(
                          label: assinaturaReviewConfirmLabel(
                            price: price,
                            trialDias: widget.trialDias,
                          ),
                          onPressed: _confirm,
                        ),
                      ),
                    ],
                  ),
                ),
        body:
            price.isEmpty
                ? FxEmptyState(
                  icon: 'dollar-sign',
                  title: assinaturaReviewEmptyTitle(),
                  subtitle: assinaturaReviewEmptySubtitle(),
                  action: FxEmptyAction(
                    label: assinaturaReviewBackLabel(),
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                )
                : ListView(
                  padding: const EdgeInsets.all(TokensStrip.s5),
                  children: [
                    Text(
                      planLabel,
                      style: TokensStrip.h1(color: ink),
                    ),
                    const SizedBox(height: TokensStrip.s4),
                    Container(
                      padding: const EdgeInsets.all(TokensStrip.s4),
                      decoration: chrome.accentPanel(accent: accent),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(price, style: TokensStrip.h1(color: ink)),
                          const SizedBox(height: TokensStrip.s3),
                          for (final (i, linha) in linhas.indexed) ...[
                            if (i > 0) const SizedBox(height: TokensStrip.s2),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    linha.quando,
                                    style: TokensStrip.body(
                                      color: i == 0 ? ink : mute,
                                    ).copyWith(
                                      fontWeight:
                                          i == 0 ? FontWeight.w700 : null,
                                    ),
                                  ),
                                ),
                                Text(
                                  linha.valor,
                                  style: TokensStrip.body(
                                    color: i == 0 ? ink : mute,
                                  ).copyWith(
                                    fontWeight:
                                        i == 0 ? FontWeight.w700 : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (widget.indicacaoNota case final nota?) ...[
                            const SizedBox(height: TokensStrip.s3),
                            Text(nota, style: TokensStrip.body(color: ink)),
                          ],
                          const SizedBox(height: TokensStrip.s3),
                          Text(
                            assinaturaReviewResumo(trialDias: widget.trialDias),
                            style: TokensStrip.bodyMuted(color: mute),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s5),
                    ...assinaturaReviewTopFeatures(widget.plan).map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: accent,
                            ),
                            const SizedBox(width: TokensStrip.s3),
                            Expanded(
                              child: Text(
                                feature,
                                style: TokensStrip.body(color: ink),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: TokensStrip.s3),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FxActionLink(
                        label: ptS.assinaturaDetalhesDaCobranca,
                        onTap: () => setState(() => _detalhes = !_detalhes),
                      ),
                    ),
                    if (_detalhes) ...[
                      const SizedBox(height: TokensStrip.s2),
                      Text(
                        assinaturaReviewLegalBody(
                          price: price,
                          period: widget.billingPeriod,
                        ),
                        style: TokensStrip.bodyMuted(
                          color: mute,
                        ).copyWith(height: 1.5),
                      ),
                    ],
                    const SizedBox(height: TokensStrip.s2),
                    Wrap(
                      spacing: TokensStrip.s3,
                      children: [
                        FxConversionTextLink(
                          text: '',
                          actionText: ptS.assinaturaPrivacidade,
                          onTap: () {
                            FocuxLegal.openPrivacy();
                          },
                        ),
                        FxConversionTextLink(
                          text: '',
                          actionText: ptS.assinaturaTermos2,
                          onTap: () {
                            FocuxLegal.openTerms();
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      height:
                          MediaQuery.paddingOf(context).bottom + TokensStrip.s4,
                    ),
                  ],
                ),
      ),
    );
  }
}

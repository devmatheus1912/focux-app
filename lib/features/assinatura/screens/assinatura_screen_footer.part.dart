part of 'assinatura_screen.dart';

class _EnterprisePreviewCard extends StatelessWidget {
  final EnterpriseUpgradePreview preview;
  final Color primary;
  final Color ink;
  final Color mute;
  final bool isDark;

  const _EnterprisePreviewCard({
    required this.preview,
    required this.primary,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(preview.planoDestino);
    final destLabel = PaywallCatalog.displayPlanName(preview.planoDestino);
    return PaywallGlassCard(
      accent: accent,
      padding: const EdgeInsets.all(14),
      blur: false,
      elevationLevel: 4,
      child: Text(
        preview.cobrancaImediata
            ? 'Upgrade para $destLabel: cobrança proporcional de R\$ ${preview.valorProporcional.toStringAsFixed(2)} (${preview.diasRestantes} dias restantes no ciclo).'
            : 'Upgrade para $destLabel sem cobrança proporcional imediata neste ciclo.',
        style: TokensStrip.body(color: ink),
      ),
    );
  }
}

class _EnterpriseProUpgradePriceHint extends StatelessWidget {
  final SubscriptionPlan currentPlan;
  final SubscriptionPlan targetPlan;
  final SubscriptionBillingPeriod billingPeriod;
  final Map<String, ProductDetails> productDetails;
  final Plano currentBackend;
  final Plano targetBackend;
  final Color primary;
  final Color ink;
  final Color mute;
  final bool isDark;

  const _EnterpriseProUpgradePriceHint({
    required this.currentPlan,
    required this.targetPlan,
    required this.billingPeriod,
    required this.productDetails,
    required this.currentBackend,
    required this.targetBackend,
    required this.primary,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  static String _formatBrl(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  String? _storeDeltaCopy() {
    final currentProduct =
        productDetails[SubscriptionProducts.productIdFor(
          currentPlan,
          billingPeriod,
        )];
    final targetProduct =
        productDetails[SubscriptionProducts.productIdFor(
          targetPlan,
          billingPeriod,
        )];
    if (currentProduct == null || targetProduct == null) return null;

    final currentRaw = currentProduct.rawPrice;
    final targetRaw = targetProduct.rawPrice;
    if (currentRaw <= 0 || targetRaw <= currentRaw) return null;

    final delta = targetRaw - currentRaw;
    final periodLabel =
        billingPeriod == SubscriptionBillingPeriod.yearly ? 'ano' : 'mês';
    final deltaLabel = delta.toStringAsFixed(2).replaceAll('.', ',');
    return 'Estimativa na ${subscriptionChannelLabel()}: +'
        '${targetProduct.currencySymbol}$deltaLabel/$periodLabel '
        'em relação ao seu plano atual. A loja confirma o valor final '
        'e o crédito proporcional do ciclo.';
  }

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(targetPlan);
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    final storeCopy = _storeDeltaCopy();
    final fallbackMonthly =
        targetBackend.precoMensal - currentBackend.precoMensal;
    final body =
        storeCopy ??
        (fallbackMonthly > 0
            ? 'Referência: +${_formatBrl(fallbackMonthly)}/mês. '
                'Valor final na ${subscriptionChannelLabel()}, '
                'com crédito proporcional se aplicável.'
            : 'Valor final na ${subscriptionChannelLabel()}, '
                'com crédito proporcional do ciclo se aplicável.');

    return PaywallInsetPanel(
      accent: accent,
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.payments_outlined, size: 18, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quanto custa o upgrade?',
                  style: FocuxHubTypography.cardTitle(color: ink)
                      .copyWith(height: 1.25),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TokensStrip.bodyMuted(
                    color: secondary,
                  ).copyWith(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _AssinaturaCtaMode {
  subscribe,
  manageStore,
  currentPlan,
  goHome,
  blocked,
  syncing,
}

class _AssinaturaStickyGlassBar extends StatelessWidget {
  final bool isDark;
  final Color line;
  final Widget child;

  const _AssinaturaStickyGlassBar({
    required this.isDark,
    required this.line,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = TokensStrip.prefersReducedMotion(context);
    final fill = DecoratedBox(
      decoration: BoxDecoration(
        color: TokensStrip.glassFill(
          dark: isDark,
          opacity: isDark ? 0.86 : 0.91,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.06 : 0.42),
            Colors.transparent,
          ],
        ),
      ),
      child: child,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: line.withValues(alpha: isDark ? 0.42 : 0.55)),
        ),
      ),
      child: ClipRect(
        child: reduceMotion
            ? fill
            : BackdropFilter(
              filter: TokensStrip.blurFilter(
                isDark ? TokensStrip.blurMedium : TokensStrip.blurLight,
              ),
              child: fill,
            ),
      ),
    );
  }
}

class _AssinaturaStickyFooter extends StatelessWidget {
  final _AssinaturaCtaMode mode;
  final String label;
  final String? planSummary;
  final String footnote;
  final bool enabled;
  final bool loading;
  final bool trialHint;
  final bool showLegalConsent;
  final bool isUpgrade;
  final Color? tierAccent;
  final Color ink;
  final Color mute;
  final Color line;
  final Color primary;
  final VoidCallback onSubscribe;
  final VoidCallback onManage;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onRestore;
  final bool restoringPurchases;
  final VoidCallback? onBillingDetails;

  const _AssinaturaStickyFooter({
    required this.mode,
    required this.label,
    this.planSummary,
    required this.footnote,
    required this.enabled,
    required this.loading,
    required this.trialHint,
    required this.showLegalConsent,
    this.isUpgrade = false,
    this.tierAccent,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.onSubscribe,
    required this.onManage,
    this.secondaryLabel,
    this.onSecondary,
    this.onRestore,
    this.restoringPurchases = false,
    this.onBillingDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = mute.withValues(alpha: isDark ? 0.78 : 0.72);
    final isActionable =
        mode == _AssinaturaCtaMode.subscribe ||
        mode == _AssinaturaCtaMode.syncing ||
        mode == _AssinaturaCtaMode.manageStore ||
        mode == _AssinaturaCtaMode.goHome;
    final onPressed =
        !enabled || loading || mode == _AssinaturaCtaMode.syncing
            ? null
            : mode == _AssinaturaCtaMode.subscribe
            ? onSubscribe
            : mode == _AssinaturaCtaMode.manageStore
            ? onManage
            : mode == _AssinaturaCtaMode.goHome
            ? onManage
            : null;

    IconData? icon;
    if (mode == _AssinaturaCtaMode.manageStore ||
        mode == _AssinaturaCtaMode.goHome) {
      icon = Icons.home_rounded;
    } else if (mode == _AssinaturaCtaMode.subscribe) {
      icon =
          trialHint
              ? Icons.card_giftcard_rounded
              : Icons.workspace_premium_rounded;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (planSummary != null) ...[
          Builder(
            builder: (context) {
              final parts = planSummary!.split(' · ');
              if (parts.length == 2) {
                return Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${parts[0]} · ',
                        style: TokensStrip.bodyMuted(color: secondary).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                      TextSpan(
                        text: parts[1],
                        style: TokensStrip.body(color: ink).copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Text(
                planSummary!,
                textAlign: TextAlign.center,
                style: TokensStrip.body(
                  color: ink,
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 14),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        if (trialHint) ...[
          Text(
            subscriptionUsesNativeStore
                ? 'Oferta introdutória aplicada pela loja ao concluir a assinatura.'
                : 'Cancele antes do fim do período gratuito para evitar cobrança.',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: secondary),
          ),
          const SizedBox(height: 8),
        ],
        if (secondaryLabel != null &&
            onSecondary != null &&
            mode == _AssinaturaCtaMode.manageStore) ...[
          FxLiquidSecondaryButton(
            label: secondaryLabel!,
            icon: Icons.workspace_premium_outlined,
            onPressed: onSecondary,
          ),
          const SizedBox(height: 8),
        ],
        if (isActionable)
          Semantics(
            button: true,
            label: label,
            liveRegion: mode == _AssinaturaCtaMode.syncing,
            child:
                tierAccent != null &&
                        mode == _AssinaturaCtaMode.subscribe &&
                        !TokensStrip.prefersReducedMotion(context)
                    ? DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          TokensStrip.rButton,
                        ),
                        border: Border.all(color: tierAccent!, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: tierAccent!.withValues(alpha: 0.28),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FxLiquidPrimaryButton(
                        label: label,
                        icon: icon,
                        loading: loading || mode == _AssinaturaCtaMode.syncing,
                        loadingLabel:
                            mode == _AssinaturaCtaMode.syncing
                                ? 'Sincronizando…'
                                : null,
                        onPressed: onPressed,
                      ),
                    )
                    : FxLiquidPrimaryButton(
                      label: label,
                      icon: icon,
                      loading: loading || mode == _AssinaturaCtaMode.syncing,
                      loadingLabel:
                          mode == _AssinaturaCtaMode.syncing
                              ? 'Sincronizando…'
                              : null,
                      onPressed: onPressed,
                    ),
          )
        else
          FxLiquidPrimaryButton(label: label, onPressed: null),
        if (footnote.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            footnote,
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(
              color: secondary,
            ).copyWith(fontSize: 12, height: 1.45),
          ),
        ],
        if (onBillingDetails != null || onRestore != null) ...[
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 0,
            children: [
              if (onBillingDetails != null)
                TextButton(
                  onPressed: onBillingDetails,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'Cobrança e termos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tierAccent ?? primary,
                    ),
                  ),
                ),
              if (onRestore != null)
                TextButton(
                  onPressed: restoringPurchases ? null : onRestore,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    restoringPurchases ? 'Restaurando…' : 'Restaurar compras',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tierAccent ?? primary,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (showLegalConsent) ...[
          const SizedBox(height: 8),
          _PaywallLegalConsentLine(
            ink: ink,
            mute: mute,
            primary: tierAccent ?? primary,
            isUpgrade: isUpgrade,
          ),
        ],
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatPrice(
  Plano plano,
  ProductDetails? productDetails,
  SubscriptionBillingPeriod period,
) {
  if (plano.precoMensal == 0) return 'Grátis';
  final suffix = period == SubscriptionBillingPeriod.yearly ? '/ano' : '/mês';
  if (productDetails != null) return '${productDetails.price}$suffix';
  if (period == SubscriptionBillingPeriod.yearly) {
    final annual = plano.annualPriceOrComputed();
    return 'R\$ ${annual.toStringAsFixed(2)}$suffix';
  }
  return 'R\$ ${plano.precoMensal.toStringAsFixed(2)}$suffix';
}

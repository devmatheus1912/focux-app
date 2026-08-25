part of 'assinatura_screen.dart';

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
  final bool showLegalConsent;
  final bool isUpgrade;
  final Color? tierAccent;
  final Color ink;
  final Color mute;
  final Color primary;
  final VoidCallback onSubscribe;
  final VoidCallback onManage;
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
    required this.showLegalConsent,
    this.isUpgrade = false,
    this.tierAccent,
    required this.ink,
    required this.mute,
    required this.primary,
    required this.onSubscribe,
    required this.onManage,
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
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (planSummary != null)
          Padding(
            padding: const EdgeInsets.only(bottom: TokensStrip.s2),
            child: Builder(
              builder: (context) {
                final parts = planSummary!.split(' · ');
                if (parts.length == 2) {
                  return Text.rich(
                    textAlign: TextAlign.center,
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${parts[0]} · ',
                          style: FocuxHubTypography.bodyMuted(
                            color: secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: parts[1],
                          style: FocuxHubTypography.cardTitle(color: ink),
                        ),
                      ],
                    ),
                  );
                }
                return Text(
                  planSummary!,
                  textAlign: TextAlign.center,
                  style: FocuxHubTypography.cardTitle(color: ink),
                );
              },
            ),
          ),
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
          const SizedBox(height: TokensStrip.s2),
          Text(
            footnote,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: FocuxHubTypography.bodyMuted(
              color: secondary,
              height: 1.35,
            ),
          ),
        ],
        if (onBillingDetails != null || onRestore != null) ...[
          const SizedBox(height: TokensStrip.s1),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: TokensStrip.s1,
            runSpacing: 0,
            children: [
              if (onBillingDetails != null)
                TextButton(
                  onPressed: onBillingDetails,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: TokensStrip.s2,
                    ),
                  ),
                  child: Text(
                    'Cobrança e termos',
                    style: FocuxHubTypography.chip(tierAccent ?? primary),
                  ),
                ),
              if (onRestore != null)
                TextButton(
                  onPressed: restoringPurchases ? null : onRestore,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: TokensStrip.s2,
                    ),
                  ),
                  child: Text(
                    restoringPurchases ? 'Restaurando…' : 'Restaurar compras',
                    style: FocuxHubTypography.chip(tierAccent ?? primary),
                  ),
                ),
            ],
          ),
        ],
        if (showLegalConsent) ...[
          const SizedBox(height: TokensStrip.s1),
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
  return buildPaywallPriceCopy(
    precoMensal: plano.precoMensal,
    precoAnual: plano.precoAnual,
    precoAnualMensalEquiv:
        plano.equivMensalNoAnual ?? plano.precoAnualMensalEquiv,
    labelDescontoAnual: plano.labelDescontoAnual,
    labelEconomiaAnual: plano.labelEconomiaAnual,
    period: period,
    storePrice: productDetails?.price,
  ).primary;
}

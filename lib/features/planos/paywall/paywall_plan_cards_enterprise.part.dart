part of 'paywall_components.dart';

class PaywallProExploreStrip extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool isDark;
  final VoidCallback onExplorePro;
  final String? roiTag;

  const PaywallProExploreStrip({
    super.key,
    required this.ink,
    required this.mute,
    required this.isDark,
    required this.onExplorePro,
    this.roiTag,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.brandDeep;
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    final tag = roiTag?.trim();
    final proAccent = PaywallCatalog.accentForPlan(
      SubscriptionPlan.ENTERPRISE_PRO,
    );
    return Semantics(
      button: true,
      label:
          'Landing, Loja digital e Pose Coach estão no Enterprise Pro. '
          '${tag != null && tag.isNotEmpty ? '$tag. ' : ''}'
          'Toque para ver o plano Pro',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onExplorePro();
          },
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TokensStrip.rSm),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        proAccent.withValues(alpha: isDark ? 0.14 : 0.08),
                        accent.withValues(alpha: isDark ? 0.06 : 0.03),
                      ],
                    ),
                  ),
                ),
              ),
              PaywallInsetPanel(
                accent: accent,
                isDark: isDark,
                child: Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 20,
                      color: accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Landing, Loja e Pose Coach estão no Enterprise Pro',
                        style: TokensStrip.body(
                          color: secondary,
                        ).copyWith(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (tag != null && tag.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: PaywallCatalog.green.withValues(
                            alpha: isDark ? 0.16 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(
                            TokensStrip.rPill,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                            color: PaywallCatalog.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Icon(Icons.chevron_right_rounded, color: accent, size: 22),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanSectionTitle extends StatelessWidget {
  final String title;
  final Color accent;
  final Color mute;
  final Color ink;

  const _PlanSectionTitle({
    required this.title,
    required this.accent,
    required this.mute,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    return Padding(
      padding: const EdgeInsets.only(
        top: TokensStrip.s3,
        bottom: TokensStrip.s2,
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: PaywallCatalog.readableTierAccent(
                accent,
                isDark: isDark,
              ).withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: FocuxHubTypography.chip(labelColor).copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String price;
  final Color accent;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _PriceBox({
    required this.label,
    required this.price,
    required this.accent,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    this.selected = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelected = selected && !disabled;
    final textInk = disabled ? mute.withValues(alpha: 0.55) : ink;

    final box = Opacity(
      opacity: disabled ? 0.5 : 1,
      child: FxGlassSurface(
        accent: accent,
        glow: effectiveSelected,
        blur: false,
        radius: TokensStrip.rSm,
        elevationLevel: effectiveSelected ? 8 : 3,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: FocuxHubTypography.bodyMuted(
                color: mute,
                fontWeight: FontWeight.w800,
              ).copyWith(letterSpacing: 0.8),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: FocuxHubTypography.metric(
                color: textInk,
                fontSize: FocuxHubTypography.metricLg,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null || disabled) return box;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $price',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: box,
        ),
      ),
    );
  }
}

/// Downgrade / plano gratuito — só consulta; mudança de tier na loja.
class _PlanReferenceStoreHint extends StatelessWidget {
  final SubscriptionPlan plan;
  final Color ink;
  final Color mute;
  final Color accent;
  final bool isDark;

  const _PlanReferenceStoreHint({
    required this.plan,
    required this.ink,
    required this.mute,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    final channel = subscriptionChannelLabel();
    final headline =
        plan == SubscriptionPlan.FREE
            ? 'Plano gratuito · referência'
            : 'Alteração só na $channel';
    final body =
        plan == SubscriptionPlan.FREE
            ? 'Compare limites com seu plano atual. Para voltar ao gratuito, use as assinaturas do dispositivo.'
            : 'Downgrade e cancelamento só na loja do dispositivo. '
                'Em Assinaturas, escolha o tier desejado.';

    return PaywallInsetPanel(
      accent: accent,
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            plan == SubscriptionPlan.FREE
                ? Icons.info_outline
                : Icons.storefront_outlined,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: FocuxHubTypography.cardTitle(
                    color: ink,
                  ).copyWith(height: 1.25),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  softWrap: true,
                  style: TokensStrip.bodyMuted(
                    color: secondary,
                  ).copyWith(fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Introdução do accordion «Outros planos» no Plan Studio.

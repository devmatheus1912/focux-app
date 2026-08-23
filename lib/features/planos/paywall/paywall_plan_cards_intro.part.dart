part of 'paywall_components.dart';

class PaywallOtherPlansIntro extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool isDark;

  const PaywallOtherPlansIntro({
    super.key,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: Text(
        'Planos abaixo são só para consulta. Seu plano ativo continua no card acima.',
        style: TokensStrip.bodyMuted(color: secondary).copyWith(fontSize: 13),
      ),
    );
  }
}

/// Status do plano atual dentro do [PaywallPlanStudio] — evita exibir preço R\$ 0.
class _StudioActiveStatusBanner extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color accent;
  final bool isDark;

  const _StudioActiveStatusBanner({
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
    return PaywallInsetPanel(
      accent: accent,
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_outlined, size: 20, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assinatura ativa',
                  style: FocuxHubTypography.sectionTitle(context, color: ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cobrança e renovação na ${subscriptionChannelLabel()}. '
                  'Valores exatos aparecem nas configurações da loja.',
                  style: TokensStrip.bodyMuted(
                    color: secondary,
                  ).copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreBillingHint extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool isDark;

  const _StoreBillingHint({
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return PaywallInsetPanel(
      accent: TokensStrip.primary,
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.storefront_outlined, size: 18, color: mute),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Preços e upgrade disponíveis na ${subscriptionChannelLabel()} '
              'deste dispositivo. Abra a loja para concluir.',
              style: TokensStrip.bodyMuted(
                color: PaywallCatalog.readableSecondary(
                  ink,
                  mute,
                  isDark: isDark,
                ),
              ).copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoiMoneyTag extends StatelessWidget {
  final String text;

  const _RoiMoneyTag({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PaywallInsetPanel(
      accent: PaywallCatalog.green,
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.savings_outlined,
            size: 16,
            color: PaywallCatalog.green,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: PaywallCatalog.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color paywallChipColorForLabel(String label) => switch (label) {
  'PREMIUM' => PaywallCatalog.brand,
  'ENTERPRISE' => PaywallCatalog.tierEnterprise,
  'ENT. PRO' => PaywallCatalog.brandDeep,
  _ => PaywallCatalog.brand,
};

class PaywallSectionHeader extends StatelessWidget {
  final String title;
  final String? note;
  final Color ink;
  final Color mute;

  const PaywallSectionHeader({
    super.key,
    required this.title,
    this.note,
    required this.ink,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    return Padding(
      padding: const EdgeInsets.only(
        top: TokensStrip.s1,
        bottom: TokensStrip.s3,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackNote = constraints.maxWidth < 400 && note != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stackNote) ...[
                Text(
                  title,
                  style: FocuxHubTypography.sectionTitle(context, color: ink),
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  note!,
                  style: TokensStrip.bodyMuted(
                    color: secondary,
                  ).copyWith(fontSize: TokensStrip.fontBodySm, height: 1.4),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: FocuxHubTypography.sectionTitle(
                          context,
                          color: ink,
                        ),
                      ),
                    ),
                    if (note != null) ...[
                      const SizedBox(width: TokensStrip.s3),
                      Flexible(
                        child: Text(
                          note!,
                          textAlign: TextAlign.end,
                          style: TokensStrip.bodyMuted(
                            color: secondary,
                          ).copyWith(
                            fontSize: TokensStrip.fontBodySm,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 10),
              Divider(height: 1, color: secondary.withValues(alpha: 0.35)),
            ],
          );
        },
      ),
    );
  }
}

/// Bloco recolhível — monta o filho só após a primeira expansão (performance).

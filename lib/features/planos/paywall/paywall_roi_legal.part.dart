part of 'paywall_components.dart';

/// Rodapé legal compacto no fluxo de upgrade — detalhes em bottom sheet.
class PaywallUpgradeLegalCompact extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color primary;
  final bool showStoreBillingNote;
  final bool restoring;
  final VoidCallback? onRestore;

  const PaywallUpgradeLegalCompact({
    super.key,
    required this.ink,
    required this.mute,
    required this.primary,
    this.showStoreBillingNote = true,
    this.restoring = false,
    this.onRestore,
  });

  static Future<void> showBillingSheet(
    BuildContext context, {
    required Color ink,
    required Color mute,
    required Color primary,
    required bool showStoreBillingNote,
    required bool restoring,
    VoidCallback? onRestore,
  }) {
    return showFxHomeSheet<void>(
      context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final maxHeight =
            MediaQuery.sizeOf(ctx).height * FxHomeSheetChrome.maxHeightFactor;
        return FxHomeSheetSurface(
          isDark: isDark,
          maxHeight: maxHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxHomeSheetHandle(isDark: isDark),
              SizedBox(height: TokensStrip.s4),
              FxHomeSheetHeader(
                isDark: isDark,
                title: 'Termos e cobrança',
                leading: Icon(Icons.policy_outlined, color: primary, size: 18),
              ),
              SizedBox(height: TokensStrip.s3),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PaywallTrustFooter(mute: mute, primary: primary),
                      const SizedBox(height: 16),
                      PaywallBillingLegalPanel(
                        ink: ink,
                        mute: mute,
                        showStoreBillingNote: showStoreBillingNote,
                        restoring: restoring,
                        onRestore: onRestore,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );

    return PaywallGlassCard(
      accent: primary,
      blur: false,
      glow: false,
      elevationLevel: 4,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Text(
            'Sem fidelidade · Cancele quando quiser',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(
              color: secondary,
            ).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Abrir termos, privacidade e informações de cobrança',
            child: TextButton.icon(
              onPressed:
                  () => showBillingSheet(
                    context,
                    ink: ink,
                    mute: mute,
                    primary: primary,
                    showStoreBillingNote: showStoreBillingNote,
                    restoring: restoring,
                    onRestore: onRestore,
                  ),
              icon: Icon(Icons.policy_outlined, size: 18, color: primary),
              label: Text(
                'Termos, privacidade e cobrança',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painel de cobrança / restaurar (sheet ou inline).
class PaywallBillingLegalPanel extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool showStoreBillingNote;
  final bool restoring;
  final VoidCallback? onRestore;

  const PaywallBillingLegalPanel({
    super.key,
    required this.ink,
    required this.mute,
    this.showStoreBillingNote = true,
    this.restoring = false,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );

    return Column(
      children: [
        if (onRestore != null)
          TextButton(
            onPressed: restoring ? null : onRestore,
            child: Text(
              restoring ? 'Restaurando compras…' : 'Restaurar compras',
              style: TextStyle(
                fontSize: 14,
                color: ink.withValues(alpha: 0.82),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (showStoreBillingNote)
          Text(
            'Cobrança e renovação automática pela ${subscriptionChannelLabel()}. '
            'Cancele quando quiser nas configurações do dispositivo.',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: secondary),
          ),
      ],
    );
  }
}

class PaywallTrustFooter extends StatelessWidget {
  final Color mute;
  final Color primary;

  const PaywallTrustFooter({
    super.key,
    required this.mute,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle link() => TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: primary,
      decoration: TextDecoration.underline,
    );
    final linkStyle = TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
    return Column(
      children: [
        Text(
          'Sem fidelidade · Cancele quando quiser nas configurações do app',
          textAlign: TextAlign.center,
          style: TokensStrip.bodyMuted(color: mute),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 0,
          children: [
            Semantics(
              button: true,
              label: 'Abrir política de privacidade',
              child: TextButton(
                onPressed: () => FocuxLegal.openPrivacy(),
                style: linkStyle,
                child: Text('Privacidade (LGPD)', style: link()),
              ),
            ),
            Semantics(
              button: true,
              label: 'Abrir termos de uso',
              child: TextButton(
                onPressed: () => FocuxLegal.openTerms(),
                style: linkStyle,
                child: Text('Termos de uso', style: link()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PaywallLoadingSkeleton extends StatelessWidget {
  const PaywallLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? EagleTokens.darkCard : EagleTokens.lineSoft;
    final highlight = isDark ? EagleTokens.darkCardHi : EagleTokens.line;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++)
            Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(TokensStrip.rCard),
              ),
            ),
        ],
      ),
    );
  }
}

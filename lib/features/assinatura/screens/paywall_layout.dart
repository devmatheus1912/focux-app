part of 'assinatura_screen.dart';

// ─── Paywall Focux — conversão (10/10) ─────────────────────────────────────

Color _paywallSecondaryText(Color mute, {required bool isDark}) =>
    mute.withValues(alpha: isDark ? 0.78 : 0.72);

Duration _paywallMotion(BuildContext context) =>
    TokensStrip.prefersReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

class _PaywallBillingSegment extends StatelessWidget {
  final SubscriptionBillingPeriod period;
  final Color ink;
  final Color mute;
  final Color line;
  final Color primary;
  final bool isDark;
  final String annualSavingsLabel;
  final ValueChanged<SubscriptionBillingPeriod> onChanged;

  const _PaywallBillingSegment({
    required this.period,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.isDark,
    required this.annualSavingsLabel,
    required this.onChanged,
  });

  static const double _segmentHeight = 52;
  static const double _subtextSlotHeight = 14;
  static const double _trackRadius = 14;
  static const double _trackInset = 4;
  static const double _thumbInset = 3;

  BorderRadius _thumbBorderRadius(SubscriptionBillingPeriod value) {
    const inner = Radius.circular(9);
    const outer = Radius.circular(_trackRadius - _trackInset - _thumbInset);
    if (value == SubscriptionBillingPeriod.yearly) {
      return BorderRadius.only(
        topLeft: outer,
        bottomLeft: outer,
        topRight: inner,
        bottomRight: inner,
      );
    }
    return BorderRadius.only(
      topRight: outer,
      bottomRight: outer,
      topLeft: inner,
      bottomLeft: inner,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final clipRadius = _trackRadius - _trackInset;
    final motion = _paywallMotion(context);
    final secondary = _paywallSecondaryText(mute, isDark: isDark);

    Widget segmentTap({
      required SubscriptionBillingPeriod value,
      required String label,
      String? subtitle,
    }) {
      final selected = period == value;
      final subtitleColor = selected ? primary : secondary;

      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: subtitle == null ? label : '$label, $subtitle',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(value),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: selected ? ink : mute,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: _subtextSlotHeight,
                    child: Center(
                      child: Text(
                        subtitle ?? '',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: subtitle == null ? Colors.transparent : subtitleColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final thumbFill =
        isDark
            ? Color.alphaBlend(
              primary.withValues(alpha: 0.18),
              TokensStrip.cinematicElevated,
            )
            : Colors.white;
    final thumbBorder =
        isDark
            ? primary.withValues(alpha: 0.62)
            : primary.withValues(alpha: 0.38);
    final thumbShadow =
        isDark
            ? TokensStrip.interactiveGlow(primary, intensity: 0.5, dark: true)
            : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: primary.withValues(alpha: 0.12),
                blurRadius: 6,
              ),
            ];

    final trackDecoration =
        isDark
            ? BoxDecoration(
              color: EagleTokens.darkLine.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(_trackRadius),
              border: Border.all(
                color: primary.withValues(alpha: 0.30),
              ),
            )
            : chrome.panel(
              radius: _trackRadius,
              accent: primary.withValues(alpha: 0.35),
              elevationLevel: 1,
            );

    return Container(
      decoration: trackDecoration,
      padding: const EdgeInsets.all(_trackInset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(clipRadius),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackW = constraints.maxWidth;
            final thumbW = (trackW - _thumbInset * 2) / 2;
            final thumbLeft =
                period == SubscriptionBillingPeriod.yearly
                    ? _thumbInset
                    : _thumbInset + thumbW;

            return SizedBox(
              height: _segmentHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  AnimatedPositioned(
                    duration: motion,
                    curve: Curves.easeOutCubic,
                    left: thumbLeft,
                    top: _thumbInset,
                    bottom: _thumbInset,
                    width: thumbW,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: thumbFill,
                        borderRadius: _thumbBorderRadius(period),
                        border: Border.all(color: thumbBorder, width: 1.2),
                        boxShadow: thumbShadow,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      segmentTap(
                        value: SubscriptionBillingPeriod.yearly,
                        label: 'Anual',
                        subtitle: annualSavingsLabel,
                      ),
                      segmentTap(
                        value: SubscriptionBillingPeriod.monthly,
                        label: 'Mensal',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PaywallUpgradeNudge extends StatelessWidget {
  final Color primary;
  final Color ink;
  final bool isDark;

  const _PaywallUpgradeNudge({
    required this.primary,
    required this.ink,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: chrome.panel(
        radius: TokensStrip.rCard,
        accent: primary,
        elevationLevel: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.rocket_launch_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Upgrade recomendado: ${PlanoIaLimits.enterprise} IA/mês, white-label e alunos ilimitados no Enterprise.',
              style: TokensStrip.body(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallFeaturePanel extends StatelessWidget {
  final Plano plano;
  final SubscriptionPlan plan;
  final SubscriptionPlan currentPlan;
  final Color ink;
  final Color mute;
  final Color line;
  final Color primary;
  final bool isDark;

  const _PaywallFeaturePanel({
    required this.plano,
    required this.plan,
    required this.currentPlan,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.isDark,
  });

  List<({String label, bool included})> get _rows => [
    (
      label:
          plano.limiteAlunos == null
              ? 'Alunos ilimitados'
              : 'Até ${plano.limiteAlunos} alunos',
      included: true,
    ),
    if (plan != SubscriptionPlan.FREE)
      (
        label: plan == SubscriptionPlan.PREMIUM
            ? '${PlanoIaLimits.premium} interações de IA/mês'
            : '${PlanoIaLimits.enterprise}+ interações de IA/mês',
        included: true,
      ),
    if (plan == SubscriptionPlan.ENTERPRISE_PRO)
      (
        label: '${MigracaoFotoLimits.enterprise} fotos de migração/mês',
        included: true,
      ),
    (label: 'IA Copiloto avançada', included: plan != SubscriptionPlan.FREE),
    (label: 'Financeiro e CRM', included: plano.temFinanceiro),
    (label: 'Agenda e relatórios', included: plano.temAgenda && plano.temRelatorios),
    (label: 'White-label e identidade visual', included: plano.temWhiteLabel),
    if (plan == SubscriptionPlan.ENTERPRISE_PRO)
      (label: 'Landing page COMPLETA', included: plano.temLandingCompleta),
  ];

  @override
  Widget build(BuildContext context) {
    final comparing = plan != currentPlan && currentPlan != SubscriptionPlan.FREE;
    final motion = _paywallMotion(context);
    final secondary = _paywallSecondaryText(mute, isDark: isDark);

    return AnimatedSwitcher(
      duration: motion,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Column(
        key: ValueKey(plan.apiName),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text(
          'O que inclui ${PaywallCatalog.displayPlanName(plan)}',
          style: TokensStrip.h2(
            color: ink,
            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
          ).copyWith(fontSize: 17),
        ),
          if (comparing) ...[
            const SizedBox(height: 6),
            Text(
            'Comparando com o ${PaywallCatalog.displayPlanName(currentPlan)} que você usa hoje.',
            style: TokensStrip.bodyMuted(color: secondary),
            ),
          ],
          const SizedBox(height: 14),
          ..._rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    row.included ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 20,
                    color:
                        row.included
                            ? primary
                            : mute.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.label,
                    style: TokensStrip.body(
                      color: row.included ? ink : mute.withValues(alpha: 0.5),
                    ).copyWith(
                      decoration:
                          row.included ? null : TextDecoration.lineThrough,
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 14, color: primary.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subscriptionUsesNativeStore
                      ? 'Pagamento seguro · Cancele quando quiser · ${subscriptionChannelLabel()}'
                      : 'Checkout seguro via Mercado Pago',
                style: TokensStrip.bodyMuted(color: secondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaywallInlineNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color ink;
  final Color mute;
  final bool isDark;

  const _PaywallInlineNote({
    required this.icon,
    required this.text,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: chrome.panel(radius: TokensStrip.rCard, elevationLevel: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: mute),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: ink.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallLegalConsentLine extends StatelessWidget {
  final Color mute;
  final Color primary;

  const _PaywallLegalConsentLine({
    required this.mute,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    TextStyle linkStyle() => TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: primary,
      decoration: TextDecoration.underline,
      decorationColor: primary.withValues(alpha: 0.45),
      height: 1.35,
    );
    final body = TokensStrip.bodyMuted(
      color: _paywallSecondaryText(mute, isDark: isDark),
    ).copyWith(fontSize: 11);

    return Semantics(
      label:
          'Ao assinar, você concorda com os Termos de uso e a Política de privacidade',
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 0,
        runSpacing: 2,
        children: [
          Text('Ao assinar, concorda com os ', style: body),
          Semantics(
            button: true,
            label: 'Abrir termos de uso',
            child: GestureDetector(
              onTap: () => FocuxLegal.openTerms(),
              child: Text('Termos', style: linkStyle()),
            ),
          ),
          Text(' e a ', style: body),
          Semantics(
            button: true,
            label: 'Abrir política de privacidade',
            child: GestureDetector(
              onTap: () => FocuxLegal.openPrivacy(),
              child: Text('Privacidade', style: linkStyle()),
            ),
          ),
          Text('.', style: body),
        ],
      ),
    );
  }
}

class _PaywallLegalFooter extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool showStoreBillingNote;
  final bool restoring;
  final VoidCallback? onRestore;

  const _PaywallLegalFooter({
    required this.ink,
    required this.mute,
    required this.showStoreBillingNote,
    required this.restoring,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = _paywallSecondaryText(mute, isDark: isDark);

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
        if (showStoreBillingNote) ...[
          Text(
            'Cobrança e renovação automática pela ${subscriptionChannelLabel()}. Cancele quando quiser nas configurações do dispositivo.',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: secondary),
          ),
        ],
      ],
    );
  }
}

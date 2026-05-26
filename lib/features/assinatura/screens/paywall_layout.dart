part of 'assinatura_screen.dart';

// ─── Paywall Claude + conversão Focux (10/10) ─────────────────────────────

Color _paywallSecondaryText(Color mute, {required bool isDark}) =>
    mute.withValues(alpha: isDark ? 0.78 : 0.72);

Duration _paywallMotion(BuildContext context) =>
    TokensStrip.prefersReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

class _PaywallHeader extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color primary;
  final SubscriptionPlan currentPlan;
  final SubscriptionPlan selectedPlan;

  const _PaywallHeader({
    required this.ink,
    required this.mute,
    required this.primary,
    required this.currentPlan,
    required this.selectedPlan,
  });

  @override
  Widget build(BuildContext context) {
    final comparing = selectedPlan != currentPlan;
    final title = switch (currentPlan) {
      SubscriptionPlan.ENTERPRISE => 'Gerencie seu plano',
      SubscriptionPlan.PREMIUM => 'Escale sua operação',
      _ => 'Escolha seu plano',
    };
    final subtitle = switch (currentPlan) {
      SubscriptionPlan.ENTERPRISE =>
        comparing
            ? 'Você usa ${currentPlan.apiName} hoje. Toque em outro plano para comparar — renovação e cancelamento ficam na loja.'
            : 'Renovação automática e troca mensal/anual na ${subscriptionChannelLabel()}.',
      SubscriptionPlan.PREMIUM =>
        comparing
            ? 'Plano ${currentPlan.apiName} ativo. Veja o que muda ao evoluir para Enterprise.'
            : 'Desbloqueie mais IA, alunos ilimitados e white-label no Enterprise.',
      _ =>
        'IA Copiloto, financeiro e treinos em um fluxo seguro pela ${subscriptionChannelLabel()}.',
    };

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (currentPlan != SubscriptionPlan.FREE) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary.withValues(alpha: 0.22)),
              ),
              child: Text(
                'Seu plano: ${currentPlan.apiName}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            title,
            style: TokensStrip.h2(
              color: ink,
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TokensStrip.bodyMuted(
              color: mute,
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

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

class _PaywallPlanOptionTile extends StatelessWidget {
  final Plano plano;
  final SubscriptionPlan plan;
  final bool isSelected;
  final bool isCurrent;
  final SubscriptionBillingPeriod billingPeriod;
  final String priceLabel;
  final String? monthlyEquiv;
  final String? yearlySavingsNote;
  final String subtitle;
  final Color ink;
  final Color mute;
  final Color line;
  final Color primary;
  final bool isDark;
  final VoidCallback onTap;

  const _PaywallPlanOptionTile({
    required this.plano,
    required this.plan,
    required this.isSelected,
    required this.isCurrent,
    required this.billingPeriod,
    required this.priceLabel,
    this.monthlyEquiv,
    this.yearlySavingsNote,
    required this.subtitle,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final motion = _paywallMotion(context);
    final reduceMotion = motion == Duration.zero;
    final secondary = _paywallSecondaryText(mute, isDark: isDark);
    final priceOnly = priceLabel.replaceAll('/mês', '').replaceAll('/ano', '');
    final suffix =
        billingPeriod == SubscriptionBillingPeriod.yearly ? '/ano' : '/mês';
    final cardDecoration = chrome.listCard(
      selected: isSelected,
      primary: primary,
      radius: TokensStrip.rCard,
    );
    final priceStyle = TokensStrip.h2(color: ink).copyWith(fontSize: 18);
    final suffixStyle = TokensStrip.bodyMuted(color: secondary).copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    final semanticsPrice = [
      priceLabel,
      if (yearlySavingsNote != null && yearlySavingsNote!.isNotEmpty)
        yearlySavingsNote,
      if (monthlyEquiv != null) 'comparado com $monthlyEquiv',
    ].join(', ');

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          'Plano ${plan.apiName}${isCurrent ? ', plano atual' : ''}, '
          '$semanticsPrice. $subtitle',
      child: AnimatedScale(
        scale: isSelected || reduceMotion ? 1 : 0.985,
        duration: motion,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: motion,
          curve: Curves.easeOutCubic,
          decoration: cardDecoration,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PaywallRadio(
                      selected: isSelected,
                      primary: primary,
                      line: line,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                plan.apiName,
                                style: TokensStrip.h2(
                                  color: ink,
                                  fontFamily:
                                      Theme.of(context).textTheme.bodyLarge?.fontFamily,
                                ).copyWith(fontSize: 18),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Atual',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TokensStrip.bodyMuted(color: mute),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(text: priceOnly, style: priceStyle),
                                  TextSpan(text: suffix, style: suffixStyle),
                                ],
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                          if (yearlySavingsNote != null &&
                              yearlySavingsNote!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              yearlySavingsNote!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: primary,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaywallRadio extends StatelessWidget {
  final bool selected;
  final Color primary;
  final Color line;

  const _PaywallRadio({
    required this.selected,
    required this.primary,
    required this.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      margin: const EdgeInsets.only(top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? primary : line,
          width: selected ? 2 : 1.5,
        ),
      ),
      child:
          selected
              ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                  ),
                ),
              )
              : null,
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
        label: plan == SubscriptionPlan.ENTERPRISE
            ? '${PlanoIaLimits.enterprise} interações de IA/mês'
            : '${PlanoIaLimits.premium} interações de IA/mês',
        included: true,
      ),
    if (plan != SubscriptionPlan.FREE)
      (
        label: plan == SubscriptionPlan.ENTERPRISE
            ? '${MigracaoFotoLimits.enterprise} fotos de migração/mês'
            : '${MigracaoFotoLimits.premium} fotos de migração/mês',
        included: true,
      ),
    (label: 'IA Copiloto avançada', included: plan != SubscriptionPlan.FREE),
    (label: 'Financeiro e CRM', included: plano.temFinanceiro),
    (label: 'Agenda e relatórios', included: plano.temAgenda && plano.temRelatorios),
    (label: 'White-label e identidade visual', included: plano.temWhiteLabel),
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
          'O que inclui ${plan.apiName}',
          style: TokensStrip.h2(
            color: ink,
            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
          ).copyWith(fontSize: 17),
        ),
          if (comparing) ...[
            const SizedBox(height: 6),
            Text(
            'Comparando com o ${currentPlan.apiName} que você usa hoje.',
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

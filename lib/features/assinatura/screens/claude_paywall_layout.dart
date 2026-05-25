part of 'assinatura_screen.dart';

// ─── Paywall Claude + conversão Focux (10/10) ─────────────────────────────

class _ClaudePaywallHeader extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color primary;
  final SubscriptionPlan currentPlan;
  final SubscriptionPlan selectedPlan;

  const _ClaudePaywallHeader({
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
            : 'Desbloqueie mais alunos, white-label e automações com Enterprise.',
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

class _ClaudeBillingSegment extends StatelessWidget {
  final SubscriptionBillingPeriod period;
  final Color ink;
  final Color mute;
  final Color line;
  final Color primary;
  final bool isDark;
  final String annualSavingsLabel;
  final ValueChanged<SubscriptionBillingPeriod> onChanged;

  const _ClaudeBillingSegment({
    required this.period,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.isDark,
    required this.annualSavingsLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);

    Widget segment(SubscriptionBillingPeriod value, String label) {
      final selected = period == value;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color:
                    selected
                        ? chrome.cardFill
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border:
                    selected
                        ? Border.all(color: line.withValues(alpha: 0.35))
                        : null,
              ),
              child: Column(
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? ink : mute,
                    ),
                  ),
                  if (value == SubscriptionBillingPeriod.yearly) ...[
                    const SizedBox(height: 2),
                    Text(
                      annualSavingsLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: selected ? primary : EagleTokens.good,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: chrome.panel(
        radius: TokensStrip.rButton,
        accent: primary.withValues(alpha: 0.35),
        elevationLevel: 1,
      ),
      child: Row(
        children: [
          segment(SubscriptionBillingPeriod.yearly, 'Anual'),
          segment(SubscriptionBillingPeriod.monthly, 'Mensal'),
        ],
      ),
    );
  }
}

class _ClaudePlanOptionTile extends StatelessWidget {
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

  const _ClaudePlanOptionTile({
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
    final priceOnly = priceLabel.replaceAll('/mês', '').replaceAll('/ano', '');
    final suffix =
        billingPeriod == SubscriptionBillingPeriod.yearly ? '/ano' : '/mês';
    final cardDecoration = chrome.listCard(
      selected: isSelected,
      primary: primary,
      radius: TokensStrip.rCard,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Plano ${plan.apiName}, $priceLabel',
      child: AnimatedScale(
        scale: isSelected ? 1 : 0.985,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
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
                    _ClaudeRadio(
                      selected: isSelected,
                      primary: primary,
                      line: line,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                          Text(
                            plan.apiName,
                            style: TokensStrip.h2(
                              color: ink,
                              fontFamily:
                                  Theme.of(context).textTheme.bodyLarge?.fontFamily,
                            ).copyWith(fontSize: 18),
                          ),
                              if (isCurrent) ...[
                                const SizedBox(width: 8),
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
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                    Text(
                      priceOnly,
                      style: TokensStrip.h2(color: ink).copyWith(fontSize: 18),
                    ),
                    Text(
                      suffix,
                      style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 12),
                    ),
                        if (billingPeriod ==
                            SubscriptionBillingPeriod.yearly) ...[
                          if (yearlySavingsNote != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              yearlySavingsNote!,
                              style: TextStyle(
                                fontSize: 10,
                                color: primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          if (monthlyEquiv != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'vs $monthlyEquiv',
                              style: TextStyle(
                                fontSize: 11,
                                color: ink.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ],
                      ],
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

class _ClaudeRadio extends StatelessWidget {
  final bool selected;
  final Color primary;
  final Color line;

  const _ClaudeRadio({
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

class _ClaudeUpgradeNudge extends StatelessWidget {
  final Color primary;
  final Color ink;
  final bool isDark;

  const _ClaudeUpgradeNudge({
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
              'Upgrade recomendado: alunos ilimitados, white-label e domínio próprio no Enterprise.',
              style: TokensStrip.body(color: ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClaudeFeaturePanel extends StatelessWidget {
  final Plano plano;
  final SubscriptionPlan plan;
  final SubscriptionPlan currentPlan;
  final Color ink;
  final Color mute;
  final Color line;
  final Color primary;
  final bool isDark;

  const _ClaudeFeaturePanel({
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
    (label: 'IA Copiloto avançada', included: plan != SubscriptionPlan.FREE),
    (label: 'Financeiro e CRM', included: plano.temFinanceiro),
    (label: 'Agenda e relatórios', included: plano.temAgenda && plano.temRelatorios),
    (label: 'White-label e domínio', included: plano.temWhiteLabel),
  ];

  @override
  Widget build(BuildContext context) {
    final comparing = plan != currentPlan && currentPlan != SubscriptionPlan.FREE;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
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
            style: TokensStrip.bodyMuted(color: mute),
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
                style: TokensStrip.bodyMuted(color: mute),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClaudeInlineNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color ink;
  final Color mute;
  final bool isDark;
  final VoidCallback? onTap;
  final String? actionLabel;

  const _ClaudeInlineNote({
    required this.icon,
    required this.text,
    required this.ink,
    required this.mute,
    required this.isDark,
    this.onTap,
    this.actionLabel,
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
          if (onTap != null && actionLabel != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _ClaudeLegalConsentLine extends StatelessWidget {
  final Color mute;
  final Color primary;

  const _ClaudeLegalConsentLine({
    required this.mute,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    TextStyle linkStyle() => TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: primary,
      decoration: TextDecoration.underline,
      decorationColor: primary.withValues(alpha: 0.45),
      height: 1.35,
    );
    final body = TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 11);

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

class _ClaudeLegalFooter extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool showStoreBillingNote;
  final bool restoring;
  final VoidCallback? onRestore;

  const _ClaudeLegalFooter({
    required this.ink,
    required this.mute,
    required this.showStoreBillingNote,
    required this.restoring,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onRestore != null)
          TextButton(
            onPressed: restoring ? null : onRestore,
            child: Text(
              restoring ? 'Restaurando compras…' : 'Restaurar compras',
              style: TextStyle(
                fontSize: 14,
                color: ink.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (showStoreBillingNote) ...[
          Text(
            'Cobrança e renovação automática pela ${subscriptionChannelLabel()}. Cancele quando quiser nas configurações do dispositivo.',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: mute),
          ),
        ],
      ],
    );
  }
}

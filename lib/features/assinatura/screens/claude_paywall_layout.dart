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
            style: AppTypography.inter(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
              height: 1.15,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: ink.withValues(alpha: 0.68),
              fontWeight: FontWeight.w400,
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
  final ValueChanged<SubscriptionBillingPeriod> onChanged;

  const _ClaudeBillingSegment({
    required this.period,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final track =
        isDark ? EagleTokens.darkCardHi : const Color(0xFFEBEBEB);

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
                        ? (isDark ? EagleTokens.darkCard : Colors.white)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow:
                    selected && !isDark
                        ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
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
                      'Economize 20%',
                      style: TextStyle(
                        fontSize: 11,
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
      decoration: BoxDecoration(
        color: track,
        borderRadius: BorderRadius.circular(14),
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
    final card = isDark ? EagleTokens.darkCard : Colors.white;
    final priceOnly = priceLabel.replaceAll('/mês', '').replaceAll('/ano', '');
    final suffix =
        billingPeriod == SubscriptionBillingPeriod.yearly ? '/ano' : '/mês';

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
          decoration: BoxDecoration(
            color:
                isSelected
                    ? primary.withValues(alpha: isDark ? 0.14 : 0.06)
                    : card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primary : line,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow:
                isSelected && !isDark
                    ? [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                    : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
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
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: ink,
                                  letterSpacing: -0.2,
                                ),
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
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: ink.withValues(alpha: 0.62),
                            ),
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
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          suffix,
                          style: TextStyle(
                            fontSize: 12,
                            color: ink.withValues(alpha: 0.55),
                          ),
                        ),
                        if (billingPeriod ==
                                SubscriptionBillingPeriod.yearly &&
                            monthlyEquiv != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'vs $monthlyEquiv',
                            style: TextStyle(
                              fontSize: 11,
                              color: primary.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.14),
            primary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.rocket_launch_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Upgrade recomendado: alunos ilimitados, white-label e domínio próprio no Enterprise.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: ink.withValues(alpha: 0.88),
              ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'O que inclui ${plan.apiName}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: ink,
            letterSpacing: -0.2,
          ),
        ),
        if (comparing) ...[
          const SizedBox(height: 6),
          Text(
            'Comparando com o ${currentPlan.apiName} que você usa hoje.',
            style: TextStyle(fontSize: 13, color: mute, height: 1.4),
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
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color:
                          row.included
                              ? ink
                              : mute.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w400,
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
                style: TextStyle(
                  fontSize: 12,
                  color: ink.withValues(alpha: 0.55),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
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
    final bg = isDark ? EagleTokens.darkCardHi : EagleTokens.paper;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? EagleTokens.darkLine : EagleTokens.lineSoft,
        ),
      ),
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

class _ClaudeLegalFooter extends StatelessWidget {
  final Color mute;
  final bool restoring;
  final VoidCallback? onRestore;

  const _ClaudeLegalFooter({
    required this.mute,
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
                color: mute,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Text(
          'Cobrança pela loja do dispositivo. Renovação automática até você cancelar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.45,
            color: mute.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

part of 'assinatura_screen.dart';

// ─── Layout estilo Claude app (minimal, radio cards, fundo plano) ───────────

class _ClaudePaywallHeader extends StatelessWidget {
  final Color ink;
  final Color mute;
  final SubscriptionPlan currentPlan;

  const _ClaudePaywallHeader({
    required this.ink,
    required this.mute,
    required this.currentPlan,
  });

  @override
  Widget build(BuildContext context) {
    final title = switch (currentPlan) {
      SubscriptionPlan.ENTERPRISE => 'Gerencie seu plano',
      SubscriptionPlan.PREMIUM => 'Atualize seu plano',
      _ => 'Escolha um plano',
    };
    final subtitle = switch (currentPlan) {
      SubscriptionPlan.ENTERPRISE =>
        'Você está no ${currentPlan.apiName}. Compare opções ou altere a renovação na loja.',
      SubscriptionPlan.PREMIUM =>
        'Você está no ${currentPlan.apiName}. Veja o que cada nível inclui.',
      _ =>
        'Mais alunos, IA Copiloto e ferramentas para escalar sua consultoria.',
    };

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              color: mute,
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
  final bool isDark;
  final ValueChanged<SubscriptionBillingPeriod> onChanged;

  const _ClaudeBillingSegment({
    required this.period,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final track =
        isDark
            ? EagleTokens.darkCardHi
            : const Color(0xFFEBEBEB);

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
                color: selected ? (isDark ? EagleTokens.darkCard : Colors.white) : Colors.transparent,
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
                        fontWeight: FontWeight.w600,
                        color: selected ? EagleTokens.good : mute,
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
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? EagleTokens.darkCard : Colors.white;
    final borderColor = isSelected ? ink : line;
    final priceOnly = priceLabel.replaceAll('/mês', '').replaceAll('/ano', '');
    final suffix =
        billingPeriod == SubscriptionBillingPeriod.yearly ? '/ano' : '/mês';

    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Plano ${plan.apiName}, $priceLabel',
      child: Material(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor, width: isSelected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ClaudeRadio(selected: isSelected, ink: ink, line: line),
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
                                color: ink.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Atual',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ink.withValues(alpha: 0.75),
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
                          color: mute,
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
                      style: TextStyle(fontSize: 12, color: mute),
                    ),
                    if (billingPeriod == SubscriptionBillingPeriod.yearly &&
                        monthlyEquiv != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'vs $monthlyEquiv',
                        style: TextStyle(fontSize: 11, color: mute),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClaudeRadio extends StatelessWidget {
  final bool selected;
  final Color ink;
  final Color line;

  const _ClaudeRadio({
    required this.selected,
    required this.ink,
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
        border: Border.all(color: selected ? ink : line, width: 2),
      ),
      child:
          selected
              ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: ink),
                ),
              )
              : null,
    );
  }
}

class _ClaudeFeaturePanel extends StatelessWidget {
  final Plano plano;
  final SubscriptionPlan plan;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const _ClaudeFeaturePanel({
    required this.plano,
    required this.plan,
    required this.ink,
    required this.mute,
    required this.line,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Incluído em ${plan.apiName}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: mute,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        ..._rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  row.included ? Icons.check : Icons.close,
                  size: 18,
                  color: row.included ? ink : mute.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    row.label,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: row.included ? ink : mute.withValues(alpha: 0.55),
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
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 14, color: mute),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                subscriptionUsesNativeStore
                    ? 'Pagamento seguro · Cancele quando quiser · ${subscriptionChannelLabel()}'
                    : 'Checkout seguro via Mercado Pago',
                style: TextStyle(fontSize: 12, color: mute, height: 1.4),
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
              style: TextStyle(fontSize: 13, height: 1.45, color: ink.withValues(alpha: 0.85)),
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
              style: TextStyle(fontSize: 14, color: mute, fontWeight: FontWeight.w500),
            ),
          ),
        Text(
          'A cobrança é processada pela loja do dispositivo. Renovação automática até cancelar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, height: 1.45, color: mute.withValues(alpha: 0.9)),
        ),
      ],
    );
  }
}

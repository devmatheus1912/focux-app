part of 'assinatura_screen.dart';

// ─── Paywall Focux — funil IAP mobile ───────────────────────────────────────

Color _paywallSecondaryText(Color mute, {required bool isDark}) =>
    mute.withValues(alpha: isDark ? 0.78 : 0.72);

Duration _paywallMotion(BuildContext context) =>
    TokensStrip.prefersReducedMotion(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);

List<({String label, bool included})> _paywallFeatureRowsWithUsage(
  Plano plano,
  SubscriptionPlan plan,
  PlanoFeatures? usage,
) {
  final rows = _paywallFeatureRows(plano, plan);
  if (usage == null) return rows;

  return [
    for (final row in rows)
      if (row.included && (row.label.startsWith('Até') || row.label.contains('ilimitados')))
        (
          label:
              usage.limiteAlunos == null
                  ? '${usage.alunosAtivos} alunos ativos · ilimitados'
                  : '${usage.alunosAtivos} de ${usage.limiteAlunos} alunos ativos',
          included: true,
        )
      else if (row.included && row.label.contains('interações de IA'))
        (
          label:
              usage.limiteIaMensal == null || (usage.limiteIaMensal ?? 0) <= 0
                  ? row.label
                  : 'IA: ${usage.iaUsadaMes} de ${usage.limiteIaMensal} este mês',
          included: true,
        )
      else if (row.included && row.label.contains('fotos de migração'))
        (
          label:
              usage.limiteMigracaoFotoMensal == null
                  ? row.label
                  : 'Migração: ${usage.migracaoFotosUsadasMes} de ${usage.limiteMigracaoFotoMensal} fotos/mês',
          included: true,
        )
      else
        row,
  ];
}

List<({String label, bool included})> _paywallFeatureRows(
  Plano plano,
  SubscriptionPlan plan,
) => [
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

List<({String label, bool included})> _paywallUpgradeGains(
  Plano currentPlano,
  SubscriptionPlan currentPlan,
  Plano targetPlano,
  SubscriptionPlan targetPlan,
) {
  final currentByLabel = {
    for (final r in _paywallFeatureRows(currentPlano, currentPlan)) r.label: r.included,
  };
  return [
    for (final r in _paywallFeatureRows(targetPlano, targetPlan))
      if (r.included && currentByLabel[r.label] != true) r,
  ];
}

List<({String label, bool included})> _paywallDowngradeLosses(
  Plano currentPlano,
  SubscriptionPlan currentPlan,
  Plano targetPlano,
  SubscriptionPlan targetPlan,
) {
  final targetByLabel = {
    for (final r in _paywallFeatureRows(targetPlano, targetPlan)) r.label: r.included,
  };
  return [
    for (final r in _paywallFeatureRows(currentPlano, currentPlan))
      if (r.included && targetByLabel[r.label] != true)
        (label: r.label, included: false),
  ];
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
  final Plano currentPlano;
  final SubscriptionPlan plan;
  final SubscriptionPlan currentPlan;
  final PlanoFeatures? usage;
  final Color ink;
  final Color mute;
  final Color line;
  final Color primary;
  final bool isDark;

  const _PaywallFeaturePanel({
    required this.plano,
    required this.currentPlano,
    required this.plan,
    required this.currentPlan,
    this.usage,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = plan == currentPlan;
    final isUpgrade = plan.level > currentPlan.level;
    final isDowngrade = plan.level < currentPlan.level;
    final motion = _paywallMotion(context);
    final secondary = _paywallSecondaryText(mute, isDark: isDark);
    final planLabel = PaywallCatalog.displayPlanName(plan);
    final currentLabel = PaywallCatalog.displayPlanName(currentPlan);
    final checkColor =
        isDowngrade ? PaywallCatalog.warning : primary;

    final rows = switch (true) {
      true when isCurrent => _paywallFeatureRowsWithUsage(plano, plan, usage),
      true when isUpgrade =>
        _paywallUpgradeGains(currentPlano, currentPlan, plano, plan),
      true when isDowngrade =>
        _paywallDowngradeLosses(currentPlano, currentPlan, plano, plan),
      _ => _paywallFeatureRows(plano, plan),
    };

    final title = switch (true) {
      true when isCurrent => 'Seu plano inclui',
      true when isUpgrade => 'O que você ganha com $planLabel',
      true when isDowngrade => 'Recursos que você perde',
      _ => 'O que inclui $planLabel',
    };

    final subtitle = switch (true) {
      true when isCurrent => 'Resumo do $currentLabel ativo.',
      true when isUpgrade => 'Em relação ao $currentLabel que você usa hoje.',
      true when isDowngrade =>
        'Downgrade para $planLabel só pela ${subscriptionChannelLabel()}.',
      _ => null,
    };

    return AnimatedSwitcher(
      duration: motion,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Column(
        key: ValueKey('${plan.apiName}-${currentPlan.apiName}-$isCurrent'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TokensStrip.h2(
              color: ink,
              fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
            ).copyWith(fontSize: 17),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TokensStrip.bodyMuted(color: secondary),
            ),
          ],
          if (isDowngrade) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PaywallCatalog.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: PaywallCatalog.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: PaywallCatalog.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Para mudar ou cancelar, use as assinaturas do dispositivo. '
                      'Você pode perder acesso a recursos do $currentLabel.',
                      style: TokensStrip.body(color: ink).copyWith(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isUpgrade && rows.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Você já tem os principais recursos deste tier. Toque em um plano superior para ver ganhos.',
              style: TokensStrip.bodyMuted(color: secondary),
            ),
          ],
          const SizedBox(height: 14),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    row.included ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    size: 20,
                    color: row.included ? checkColor : mute.withValues(alpha: 0.4),
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
            child: TextButton(
              onPressed: () => FocuxLegal.openTerms(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Termos', style: linkStyle()),
            ),
          ),
          Text(' e a ', style: body),
          Semantics(
            button: true,
            label: 'Abrir política de privacidade',
            child: TextButton(
              onPressed: () => FocuxLegal.openPrivacy(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
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

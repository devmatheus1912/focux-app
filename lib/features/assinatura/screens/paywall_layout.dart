part of 'assinatura_screen.dart';

// ─── Paywall Focux — funil IAP mobile ───────────────────────────────────────

Color _paywallSecondaryText(Color ink, Color mute, {required bool isDark}) =>
    PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);

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
              (usage.limiteIaMensal ?? 0) <= 0
                  ? row.label
                  : 'IA: ${usage.iaUsadaMes} de ${usage.limiteIaMensal} este mês · ${usage.iaRestantes} restantes',
          included: true,
        )
      else if (row.included && row.label.contains('fotos de migração'))
        (
          label:
              usage.limiteMigracaoFotoMensal == null
                  ? row.label
                  : 'Migração: ${usage.migracaoFotosUsadasMes} de ${usage.limiteMigracaoFotoMensal} fotos/mês · ${usage.migracaoFotosRestantes} restantes',
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
  (label: 'Marca própria e identidade visual', included: plano.temWhiteLabel),
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
    return PaywallGlassCard(
      accent: primary,
      glow: !TokensStrip.prefersReducedMotion(context),
      glowStrength: 0.65,
      blur: false,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.rocket_launch_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Upgrade recomendado: ${PlanoIaLimits.enterprise} IA/mês, marca própria e alunos ilimitados no Enterprise.',
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
    final secondary = _paywallSecondaryText(ink, mute, isDark: isDark);
    final planLabel = PaywallCatalog.displayNameFor(plano, plan);
    final currentLabel = PaywallCatalog.displayNameFor(currentPlano, currentPlan);
    final checkColor = switch (true) {
      true when isDowngrade => PaywallCatalog.warning,
      true when isCurrent => PaywallCatalog.accentForPlan(plan),
      _ => primary,
    };

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
      true when isCurrent =>
        'Resumo do ${usage?.displayName?.trim().isNotEmpty == true ? usage!.displayName!.trim() : currentLabel} ativo.',
      true when isUpgrade => 'Em relação ao $currentLabel que você usa hoje.',
      true when isDowngrade =>
        'Downgrade para $planLabel só pela ${subscriptionChannelLabel()}.',
      _ => null,
    };

    final tierAccent = PaywallCatalog.accentForPlan(plan);

    return AnimatedSwitcher(
      duration: motion,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: PaywallGlassCard(
        key: ValueKey('${plan.apiName}-${currentPlan.apiName}-$isCurrent'),
        accent: tierAccent,
        glow: (isCurrent || isUpgrade) && !TokensStrip.prefersReducedMotion(context),
        glowStrength: 0.7,
        blur: false,
        elevationLevel: 8,
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            PaywallTierChrome.cardWash(
              accent: tierAccent,
              isDark: isDark,
              emphasis: PaywallTierEmphasis.mid,
            ),
            PaywallTierChrome.accentRail(tierAccent, emphasis: PaywallTierEmphasis.mid),
            Column(
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
            (row) => Semantics(
              label: row.included
                  ? 'Incluído: ${row.label}'
                  : 'Não incluído: ${row.label}',
              child: Padding(
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
          ],
        ),
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
    return PaywallGlassCard(
      padding: const EdgeInsets.all(14),
      blur: false,
      elevationLevel: 4,
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

class _PaywallLegalConsentLine extends StatefulWidget {
  final Color ink;
  final Color mute;
  final Color primary;
  final bool isUpgrade;

  const _PaywallLegalConsentLine({
    required this.ink,
    required this.mute,
    required this.primary,
    this.isUpgrade = false,
  });

  @override
  State<_PaywallLegalConsentLine> createState() => _PaywallLegalConsentLineState();
}

class _PaywallLegalConsentLineState extends State<_PaywallLegalConsentLine> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()..onTap = FocuxLegal.openTerms;
    _privacyTap = TapGestureRecognizer()..onTap = FocuxLegal.openPrivacy;
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = _paywallSecondaryText(
      widget.ink,
      widget.mute,
      isDark: isDark,
    );
    final body = TokensStrip.bodyMuted(color: secondary).copyWith(
      fontSize: 12,
      height: 1.45,
    );
    final link = body.copyWith(
      fontWeight: FontWeight.w600,
      color: widget.primary,
      decoration: TextDecoration.underline,
      decorationColor: widget.primary.withValues(alpha: 0.45),
    );

    final lead = widget.isUpgrade
        ? 'Ao confirmar upgrade, você concorda com os '
        : 'Ao assinar, você concorda com os ';
    final semanticsLead = widget.isUpgrade
        ? 'Ao confirmar upgrade, você concorda com os Termos de uso e a Política de privacidade'
        : 'Ao assinar, você concorda com os Termos de uso e a Política de privacidade';

    return Semantics(
      label: semanticsLead,
      child: Text.rich(
        textAlign: TextAlign.center,
        TextSpan(
          style: body,
          children: [
            TextSpan(text: lead),
            TextSpan(
              text: 'Termos',
              style: link,
              recognizer: _termsTap,
            ),
            const TextSpan(text: ' e a '),
            TextSpan(
              text: 'Privacidade',
              style: link,
              recognizer: _privacyTap,
            ),
            const TextSpan(text: '.'),
          ],
        ),
      ),
    );
  }
}

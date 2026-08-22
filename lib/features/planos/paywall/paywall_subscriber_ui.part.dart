part of 'paywall_components.dart';

/// Âncoras de scroll na vitrine de planos.
enum PaywallScrollTarget {
  planos,
  features,
  roi,

  /// Assinante — plano atual.
  seuPlano,

  /// Assinante — accordion de upgrade.
  upgrade,

  /// Assinante — comparativo rápido.
  comparar,

  /// Assinante — termos e cobrança.
  legal,
}

/// Alias legado — use [PaywallTierChrome] / [PaywallTierCard].
abstract class PaywallSurface {
  static const double cardRadius = PaywallTierChrome.cardRadius;
}

/// Rótulo de feature sem emoji no texto — ícone vetorial quando [pro].
class PaywallFeatureLabel extends StatelessWidget {
  final String raw;
  final Color ink;
  final Color accent;
  final TextStyle? style;
  final int? maxLines;

  const PaywallFeatureLabel({
    super.key,
    required this.raw,
    required this.ink,
    required this.accent,
    this.style,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final parsed = PaywallCatalog.parseFeatureLabel(raw);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            parsed.label,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
            style: style ?? TokensStrip.body(color: ink),
          ),
        ),
        if (parsed.pro) ...[
          const SizedBox(width: 6),
          Semantics(
            label: 'Recurso premium',
            child: Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
          ),
        ],
      ],
    );
  }
}

// ─── Hero ───────────────────────────────────────────────────────────────────

class PaywallHero extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color primary;
  final bool isDark;
  final SubscriptionPlan? currentPlan;
  final String? planDisplayLabel;
  final bool isMaxTier;
  final bool hasUpgradePath;
  final bool viewingCurrentPlan;
  final bool upgradeOffersExpanded;
  final bool upgradeTargetSelected;

  const PaywallHero({
    super.key,
    required this.ink,
    required this.mute,
    required this.primary,
    required this.isDark,
    this.currentPlan,
    this.planDisplayLabel,
    this.isMaxTier = false,
    this.hasUpgradePath = true,
    this.viewingCurrentPlan = false,
    this.upgradeOffersExpanded = false,
    this.upgradeTargetSelected = false,
  });

  bool get _isSubscriber =>
      currentPlan != null && currentPlan != SubscriptionPlan.FREE;

  @override
  Widget build(BuildContext context) {
    if (_isSubscriber) {
      final label =
          planDisplayLabel ?? PaywallCatalog.displayPlanName(currentPlan!);
      return PaywallSubscriberHeroGlass(
        plan: currentPlan!,
        planLabel: label,
        ink: ink,
        mute: mute,
        isDark: isDark,
        isMaxTier: isMaxTier,
        hasUpgradePath: hasUpgradePath,
        viewingCurrentPlan: viewingCurrentPlan,
        upgradeOffersExpanded: upgradeOffersExpanded,
        upgradeTargetSelected: upgradeTargetSelected,
      );
    }

    return PaywallGlassCard(
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      accent: primary,
      glow: false,
      blur: false,
      elevationLevel: 8,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PaywallTierBrandPill(
            label: 'PLANOS',
            accent: primary,
            isDark: isDark,
            icon: Icons.workspace_premium_outlined,
          ),
          const SizedBox(height: 12),
          Text(
            'Escolha o plano que cabe no seu momento',
            style: TokensStrip.h2(color: ink).copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'FREE para começar. Premium quando for cobrar e escalar.',
            style: TokensStrip.body(color: mute).copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Vitrine web (comparativo, ROI, features) — link só quando [FocuxLegal.plansMarketingWebLive] for true.
class PaywallWebDetailsLink extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color primary;
  final Color line;
  final bool isDark;

  const PaywallWebDetailsLink({
    super.key,
    required this.ink,
    required this.mute,
    required this.primary,
    required this.line,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final live = FocuxLegal.plansMarketingWebLive;
    final panel = PaywallGlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      accent: live ? primary : mute.withValues(alpha: 0.35),
      glow: live,
      blur: false,
      elevationLevel: 6,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            live ? Icons.open_in_new_rounded : Icons.schedule_rounded,
            color: live ? primary : mute,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  live
                      ? 'Comparação completa no site'
                      : 'Comparação detalhada em breve',
                  style: TokensStrip.h2(color: ink).copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  live
                      ? 'Tabela 4 tiers · ROI · 10 diferenciais'
                      : 'Tabela, ROI e diferenciais — disponível no site em breve.',
                  style: TokensStrip.bodyMuted(color: mute),
                ),
              ],
            ),
          ),
          if (live)
            Icon(Icons.chevron_right_rounded, color: mute)
          else
            _PlanChip(label: 'EM BREVE', color: PaywallCatalog.warning),
        ],
      ),
    );

    if (!live) {
      return Semantics(
        label: 'Comparação detalhada de planos no site, em breve',
        child: panel,
      );
    }

    return Semantics(
      button: true,
      label: 'Abrir comparação completa de planos no site',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => FocuxLegal.openPlansMarketing(),
          borderRadius: BorderRadius.circular(16),
          child: panel,
        ),
      ),
    );
  }
}

/// Comparativo enxuto no app (assinante) — sem depender da página web.
class PaywallSubscriberQuickCompare extends StatelessWidget {
  final SubscriptionPlan currentPlan;
  final SubscriptionPlan? targetPlan;
  final List<PaywallComparisonRow> comparisonRows;
  final bool initiallyExpanded;
  final bool catalogFromApi;
  final bool expandRequested;
  final VoidCallback? onReveal;
  final Color ink;
  final Color mute;
  final Color line;
  final Color primary;
  final bool isDark;

  const PaywallSubscriberQuickCompare({
    super.key,
    required this.currentPlan,
    this.targetPlan,
    this.comparisonRows = PaywallCatalog.comparisonRows,
    this.initiallyExpanded = false,
    this.catalogFromApi = false,
    this.expandRequested = false,
    this.onReveal,
    required this.ink,
    required this.mute,
    required this.line,
    required this.primary,
    required this.isDark,
  });

  List<PaywallComparisonRow> get _rows {
    if (targetPlan == null) return const [];
    final rows = comparisonRows.where((row) {
      final current = row.valueFor(currentPlan);
      final next = row.valueFor(targetPlan!);
      return current != next && next != '—';
    });
    return rows.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    if (rows.isEmpty) return const SizedBox.shrink();

    final targetLabel = PaywallCatalog.displayPlanName(targetPlan!);
    final diffCount = rows.length;

    if (!expandRequested) {
      return PaywallInsetPanel(
        accent: PaywallCatalog.accentForPlan(targetPlan!),
        isDark: isDark,
        child: Semantics(
          button: true,
          label:
              'Comparativo rápido com $targetLabel, '
              '$diffCount recursos exclusivos. Toque para ver.',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onReveal?.call();
              },
              borderRadius: BorderRadius.circular(TokensStrip.rSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comparativo rápido',
                            style: TokensStrip.body(color: ink).copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            diffCount == 1
                                ? '1 recurso exclusivo no $targetLabel'
                                : '$diffCount recursos exclusivos no $targetLabel',
                            style: TokensStrip.bodyMuted(
                              color: mute,
                            ).copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: primary, size: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return PaywallCollapsibleBlock(
      title: 'Comparativo rápido',
      subtitle:
          diffCount == 1
              ? '1 recurso exclusivo no $targetLabel'
              : '$diffCount recursos exclusivos no $targetLabel',
      ink: ink,
      mute: mute,
      line: line,
      isDark: isDark,
      initiallyExpanded: initiallyExpanded || expandRequested,
      expandRequested: expandRequested,
      subscriberFlat: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label:
                'Comparativo rápido entre ${PaywallCatalog.displayPlanName(currentPlan)} '
                'e $targetLabel, ${rows.length} recursos',
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  _PaywallCompareDiffRow(
                    feature: rows[i].feature,
                    targetAccent: PaywallCatalog.accentForPlan(targetPlan!),
                    ink: ink,
                    mute: mute,
                    isDark: isDark,
                    isLast: i == rows.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            catalogFromApi
                ? 'Comparativo sincronizado com o servidor.'
                : 'Tabela completa e ROI no site quando disponível.',
            style: TokensStrip.bodyMuted(
              color: PaywallCatalog.readableSecondary(
                ink,
                mute,
                isDark: isDark,
              ),
            ).copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Rodapé legal enxuto para assinante no plano atual (sem bloco de compra).
class PaywallSubscriberLegalStrip extends StatelessWidget {
  final Color mute;
  final Color primary;
  final VoidCallback? onRestore;
  final bool restoring;

  const PaywallSubscriberLegalStrip({
    super.key,
    required this.mute,
    required this.primary,
    this.onRestore,
    this.restoring = false,
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
    return Wrap(
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
            child: Text('Privacidade', style: link()),
          ),
        ),
        Semantics(
          button: true,
          label: 'Abrir termos de uso',
          child: TextButton(
            onPressed: () => FocuxLegal.openTerms(),
            style: linkStyle,
            child: Text('Termos', style: link()),
          ),
        ),
        if (onRestore != null)
          Semantics(
            button: true,
            label:
                restoring
                    ? 'Restaurando compras'
                    : 'Restaurar compras anteriores',
            child: TextButton(
              onPressed: restoring ? null : onRestore,
              style: linkStyle,
              child: Text(
                restoring ? 'Restaurando…' : 'Restaurar compras',
                style: link(),
              ),
            ),
          ),
      ],
    );
  }
}

/// Navegação rápida para assinantes — âncoras na mesma tela.
class PaywallSubscriberQuickNav extends StatelessWidget {
  final Color primary;
  final Color ink;
  final ValueChanged<PaywallScrollTarget> onSectionTap;

  const PaywallSubscriberQuickNav({
    super.key,
    required this.primary,
    required this.ink,
    required this.onSectionTap,
  });

  static const _items =
      <({PaywallScrollTarget id, String label, IconData icon})>[
        (
          id: PaywallScrollTarget.seuPlano,
          label: 'Seu plano',
          icon: Icons.verified_outlined,
        ),
        (
          id: PaywallScrollTarget.upgrade,
          label: 'Upgrade',
          icon: Icons.arrow_upward_rounded,
        ),
        (
          id: PaywallScrollTarget.comparar,
          label: 'Comparar',
          icon: Icons.compare_arrows_rounded,
        ),
        (
          id: PaywallScrollTarget.legal,
          label: 'Legal',
          icon: Icons.policy_outlined,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++) ...[
              if (i > 0) const SizedBox(width: TokensStrip.s2),
              Semantics(
                button: true,
                label: 'Ir para ${_items[i].label}',
                child: FxGlassSurface(
                  accent: primary,
                  radius: TokensStrip.rPill,
                  elevationLevel: 6,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  onTap: () => onSectionTap(_items[i].id),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_items[i].icon, size: 16, color: primary),
                      const SizedBox(width: TokensStrip.s2),
                      Text(
                        _items[i].label,
                        style: AppTypography.inter(
                          color: ink,
                          fontWeight: FontWeight.w700,
                          fontSize: TokensStrip.fontBodySm,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PaywallQuickNav extends StatelessWidget {
  final Color primary;
  final Color ink;
  final ValueChanged<PaywallScrollTarget> onSectionTap;

  const PaywallQuickNav({
    super.key,
    required this.primary,
    required this.ink,
    required this.onSectionTap,
  });

  static const _items =
      <({PaywallScrollTarget id, String label, IconData icon})>[
        (
          id: PaywallScrollTarget.planos,
          label: 'Planos',
          icon: Icons.view_agenda_outlined,
        ),
        (
          id: PaywallScrollTarget.features,
          label: 'Features',
          icon: Icons.star_outline_rounded,
        ),
        (
          id: PaywallScrollTarget.roi,
          label: 'ROI',
          icon: Icons.savings_outlined,
        ),
      ];

  List<({PaywallScrollTarget id, String label, IconData icon})>
  get _visibleItems {
    if (FocuxLegal.plansMarketingWebLive) return _items;
    return _items
        .where((item) => item.id == PaywallScrollTarget.planos)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Ir para ${items[i].label}',
                child: FxGlassSurface(
                  accent: primary,
                  radius: TokensStrip.rPill,
                  elevationLevel: 6,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  onTap: () => onSectionTap(items[i].id),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].icon, size: 16, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        items[i].label,
                        style: AppTypography.inter(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PaywallSectionAnchor extends StatelessWidget {
  final GlobalKey anchorKey;
  final Widget child;

  const PaywallSectionAnchor({
    super.key,
    required this.anchorKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: anchorKey, child: child);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/legal/focux_legal.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../assinatura/data/plano.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/plan_entitlements.dart';
import '../../subscription/store_subscription_policy.dart';
import '../../subscription/widgets/upgrade_prompt_sheet.dart';
import '../../subscription/subscription_products.dart';
import '../../../core/widgets/fx_glass_surface.dart';
import '../../../core/widgets/fx_motion.dart';
import 'paywall_catalog.dart';
import 'paywall_glass.dart';

export 'paywall_glass.dart';
export 'paywall_plan_studio.dart';

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
          planDisplayLabel ??
          PaywallCatalog.displayPlanName(currentPlan!);
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
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 20),
      accent: primary,
      glow: true,
      blur: false,
      elevationLevel: 12,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          PaywallTierBrandPill(
            label: 'FOCUX · PLANOS',
            accent: primary,
            isDark: isDark,
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: 18),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ink, primary],
            ).createShader(bounds),
            child: Text(
              'Seu app. Sua marca.\nSeus alunos. Sem limite.',
              textAlign: TextAlign.center,
              style: TokensStrip.h1(color: Colors.white).copyWith(
                fontSize: 26,
                height: 1.06,
                letterSpacing: -1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Cada recurso aqui responde: isso me ajuda a ganhar mais ou trabalhar menos?',
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 15),
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
                  live ? 'Comparação completa no site' : 'Comparação detalhada em breve',
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
                            style: TokensStrip.bodyMuted(color: mute).copyWith(
                              fontSize: 12.5,
                            ),
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
              color: PaywallCatalog.readableSecondary(ink, mute, isDark: isDark),
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
            label: restoring ? 'Restaurando compras' : 'Restaurar compras anteriores',
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

  static const _items = <({PaywallScrollTarget id, String label, IconData icon})>[
    (id: PaywallScrollTarget.seuPlano, label: 'Seu plano', icon: Icons.verified_outlined),
    (id: PaywallScrollTarget.upgrade, label: 'Upgrade', icon: Icons.arrow_upward_rounded),
    (id: PaywallScrollTarget.comparar, label: 'Comparar', icon: Icons.compare_arrows_rounded),
    (id: PaywallScrollTarget.legal, label: 'Legal', icon: Icons.policy_outlined),
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

  static const _items = <({PaywallScrollTarget id, String label, IconData icon})>[
    (id: PaywallScrollTarget.planos, label: 'Planos', icon: Icons.view_agenda_outlined),
    (id: PaywallScrollTarget.features, label: 'Features', icon: Icons.star_outline_rounded),
    (id: PaywallScrollTarget.roi, label: 'ROI', icon: Icons.savings_outlined),
  ];

  List<({PaywallScrollTarget id, String label, IconData icon})> get _visibleItems {
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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

// ─── Usage meters (Plan Studio) ─────────────────────────────────────────────

/// Barras de uso do plano atual — alunos e IA (assinante).
class PaywallUsageMeters extends StatelessWidget {
  final PlanoUsageSnapshot usage;
  final Color ink;
  final Color mute;
  final bool isDark;

  const PaywallUsageMeters({
    super.key,
    required this.usage,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(usage.plano);
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final showAlunosMeter =
        usage.limiteAlunos != null && usage.limiteAlunos! > 0;
    final showAlunosUnlimited =
        usage.limiteAlunos == null &&
        (usage.plano == SubscriptionPlan.ENTERPRISE ||
            usage.plano == SubscriptionPlan.ENTERPRISE_PRO);
    final showIa = usage.limiteIaMensal > 0;
    if (!showAlunosMeter && !showAlunosUnlimited && !showIa) {
      return const SizedBox.shrink();
    }

    return Semantics(
      container: true,
      label: 'Uso do seu plano',
      child: PaywallInsetPanel(
      accent: accent,
      isDark: isDark,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Uso do seu plano',
            style: AppTypography.inter(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          if (showAlunosUnlimited)
            _PaywallUsageUnlimitedRow(
              label: 'Alunos ativos',
              detail: usage.alunosAtivos > 0
                  ? '${usage.alunosAtivos} cadastrados agora'
                  : 'Sem teto de cadastro',
              accent: accent,
              ink: ink,
              secondary: secondary,
              isDark: isDark,
            ),
          if (showAlunosMeter)
            _PaywallUsageMeterRow(
              label: 'Alunos ativos',
              used: usage.alunosAtivos,
              limit: usage.limiteAlunos!,
              accent: accent,
              ink: ink,
              secondary: secondary,
              isDark: isDark,
              atLimit: usage.alunosAtLimit,
              nearLimit: usage.alunosNearLimit,
            ),
          if ((showAlunosMeter || showAlunosUnlimited) && showIa)
            const SizedBox(height: 10),
          if (showIa)
            _PaywallUsageMeterRow(
              label: 'IA Copiloto (mês)',
              used: usage.iaUsadaMes,
              limit: usage.limiteIaMensal,
              remaining: usage.iaRestantesEfetivos,
              accent: accent,
              ink: ink,
              secondary: secondary,
              isDark: isDark,
              atLimit: usage.iaAtLimit,
              nearLimit: usage.iaNearLimit,
            ),
        ],
      ),
    ),
    );
  }
}

class _PaywallUsageMeterRow extends StatelessWidget {
  final String label;
  final int used;
  final int limit;
  final int? remaining;
  final Color accent;
  final Color ink;
  final Color secondary;
  final bool isDark;
  final bool atLimit;
  final bool nearLimit;

  const _PaywallUsageMeterRow({
    required this.label,
    required this.used,
    required this.limit,
    this.remaining,
    required this.accent,
    required this.ink,
    required this.secondary,
    required this.isDark,
    required this.atLimit,
    required this.nearLimit,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = limit <= 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final barColor = atLimit
        ? const Color(0xFFE85D5D)
        : nearLimit
        ? PaywallCatalog.warning
        : accent;
    final rest = remaining ?? (limit - used).clamp(0, limit);
    final statusHint = atLimit
        ? ', limite atingido'
        : nearLimit
        ? ', perto do limite'
        : '';
    return Semantics(
      label: '$label: $used de $limit, $rest restantes$statusHint',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TokensStrip.body(color: secondary).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$used / $limit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '$rest restantes',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: accent.withValues(alpha: isDark ? 0.12 : 0.08),
              color: barColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallUsageUnlimitedRow extends StatelessWidget {
  final String label;
  final String detail;
  final Color accent;
  final Color ink;
  final Color secondary;
  final bool isDark;

  const _PaywallUsageUnlimitedRow({
    required this.label,
    required this.detail,
    required this.accent,
    required this.ink,
    required this.secondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: ilimitados. $detail',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TokensStrip.body(color: secondary).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TokensStrip.bodyMuted(color: secondary).copyWith(
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(TokensStrip.rPill),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Text(
              'ILIMITADO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: PaywallCatalog.readableTierAccent(accent, isDark: isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sync banner (assinatura vs /me) ────────────────────────────────────────

class PaywallPlanSyncBanner extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool isDark;
  final String billingLabel;
  final String? serverLabel;
  final String? message;
  final VoidCallback? onRefresh;

  const PaywallPlanSyncBanner({
    super.key,
    required this.ink,
    required this.mute,
    required this.isDark,
    required this.billingLabel,
    this.serverLabel,
    this.message,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.warning;
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final body = message?.trim().isNotEmpty == true
        ? message!.trim()
        : 'Seu plano $billingLabel está ativo na loja. '
            'Estamos sincronizando os dados — toque em Atualizar.';

    return Semantics(
      container: true,
      label: body,
      child: PaywallInsetPanel(
        accent: accent,
        isDark: isDark,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sync_problem_rounded, size: 20, color: accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                body,
                style: TokensStrip.body(color: secondary).copyWith(
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
            if (onRefresh != null) ...[
              const SizedBox(width: 6),
              TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onRefresh!();
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Atualizar',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: PaywallCatalog.readableTierAccent(accent, isDark: isDark),
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

// ─── Context banner ─────────────────────────────────────────────────────────

class PaywallContextBanner extends StatelessWidget {
  final PlanoUsageSnapshot usage;
  final String? blockedFeatureLabel;
  final String? blockedCapability;
  final Color ink;
  final Color mute;
  final VoidCallback? onCta;

  const PaywallContextBanner({
    super.key,
    required this.usage,
    this.blockedFeatureLabel,
    this.blockedCapability,
    required this.ink,
    required this.mute,
    this.onCta,
  });

  String? _message(SubscriptionPlan target) {
    if (blockedFeatureLabel != null && blockedFeatureLabel!.isNotEmpty) {
      return 'Você tentou usar $blockedFeatureLabel. '
          'Disponível no plano ${PlanEntitlements.displayPlanName(target)}.';
    }
    if (usage.alunosAtLimit && usage.limiteAlunos != null) {
      return 'Você atingiu ${usage.limiteAlunos} alunos. '
          'Cada novo = R\$ 300–600/mês. Enterprise remove o teto.';
    }
    if (usage.alunosNearLimit && usage.limiteAlunos != null) {
      final left = (usage.limiteAlunos! - usage.alunosAtivos).clamp(0, 99);
      return 'Você tem ${usage.alunosAtivos} alunos — faltam $left para o limite. '
          'Upgrade libera mais vagas e receita.';
    }
    if (usage.iaAtLimit) {
      return 'Você usou ${usage.iaUsadaMes} de ${usage.limiteIaMensal} IA este mês. '
          'Enterprise libera até 400+ interações.';
    }
    if (usage.iaNearLimit) {
      return 'Você usou ${usage.iaUsadaMes} de ${usage.limiteIaMensal} interações de IA. '
          'Enterprise dá mais folga no Copiloto.';
    }
    if (usage.plano == SubscriptionPlan.FREE) {
      return 'Com 20 alunos a R\$ 400 = R\$ 8.000/mês. '
          'O Premium representa menos de 1% desse faturamento.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final target = PlanEntitlements.resolveUpgradeTarget(
      usage: usage,
      blockedFeatureLabel: blockedFeatureLabel,
      blockedCapability: blockedCapability,
    );
    final msg = _message(target);
    if (msg == null) return const SizedBox.shrink();

    final accent = PaywallCatalog.accentForPlan(target);

    return PaywallGlassCard(
      accent: accent,
      glow: false,
      blur: false,
      elevationLevel: 6,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bolt_rounded, color: accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg, style: TokensStrip.body(color: ink)),
          ),
          if (onCta != null)
            TextButton(
              onPressed: onCta,
              child: Text(
                'Ver ${PlanEntitlements.displayPlanName(target)}',
                style: TextStyle(color: accent),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Social proof + ROI strip ─────────────────────────────────────────────────

class PaywallSocialProofStrip extends StatelessWidget {
  final Color line;
  final Color ink;
  final Color mute;
  final List<({String value, String label})> socialProof;

  const PaywallSocialProofStrip({
    super.key,
    required this.line,
    required this.ink,
    required this.mute,
    List<({String value, String label})>? socialProof,
  }) : socialProof = socialProof ?? PaywallCatalog.socialProof;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: line),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var i = 0; i < socialProof.length; i++) ...[
            if (i > 0) VerticalDivider(width: 1, color: line),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
                child: Column(
                  children: [
                    Text(
                      socialProof[i].value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: ink,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      socialProof[i].label,
                      textAlign: TextAlign.center,
                      style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PaywallRoiStrip extends StatelessWidget {
  final Color line;
  final Color ink;
  final Color mute;
  final List<({String value, String label, Color color})>? roiStrip;

  const PaywallRoiStrip({
    super.key,
    required this.line,
    required this.ink,
    required this.mute,
    this.roiStrip,
  });

  @override
  Widget build(BuildContext context) {
    return PaywallGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      accent: PaywallCatalog.brand,
      glow: false,
      blur: false,
      elevationLevel: 6,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, c) {
          final items = roiStrip ?? PaywallCatalog.roiStrip;
          final cols = c.maxWidth < 520 ? 2 : 3;
          return Column(
            children: [
              for (var row = 0; row < (items.length / cols).ceil(); row++) ...[
                if (row > 0) Divider(height: 1, color: line),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < cols; col++) ...[
                        if (col > 0) VerticalDivider(width: 1, color: line),
                        Expanded(
                          child: row * cols + col < items.length
                              ? _RoiCell(
                                  item: items[row * cols + col],
                                  line: line,
                                  mute: mute,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _RoiCell extends StatelessWidget {
  final ({String value, String label, Color color}) item;
  final Color line;
  final Color mute;

  const _RoiCell({
    required this.item,
    required this.line,
    required this.mute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Text(
            item.value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: item.color,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─── Rich plan card ───────────────────────────────────────────────────────────

class PaywallRichPlanCard extends StatelessWidget {
  final Plano plano;
  final SubscriptionPlan plan;
  final bool isSelected;
  final bool isCurrent;
  final bool isLockedDowngrade;
  /// Consulta/downgrade na loja — sem preços nem fluxo de compra (Plan Studio).
  final bool referenceOnly;
  final bool dimUnselected;
  final bool collapseFeatureDetails;
  final bool compactUpsell;
  final List<String> upsellHighlights;
  final bool billingDisabled;
  final String monthlyPrice;
  final String annualPrice;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final VoidCallback? onTap;
  final SubscriptionBillingPeriod? billingPeriod;
  final ValueChanged<SubscriptionBillingPeriod>? onBillingPeriodTap;
  final VoidCallback? onFeatureHelp;
  final bool nestedInAccordion;
  final bool embeddedInStudio;
  final bool showFeatureLegend;

  const PaywallRichPlanCard({
    super.key,
    required this.plano,
    required this.plan,
    required this.isSelected,
    required this.isCurrent,
    this.isLockedDowngrade = false,
    this.referenceOnly = false,
    this.dimUnselected = false,
    this.collapseFeatureDetails = false,
    this.compactUpsell = false,
    this.upsellHighlights = const [],
    this.billingDisabled = false,
    required this.monthlyPrice,
    required this.annualPrice,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    this.onTap,
    this.billingPeriod,
    this.onBillingPeriodTap,
    this.onFeatureHelp,
    this.nestedInAccordion = false,
    this.embeddedInStudio = false,
    this.showFeatureLegend = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(plan);
    final badge = PaywallCatalog.badgeFor(plano, plan);
    final planTitle = PaywallCatalog.displayNameFor(plano, plan);
    final planSubtitle = PaywallCatalog.subtitleFor(plano, plan);
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final roiTag = PaywallCatalog.roiTagFor(plano, plan);
    final sections = PaywallCatalog.featureSectionsForPlan(plano, plan);
    final hideUpgradePricing =
        billingDisabled && !isCurrent && plan != SubscriptionPlan.FREE;
    final showCompactBody = compactUpsell && !isCurrent;
    final referenceMode = referenceOnly || isLockedDowngrade;
    final collapseFeatures = collapseFeatureDetails && isCurrent || referenceMode;

    final cardBody = Stack(
          children: [
            if (!embeddedInStudio && !referenceMode && badge != null && !isCurrent)
              Positioned(
                top: TokensStrip.s4,
                right: TokensStrip.s4,
                child: PaywallTierBrandPill(
                  label: badge,
                  accent: accent,
                  isDark: isDark,
                ),
              ),
            if (!embeddedInStudio && isCurrent)
              Positioned(
                top: TokensStrip.s4,
                right: TokensStrip.s4,
                child: PaywallTierBrandPill(
                  label: 'SEU PLANO',
                  accent: accent,
                  isDark: isDark,
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(PaywallSurface.cardRadius),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        embeddedInStudio ? 16 : TokensStrip.s5,
                        embeddedInStudio ? 8 : TokensStrip.s5,
                        embeddedInStudio
                            ? 16
                            : (badge != null || isCurrent)
                            ? 100
                            : TokensStrip.s5,
                        TokensStrip.s3,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!embeddedInStudio)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                PaywallTierMedallion(
                                  plan: plan,
                                  accent: accent,
                                  isDark: isDark,
                                ),
                                const SizedBox(width: TokensStrip.s3),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        planTitle.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                          height: 1.1,
                                          color: PaywallCatalog.tierAccentOnSurface(
                                            plan,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: TokensStrip.s1),
                                      Text(
                                        planSubtitle,
                                        style: TokensStrip.bodyMuted(color: secondary).copyWith(
                                          fontSize: TokensStrip.fontBodySm,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else if (!isCurrent) ...[
                            Text(
                              planTitle.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                height: 1.1,
                                color: PaywallCatalog.tierAccentOnSurface(
                                  plan,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: TokensStrip.s1),
                            Text(
                              planSubtitle,
                              style: TokensStrip.bodyMuted(color: secondary).copyWith(
                                fontSize: TokensStrip.fontBodySm,
                                height: 1.4,
                              ),
                            ),
                          ],
                          if (!embeddedInStudio || !isCurrent)
                            const SizedBox(height: TokensStrip.s3),
                          if (referenceMode)
                            _PlanReferenceStoreHint(
                              plan: plan,
                              ink: ink,
                              mute: mute,
                              isDark: isDark,
                              accent: accent,
                            )
                          else if (!isCurrent && plan != SubscriptionPlan.FREE)
                            hideUpgradePricing
                                ? _StoreBillingHint(
                                    ink: ink,
                                    mute: mute,
                                    isDark: isDark,
                                  )
                                : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _PriceBox(
                                        label: 'Mensal',
                                        price: monthlyPrice,
                                        accent: accent,
                                        ink: ink,
                                        mute: mute,
                                        line: line,
                                        isDark: isDark,
                                        disabled: billingDisabled,
                                        selected:
                                            !billingDisabled &&
                                            isSelected &&
                                            billingPeriod ==
                                                SubscriptionBillingPeriod.monthly,
                                        onTap:
                                            billingDisabled
                                                ? null
                                                : onBillingPeriodTap == null
                                                ? null
                                                : () => onBillingPeriodTap!(
                                                      SubscriptionBillingPeriod.monthly,
                                                    ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _PriceBox(
                                        label: 'Anual',
                                        price: annualPrice,
                                        accent: accent,
                                        ink: ink,
                                        mute: mute,
                                        line: line,
                                        isDark: isDark,
                                        disabled: billingDisabled,
                                        selected:
                                            !billingDisabled &&
                                            isSelected &&
                                            (billingPeriod ??
                                                    SubscriptionBillingPeriod.yearly) ==
                                                SubscriptionBillingPeriod.yearly,
                                        onTap:
                                            billingDisabled
                                                ? null
                                                : onBillingPeriodTap == null
                                                ? null
                                                : () => onBillingPeriodTap!(
                                                      SubscriptionBillingPeriod.yearly,
                                                    ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else if (isCurrent)
                            embeddedInStudio
                                ? _StudioActiveStatusBanner(
                                    ink: ink,
                                    mute: mute,
                                    accent: accent,
                                    isDark: isDark,
                                  )
                                : Text(
                                    'Ativo',
                                    style: AppTypography.inter(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 26,
                                      letterSpacing: -0.4,
                                      height: 1.05,
                                      color: ink,
                                    ),
                                  )
                          else if (plan == SubscriptionPlan.FREE)
                            Text(
                              'R\$ 0',
                              style: TokensStrip.h2(color: ink).copyWith(fontSize: 22),
                            ),
                          if (roiTag != null && !referenceMode) ...[
                            const SizedBox(height: 10),
                            _RoiMoneyTag(text: roiTag),
                          ],
                          if (!embeddedInStudio &&
                              !collapseFeatures &&
                              !showCompactBody &&
                              !referenceMode) ...[
                            const SizedBox(height: 8),
                            Text(
                              PaywallCatalog.descriptionForPlan(plan),
                              style: TokensStrip.bodyMuted(color: secondary).copyWith(
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (showCompactBody && upsellHighlights.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            PaywallInsetPanel(
                              accent: accent,
                              isDark: isDark,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final line in upsellHighlights)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.add_circle_outline,
                                            size: 16,
                                            color: accent,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              line,
                                              style: TokensStrip.body(color: ink).copyWith(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Text(
                                    'Detalhes no comparativo abaixo.',
                                    style: TokensStrip.bodyMuted(color: secondary).copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (showCompactBody)
                  const SizedBox(height: 12)
                else ...[
                  Divider(height: 1, color: line.withValues(alpha: isDark ? 0.35 : 0.45)),
                  if (embeddedInStudio && collapseFeatures && isCurrent) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: _PaywallStudioFeatureSummary(
                        sections: sections,
                        accent: accent,
                        ink: ink,
                        mute: mute,
                        isDark: isDark,
                      ),
                    ),
                  ],
                  if (collapseFeatures)
                    Theme(
                      data: PaywallTierChrome.expansionTheme(context, accent),
                      child: Semantics(
                        label: referenceMode
                            ? 'Ver recursos deste plano, referência'
                            : 'Ver todos os recursos do plano',
                        child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        title: Text(
                          referenceMode
                              ? 'Ver recursos deste plano (referência)'
                              : 'Ver todos os recursos',
                          style: TokensStrip.body(color: ink).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        children: [
                          PaywallPlanFeatureSections(
                            sections: sections,
                            accent: accent,
                            ink: ink,
                            mute: mute,
                            onFeatureHelp: onFeatureHelp,
                            allowLockedTap: !referenceMode,
                            showLegend: showFeatureLegend,
                            hideLockedOnlySections:
                                embeddedInStudio && collapseFeatures && isCurrent,
                          ),
                        ],
                      ),
                      ),
                    )
                  else
                    PaywallPlanFeatureSections(
                      sections: sections,
                      accent: accent,
                      ink: ink,
                      mute: mute,
                      onFeatureHelp: onFeatureHelp,
                      allowLockedTap: !referenceMode,
                      showLegend: showFeatureLegend,
                      hideLockedOnlySections:
                          embeddedInStudio && collapseFeatures && isCurrent,
                    ),
                ],
              ],
            ),
          ],
        );

    return Semantics(
      selected: isSelected,
      label: referenceMode
          ? 'Plano $planTitle, referência, alteração somente na ${subscriptionChannelLabel()}'
          : 'Plano $planTitle, $monthlyPrice mensal, $annualPrice anual'
              '${isCurrent ? ', plano atual' : ''}'
              '${isLockedDowngrade ? ', downgrade pela loja' : ''}',
      child: Opacity(
        opacity: referenceMode
            ? 1
            : isLockedDowngrade
            ? 0.72
            : dimUnselected
            ? (compactUpsell ? 0.92 : 0.72)
            : 1,
        child: embeddedInStudio || referenceMode
            ? cardBody
            : PaywallTierCard(
                plan: plan,
                isDark: isDark,
                isCurrent: isCurrent,
                isSelected: isSelected && plan != SubscriptionPlan.FREE,
                nestedInAccordion: nestedInAccordion,
                child: cardBody,
              ),
      ),
    );
  }
}

/// Três destaques do plano ativo — modo resumo no Plan Studio.
class _PaywallStudioFeatureSummary extends StatelessWidget {
  final List<PaywallPlanFeatureSection> sections;
  final Color accent;
  final Color ink;
  final Color mute;
  final bool isDark;

  const _PaywallStudioFeatureSummary({
    required this.sections,
    required this.accent,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  List<PaywallPlanFeatureItem> get _highlights {
    final included = <PaywallPlanFeatureItem>[];
    for (final section in sections) {
      for (final item in section.items) {
        if (item.included && !item.comingSoon) included.add(item);
      }
    }
    included.sort((a, b) {
      final ah = a.highlight ? 1 : 0;
      final bh = b.highlight ? 1 : 0;
      return bh.compareTo(ah);
    });
    return included.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _highlights;
    if (items.isEmpty) return const SizedBox.shrink();
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);

    return PaywallInsetPanel(
      accent: accent,
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Incluído no seu plano',
            style: AppTypography.inter(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: ink,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: PaywallCatalog.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PaywallFeatureLabel(
                      raw: item.label,
                      ink: ink,
                      accent: accent,
                      style: TokensStrip.body(color: secondary).copyWith(
                        fontSize: 12.5,
                        fontWeight: item.highlight ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PaywallPlanFeatureSections extends StatelessWidget {
  final List<PaywallPlanFeatureSection> sections;
  final Color accent;
  final Color ink;
  final Color mute;
  final VoidCallback? onFeatureHelp;
  final bool allowLockedTap;
  final bool showLegend;
  final bool hideLockedOnlySections;

  const PaywallPlanFeatureSections({
    super.key,
    required this.sections,
    required this.accent,
    required this.ink,
    required this.mute,
    this.onFeatureHelp,
    this.allowLockedTap = true,
    this.showLegend = false,
    this.hideLockedOnlySections = false,
  });

  List<PaywallPlanFeatureSection> get _visibleSections {
    if (!hideLockedOnlySections) return sections;
    return sections
        .where(
          (section) => section.items.any(
            (item) => item.included || item.comingSoon,
          ),
        )
        .toList();
  }

  Duration _expansionDuration(BuildContext context) =>
      TokensStrip.prefersReducedMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 220);

  PaywallFeatureEducation _education(PaywallPlanFeatureItem item) {
    return PaywallFeatureEducation(
      row: PaywallFeatureRow(
        label: item.label,
        included: item.included,
        highlight: item.highlight,
        comingSoon: item.comingSoon,
      ),
      education: PaywallCatalog.educationByLabel[item.label],
      capability: item.capability,
      upgradePlan: item.upgradePlan,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleSections = _visibleSections;
    final comingSoonItems = <PaywallPlanFeatureItem>[
      for (final section in visibleSections)
        for (final item in section.items)
          if (item.comingSoon) item,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in visibleSections) ...[
            if (section.collapsible)
              Theme(
                data: PaywallTierChrome.expansionTheme(context, accent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 4),
                  title: _PlanSectionTitle(
                    title: section.title,
                    accent: accent,
                    mute: mute,
                    ink: ink,
                  ),
                  initiallyExpanded: section.initiallyExpanded,
                  expansionAnimationStyle: AnimationStyle(
                    duration: _expansionDuration(context),
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  ),
                  children: section.items
                      .where((item) => !item.comingSoon)
                      .map(
                        (item) => PaywallFeatureLine(
                          feature: _education(item),
                          accent: accent,
                          mute: mute,
                          ink: ink,
                          onHelp: onFeatureHelp,
                          allowLockedTap: allowLockedTap,
                        ),
                      )
                      .toList(),
                ),
              )
            else ...[
              _PlanSectionTitle(
                title: section.title,
                accent: accent,
                mute: mute,
                ink: ink,
              ),
              ...section.items.where((item) => !item.comingSoon).map(
                (item) => PaywallFeatureLine(
                  feature: _education(item),
                  accent: accent,
                  mute: mute,
                  ink: ink,
                  onHelp: onFeatureHelp,
                  allowLockedTap: allowLockedTap,
                ),
              ),
            ],
            const SizedBox(height: 4),
          ],
          if (comingSoonItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            _PlanSectionTitle(
              title: 'Em breve',
              accent: PaywallCatalog.warning,
              mute: mute,
              ink: ink,
            ),
            ...comingSoonItems.map(
              (item) => PaywallFeatureLine(
                feature: _education(item),
                accent: accent,
                mute: mute,
                ink: ink,
                onHelp: onFeatureHelp,
                allowLockedTap: allowLockedTap,
              ),
            ),
          ],
          if (showLegend) ...[
            const SizedBox(height: 10),
            _PaywallFeatureLegend(ink: ink, mute: mute),
          ],
        ],
      ),
    );
  }
}

/// Legenda compacta — ícone + texto (sem depender só de cor).
class _PaywallFeatureLegend extends StatelessWidget {
  final Color ink;
  final Color mute;

  const _PaywallFeatureLegend({required this.ink, required this.mute});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 11, height: 1.35, color: mute.withValues(alpha: 0.88));
    return Semantics(
      label:
          'Legenda: check verde incluído no plano; cadeado requer upgrade; '
          'ícone destaque do plano; badge PRO indica Enterprise Pro',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PaywallLegendRow(
            icon: Icons.check_circle_rounded,
            iconColor: PaywallCatalog.green,
            label: 'Incluído no seu plano',
            style: style,
          ),
          const SizedBox(height: 4),
          _PaywallLegendRow(
            icon: Icons.lock_rounded,
            iconColor: mute.withValues(alpha: 0.72),
            label: 'Toque para ver upgrade',
            style: style,
          ),
          const SizedBox(height: 4),
          _PaywallLegendRow(
            icon: Icons.auto_awesome_rounded,
            iconColor: PaywallCatalog.brandDeep,
            label: 'Destaque do plano',
            style: style,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _PlanChip(label: 'PRO', color: PaywallCatalog.brandDeep),
              const SizedBox(width: 6),
              Expanded(child: Text('Requer Enterprise Pro', style: style)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaywallLegendRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final TextStyle style;

  const _PaywallLegendRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: style)),
      ],
    );
  }
}

/// ROI compacto — assinante Enterprise vendo o plano atual (upgrade para Pro).
class PaywallEnterpriseProRoiCard extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool isDark;
  final double? monthlyDelta;
  final VoidCallback? onExplorePro;

  const PaywallEnterpriseProRoiCard({
    super.key,
    required this.ink,
    required this.mute,
    required this.isDark,
    this.monthlyDelta,
    this.onExplorePro,
  });

  static const _bullets = <({String text, IconData icon})>[
    (
      text: 'Landing, Loja digital e Pose Coach no seu app',
      icon: Icons.auto_awesome_rounded,
    ),
    (
      text: 'Economize agência e desenvolvimento sob medida',
      icon: Icons.savings_outlined,
    ),
    (
      text: 'Escale alunos sem refazer infraestrutura',
      icon: Icons.trending_up_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(SubscriptionPlan.ENTERPRISE_PRO);
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final delta = monthlyDelta;
    final deltaLabel = delta != null && delta > 0
        ? '+R\$ ${delta.toStringAsFixed(0)}/mês'
        : null;

    return PaywallGlassCard(
      margin: EdgeInsets.zero,
      accent: accent,
      glow: false,
      blur: false,
      elevationLevel: 6,
      padding: const EdgeInsets.all(14),
      child: PaywallInsetPanel(
        accent: accent,
        isDark: isDark,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_rounded, size: 22, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Por que o Enterprise Pro?',
                    style: AppTypography.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      height: 1.25,
                      color: ink,
                    ),
                  ),
                ),
                if (deltaLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: PaywallCatalog.green.withValues(alpha: isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(TokensStrip.rPill),
                      border: Border.all(
                        color: PaywallCatalog.green.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      deltaLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: PaywallCatalog.green,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            for (final bullet in _bullets) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(bullet.icon, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bullet.text,
                        style: TokensStrip.body(color: secondary).copyWith(
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onExplorePro != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onExplorePro!();
                  },
                  icon: Icon(Icons.chevron_right_rounded, size: 18, color: accent),
                  label: Text(
                    'Ver Enterprise Pro',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: PaywallCatalog.readableTierAccent(accent, isDark: isDark),
                    ),
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

/// Convite discreto para explorar o tier Pro no Plan Studio.
class PaywallProExploreStrip extends StatelessWidget {
  final Color ink;
  final Color mute;
  final bool isDark;
  final VoidCallback onExplorePro;
  final String? roiTag;

  const PaywallProExploreStrip({
    super.key,
    required this.ink,
    required this.mute,
    required this.isDark,
    required this.onExplorePro,
    this.roiTag,
  });

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.brandDeep;
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final tag = roiTag?.trim();
    final proAccent = PaywallCatalog.accentForPlan(SubscriptionPlan.ENTERPRISE_PRO);
    return Semantics(
      button: true,
      label:
          'Landing, Loja digital e Pose Coach estão no Enterprise Pro. '
          '${tag != null && tag.isNotEmpty ? '$tag. ' : ''}'
          'Toque para ver o plano Pro',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onExplorePro();
          },
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TokensStrip.rSm),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        proAccent.withValues(alpha: isDark ? 0.14 : 0.08),
                        accent.withValues(alpha: isDark ? 0.06 : 0.03),
                      ],
                    ),
                  ),
                ),
              ),
              PaywallInsetPanel(
            accent: accent,
            isDark: isDark,
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded, size: 20, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Landing, Loja e Pose Coach estão no Enterprise Pro',
                    style: TokensStrip.body(color: secondary).copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (tag != null && tag.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: PaywallCatalog.green.withValues(alpha: isDark ? 0.16 : 0.1),
                      borderRadius: BorderRadius.circular(TokensStrip.rPill),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                        color: PaywallCatalog.green,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Icon(Icons.chevron_right_rounded, color: accent, size: 22),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanSectionTitle extends StatelessWidget {
  final String title;
  final Color accent;
  final Color mute;
  final Color ink;

  const _PlanSectionTitle({
    required this.title,
    required this.accent,
    required this.mute,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s3, bottom: TokensStrip.s2),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: PaywallCatalog.readableTierAccent(accent, isDark: isDark)
                  .withValues(alpha: 0.55),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                height: 1.25,
                color: labelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceBox extends StatelessWidget {
  final String label;
  final String price;
  final Color accent;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _PriceBox({
    required this.label,
    required this.price,
    required this.accent,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    this.selected = false,
    this.disabled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelected = selected && !disabled;
    final textInk = disabled ? mute.withValues(alpha: 0.55) : ink;

    final box = Opacity(
      opacity: disabled ? 0.5 : 1,
      child: FxGlassSurface(
        accent: accent,
        glow: effectiveSelected,
        blur: false,
        radius: TokensStrip.rSm,
        elevationLevel: effectiveSelected ? 8 : 3,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: mute,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textInk,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null || disabled) return box;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $price',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: box,
        ),
      ),
    );
  }
}

/// Downgrade / plano gratuito — só consulta; mudança de tier na loja.
class _PlanReferenceStoreHint extends StatelessWidget {
  final SubscriptionPlan plan;
  final Color ink;
  final Color mute;
  final Color accent;
  final bool isDark;

  const _PlanReferenceStoreHint({
    required this.plan,
    required this.ink,
    required this.mute,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final channel = subscriptionChannelLabel();
    final headline = plan == SubscriptionPlan.FREE
        ? 'Plano gratuito · referência'
        : 'Alteração só na $channel';
    final body = plan == SubscriptionPlan.FREE
        ? 'Compare limites com seu plano atual. Para voltar ao gratuito, use as assinaturas do dispositivo.'
        : 'Downgrade e cancelamento não são feitos no app. Abra as assinaturas do dispositivo para mudar de tier.';

    return PaywallInsetPanel(
      accent: accent,
      isDark: isDark,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            plan == SubscriptionPlan.FREE
                ? Icons.info_outline
                : Icons.storefront_outlined,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: AppTypography.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    height: 1.25,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TokensStrip.bodyMuted(color: secondary).copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Introdução do accordion «Outros planos» no Plan Studio.
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
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
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
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
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
                  style: AppTypography.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.2,
                    height: 1.2,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cobrança e renovação na ${subscriptionChannelLabel()}. '
                  'Valores exatos aparecem nas configurações da loja.',
                  style: TokensStrip.bodyMuted(color: secondary).copyWith(fontSize: 13),
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
                color: PaywallCatalog.readableSecondary(ink, mute, isDark: isDark),
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
          const Icon(Icons.savings_outlined, size: 16, color: PaywallCatalog.green),
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
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s1, bottom: TokensStrip.s3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackNote = constraints.maxWidth < 400 && note != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (stackNote) ...[
                Text(
                  title,
                  style: AppTypography.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: TokensStrip.fontH2,
                    letterSpacing: TokensStrip.trackingH2,
                    height: 1.15,
                    color: ink,
                  ),
                ),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  note!,
                  style: TokensStrip.bodyMuted(color: secondary).copyWith(
                    fontSize: TokensStrip.fontBodySm,
                    height: 1.4,
                  ),
                ),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: TokensStrip.fontH2,
                          letterSpacing: TokensStrip.trackingH2,
                          height: 1.15,
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
                          style: TokensStrip.bodyMuted(color: secondary).copyWith(
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
class PaywallCollapsibleBlock extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;
  final bool initiallyExpanded;
  final bool subscriberFlat;
  final bool expandRequested;

  const PaywallCollapsibleBlock({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
    this.initiallyExpanded = false,
    this.subscriberFlat = false,
    this.expandRequested = false,
  });

  @override
  State<PaywallCollapsibleBlock> createState() => _PaywallCollapsibleBlockState();
}

class _PaywallCollapsibleBlockState extends State<PaywallCollapsibleBlock> {
  late bool _expanded;
  late bool _mountedChild;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded || widget.expandRequested;
    _mountedChild = _expanded;
  }

  @override
  void didUpdateWidget(PaywallCollapsibleBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandRequested && !_expanded) {
      setState(() {
        _expanded = true;
        _mountedChild = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final flat = widget.subscriberFlat;
    final reducedMotion = TokensStrip.prefersReducedMotion(context);
    final useBlur = _expanded && !flat && !reducedMotion;
    return PaywallGlassCard(
      margin: const EdgeInsets.only(bottom: TokensStrip.s4),
      accent: PaywallCatalog.brandDeep,
      glow: false,
      glowStrength: 0.2,
      blur: useBlur,
      elevationLevel: flat ? 7 : (_expanded ? 10 : 7),
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          if (!flat)
            PaywallTierChrome.cardWash(
              accent: PaywallCatalog.brandDeep,
              isDark: widget.isDark,
              emphasis:
                  _expanded ? PaywallTierEmphasis.mid : PaywallTierEmphasis.low,
            ),
          if (!flat)
            PaywallTierChrome.accentRail(
              PaywallCatalog.brandDeep,
              emphasis:
                  _expanded ? PaywallTierEmphasis.mid : PaywallTierEmphasis.low,
            ),
          Theme(
            data: PaywallTierChrome.expansionTheme(context, TokensStrip.primary),
            child: Semantics(
              button: true,
              expanded: _expanded,
              label:
                  '${widget.title}. ${widget.subtitle}'
                  '${_expanded ? '' : '. Toque para expandir'}',
              hint: _expanded ? 'Recolher seção' : 'Expandir seção',
              child: ExpansionTile(
                initiallyExpanded: _expanded,
                onExpansionChanged: (open) {
                  setState(() {
                    _expanded = open;
                    if (open) _mountedChild = true;
                  });
                },
                tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                title: Text(
                  widget.title,
                  style: TokensStrip.h2(color: widget.ink).copyWith(fontSize: 17),
                ),
                subtitle: Text(
                  widget.subtitle,
                  style: TokensStrip.bodyMuted(color: widget.mute).copyWith(fontSize: 13),
                ),
                trailing: _PaywallExpandTrailing(expanded: _expanded, mute: widget.mute),
                children: [
                  AnimatedSize(
                    duration: TokensStrip.prefersReducedMotion(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _mountedChild ? widget.child : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallExpandTrailing extends StatelessWidget {
  final bool expanded;
  final Color mute;

  const _PaywallExpandTrailing({required this.expanded, required this.mute});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          expanded ? 'Recolher' : 'Ver detalhes',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: mute,
          ),
        ),
        const SizedBox(width: 2),
        AnimatedRotation(
          turns: expanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Icon(Icons.keyboard_arrow_down_rounded, color: mute, size: 22),
        ),
      ],
    );
  }
}

class PaywallRoiBundle extends StatelessWidget {
  final Color line;
  final Color ink;
  final Color mute;
  final bool isDark;

  const PaywallRoiBundle({
    super.key,
    required this.line,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaywallRoiStrip(line: line, ink: ink, mute: mute),
        const SizedBox(height: 12),
        PaywallRoiRowsList(ink: ink, mute: mute, line: line, isDark: isDark),
      ],
    );
  }
}

class _PaywallCompareDiffRow extends StatelessWidget {
  final String feature;
  final Color targetAccent;
  final Color ink;
  final Color mute;
  final bool isDark;
  final bool isLast;

  const _PaywallCompareDiffRow({
    required this.feature,
    required this.targetAccent,
    required this.ink,
    required this.mute,
    required this.isDark,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: PaywallInsetPanel(
        accent: targetAccent,
        isDark: isDark,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline_rounded, size: 18, color: targetAccent),
            const SizedBox(width: 10),
            Expanded(
              child: PaywallFeatureLabel(
                raw: feature,
                ink: ink,
                accent: targetAccent,
                maxLines: 2,
                style: TokensStrip.body(color: ink).copyWith(
                  fontSize: 13.5,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _PlanChip(label: 'SÓ PRO', color: targetAccent),
          ],
        ),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PlanChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = PaywallCatalog.readableTierAccent(color, isDark: isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        border: Border.all(color: color.withValues(alpha: isDark ? 0.38 : 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.35,
          height: 1.1,
          color: fg,
        ),
      ),
    );
  }
}

class PaywallFeatureLine extends StatelessWidget {
  final PaywallFeatureEducation feature;
  final Color accent;
  final Color mute;
  final Color ink;
  final VoidCallback? onHelp;
  final bool allowLockedTap;

  const PaywallFeatureLine({
    super.key,
    required this.feature,
    required this.accent,
    required this.mute,
    required this.ink,
    this.onHelp,
    this.allowLockedTap = true,
  });

  String _tierBadgeLabel(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.ENTERPRISE_PRO => 'PRO',
    SubscriptionPlan.ENTERPRISE => 'ENT',
    SubscriptionPlan.PREMIUM => 'PREMIUM',
    _ => 'FREE',
  };

  Future<void> _onLockedTap(BuildContext context) async {
    final parsed = PaywallCatalog.parseFeatureLabel(feature.row.label);
    await UpgradePromptSheet.show(
      context: context,
      featureName: parsed.label,
      capability: feature.capability,
      requiredPlan: feature.upgradePlan,
      source: 'paywall_feature_line',
    );
  }

  @override
  Widget build(BuildContext context) {
    final row = feature.row;
    final off = !row.included;
    final upgradePlan = feature.upgradePlan;
    final tierName = upgradePlan != null
        ? PaywallCatalog.displayPlanName(upgradePlan)
        : 'Enterprise Pro';
    final status = row.included
        ? 'Incluído no plano'
        : 'Bloqueado. Disponível no plano $tierName.'
            '${allowLockedTap ? " Toque para ver upgrade." : ""}';
    final lockedInk = mute.withValues(alpha: 0.72);
    final canTapLocked = off && allowLockedTap && upgradePlan != null;

    final rowBody = Row(
      children: [
        Icon(
          row.included ? Icons.check_circle_rounded : Icons.lock_rounded,
          size: 18,
          color: row.included ? PaywallCatalog.green : lockedInk,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PaywallFeatureLabel(
            raw: row.label,
            ink: off ? lockedInk : ink,
            accent: accent,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: row.highlight ? FontWeight.w800 : FontWeight.w500,
              color: off ? lockedInk : ink,
            ),
          ),
        ),
        if (off && upgradePlan != null)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Semantics(
              label: 'Requer plano $tierName',
              child: _PlanChip(
                label: _tierBadgeLabel(upgradePlan),
                color: PaywallCatalog.accentForPlan(upgradePlan),
              ),
            ),
          ),
        if (row.highlight && row.included)
          Semantics(
            label: 'Destaque do plano',
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: PaywallCatalog.brandDeep,
            ),
          ),
        if (row.comingSoon)
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: _PlanChip(label: 'EM BREVE', color: PaywallCatalog.warning),
          ),
        if (feature.education != null)
          Semantics(
            button: true,
            label: 'Saiba mais sobre ${row.label}',
            child: IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              icon: Icon(Icons.help_outline_rounded, size: 18, color: mute),
              onPressed: () {
                onHelp?.call();
                final parsed = PaywallCatalog.parseFeatureLabel(row.label);
                showPaywallFeatureEducation(
                  context,
                  feature.education!,
                  onViewPlan: feature.upgradePlan != null
                      ? () {
                          UpgradePromptSheet.show(
                            context: context,
                            featureName: parsed.label,
                            capability: feature.capability,
                            requiredPlan: feature.upgradePlan!,
                            source: 'paywall_education_sheet',
                          );
                        }
                      : null,
                );
              },
            ),
          ),
        if (canTapLocked)
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: mute.withValues(alpha: 0.55),
          ),
      ],
    );

    final padded = Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: rowBody,
    );

    if (!canTapLocked) {
      return Semantics(label: status, child: padded);
    }

    return Semantics(
      button: true,
      label: status,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _onLockedTap(context);
          },
          borderRadius: BorderRadius.circular(TokensStrip.rSm),
          child: padded,
        ),
      ),
    );
  }
}

SubscriptionPlan? _educationTargetPlan(List<String> planNames) {
  SubscriptionPlan? best;
  for (final name in planNames) {
    final tier = subscriptionPlanFromApi(name);
    if (best == null || tier.level > best.level) best = tier;
  }
  return best;
}

void showPaywallFeatureEducation(
  BuildContext context,
  PaywallEducationContent content, {
  VoidCallback? onViewPlan,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final sheetInk = isDark ? EagleTokens.darkInk : TokensStrip.textPrimary;
  final sheetMute = isDark ? EagleTokens.darkInkMute : TokensStrip.textSecondary;
  final sheetLine = isDark ? EagleTokens.darkLine : EagleTokens.line;
  final targetPlan = _educationTargetPlan(content.plans);
  final targetLabel = targetPlan == null
      ? null
      : PaywallCatalog.displayPlanName(targetPlan);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scroll) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: TokensStrip.blurFilter(TokensStrip.blurMedium),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: TokensStrip.glassFill(
                    dark: isDark,
                    opacity: isDark ? 0.92 : 0.96,
                  ),
                  border: Border(
                    top: BorderSide(color: sheetLine.withValues(alpha: 0.5)),
                  ),
                ),
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: sheetLine,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                content.title,
                style: TokensStrip.h2(color: sheetInk),
              ),
              const SizedBox(height: 16),
              Text(
                'O que é',
                style: TextStyle(
                  color: PaywallCatalog.brandDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(content.whatIs, style: TokensStrip.body(color: sheetMute)),
              const SizedBox(height: 14),
              Text(
                'Por que importa pra você',
                style: TextStyle(
                  color: PaywallCatalog.brandDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(content.whyMatters, style: TokensStrip.body(color: sheetMute)),
              if (content.roiStatement != null) ...[
                const SizedBox(height: 14),
                PaywallInsetPanel(
                  accent: PaywallCatalog.green,
                  isDark: isDark,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.savings_outlined,
                        size: 18,
                        color: PaywallCatalog.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          content.roiStatement!,
                          style: const TextStyle(
                            color: PaywallCatalog.green,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Disponível em',
                style: TextStyle(
                  color: PaywallCatalog.brandDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: content.plans
                    .map((p) => _PlanChip(label: p, color: PaywallCatalog.accentForPlan(
                      subscriptionPlanFromApi(p),
                    )))
                    .toList(),
              ),
              if (targetPlan != null && onViewPlan != null) ...[
                const SizedBox(height: 20),
                FxLiquidPrimaryButton(
                  label: 'Ver $targetLabel',
                  icon: Icons.workspace_premium_rounded,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onViewPlan();
                  },
                ),
              ],
              const SizedBox(height: 10),
              FxLiquidSecondaryButton(
                label: 'Fechar',
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
        },
      );
    },
  );
}

// ─── ROI calculator ─────────────────────────────────────────────────────────

class PaywallRoiCalculator extends StatefulWidget {
  final List<Plano> paidPlans;
  final Color ink;
  final Color mute;
  final Color line;
  final ValueChanged<SubscriptionPlan>? onSuggestPlan;

  const PaywallRoiCalculator({
    super.key,
    required this.paidPlans,
    required this.ink,
    required this.mute,
    required this.line,
    this.onSuggestPlan,
  });

  @override
  State<PaywallRoiCalculator> createState() => _PaywallRoiCalculatorState();
}

class _PaywallRoiCalculatorState extends State<PaywallRoiCalculator> {
  bool _expanded = false;
  int _students = 12;
  double _monthlyFee = 400;
  late final TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _feeController = TextEditingController(text: _monthlyFee.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mrr = _students * _monthlyFee;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: widget.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            label: 'Calculadora de ROI, ${_expanded ? 'recolher' : 'expandir'}',
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.calculate_outlined, size: 26, color: PaywallCatalog.brand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calcule seu ROI', style: TokensStrip.h2(color: widget.ink).copyWith(fontSize: 17)),
                          Text(
                            'Veja qual plano faz sentido agora',
                            style: TokensStrip.bodyMuted(color: widget.mute),
                          ),
                        ],
                      ),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: widget.mute),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Alunos ativos hoje', style: TokensStrip.bodyMuted(color: widget.mute)),
                  Slider(
                    value: _students.toDouble(),
                    min: 0,
                    max: 50,
                    divisions: 50,
                    label: '$_students',
                    onChanged: (v) => setState(() => _students = v.round()),
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Mensalidade média (R\$)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    controller: _feeController,
                    onChanged: (v) {
                      final n = double.tryParse(v.replaceAll(',', '.'));
                      if (n != null) {
                        setState(() => _monthlyFee = n.clamp(50, 5000));
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: PaywallCatalog.brand.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Seu MRR atual', style: TokensStrip.bodyMuted(color: widget.mute)),
                        Text(
                          'R\$ ${mrr.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: widget.ink,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.paidPlans.map((p) {
                    final plan = subscriptionPlanFromApi(p.nome);
                    final price = p.precoMensal;
                    final pct = mrr > 0 ? (price / mrr * 100) : 0.0;
                    final payback = price > 0 ? (price / _monthlyFee).ceil() : 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${PaywallCatalog.displayPlanName(plan)} · R\$ ${price.toStringAsFixed(2)}/mês',
                              style: TokensStrip.body(color: widget.ink),
                            ),
                          ),
                          Text(
                            mrr > 0 ? '${pct.toStringAsFixed(1)}% MRR' : '—',
                            style: TextStyle(
                              color: PaywallCatalog.accentForPlan(plan),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            payback <= 1 ? '1 aluno paga' : '$payback alunos',
                            style: TokensStrip.bodyMuted(color: widget.mute).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (mrr > 0 && widget.paidPlans.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Premium = ${(widget.paidPlans.first.precoMensal / mrr * 100).toStringAsFixed(2)}% do faturamento'
                      '${widget.paidPlans.first.precoMensal / mrr < 0.01 ? ' — menos de 1%, ROI imediato' : ''}',
                      style: TokensStrip.bodyMuted(color: widget.mute),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Comparison table ─────────────────────────────────────────────────────────

class PaywallComparisonTable extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const PaywallComparisonTable({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  static const double _featureColWidth = 168;
  static const double _tierColWidth = 64;

  TextStyle _cellStyle({bool header = false, bool feature = false}) => TextStyle(
    color: header ? ink : (feature ? ink : mute),
    fontSize: header ? 12 : 12,
    fontWeight: header || feature ? FontWeight.w700 : FontWeight.w500,
    height: 1.25,
  );

  Widget _cell(
    String text, {
    bool header = false,
    bool feature = false,
    double? width,
    TextAlign align = TextAlign.left,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Text(
          text,
          textAlign: align,
          style: _cellStyle(header: header, feature: feature),
          maxLines: header ? 2 : 4,
          softWrap: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerBg = isDark ? EagleTokens.darkCardHi : EagleTokens.paper;
    final rowDivider = line.withValues(alpha: 0.5);
    final tableWidth = _featureColWidth + _tierColWidth * 4;

    return Semantics(
      label: 'Tabela de comparação de planos, 4 tiers, ${PaywallCatalog.comparisonRows.length} recursos',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 4),
        child: SizedBox(
          width: tableWidth,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: {
              0: const FixedColumnWidth(_featureColWidth),
              1: const FixedColumnWidth(_tierColWidth),
              2: const FixedColumnWidth(_tierColWidth),
              3: const FixedColumnWidth(_tierColWidth),
              4: const FixedColumnWidth(_tierColWidth),
            },
            border: TableBorder(
              horizontalInside: BorderSide(color: rowDivider, width: 1),
              bottom: BorderSide(color: rowDivider),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(color: headerBg),
                children: [
                  _cell('Recurso', header: true, width: _featureColWidth),
                  _cell('FREE', header: true, width: _tierColWidth, align: TextAlign.center),
                  _cell('PREM.', header: true, width: _tierColWidth, align: TextAlign.center),
                  _cell('ENT.', header: true, width: _tierColWidth, align: TextAlign.center),
                  _cell('PRO', header: true, width: _tierColWidth, align: TextAlign.center),
                ],
              ),
              ...PaywallCatalog.comparisonRows.map(
                (r) => TableRow(
                  children: [
                    _cell(r.feature, feature: true, width: _featureColWidth),
                    _cell(r.free, width: _tierColWidth, align: TextAlign.center),
                    _cell(r.premium, width: _tierColWidth, align: TextAlign.center),
                    _cell(r.enterprise, width: _tierColWidth, align: TextAlign.center),
                    _cell(r.enterprisePro, width: _tierColWidth, align: TextAlign.center),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PaywallFeaturesGrid extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const PaywallFeaturesGrid({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final border = isDark ? EagleTokens.darkLine : line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final f in PaywallCatalog.topFeatures)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: PaywallCatalog.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(f.icon, color: PaywallCatalog.brand, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${f.rank} ${f.title}',
                        style: TokensStrip.h2(color: ink).copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      _PlanChip(label: f.badge, color: f.badgeColor),
                      const SizedBox(height: 8),
                      Text(
                        f.description,
                        style: TokensStrip.bodyMuted(color: mute).copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                      _RoiMoneyTag(text: f.roiMoney),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: f.planChips
                            .map((p) => _PlanChip(label: p, color: paywallChipColorForLabel(p)))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class PaywallRoiRowsList extends StatelessWidget {
  final Color ink;
  final Color mute;
  final Color line;
  final bool isDark;

  const PaywallRoiRowsList({
    super.key,
    required this.ink,
    required this.mute,
    required this.line,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? EagleTokens.darkCard : EagleTokens.card;
    final border = isDark ? EagleTokens.darkLine : line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...PaywallCatalog.roiRows.map(
          (r) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: border),
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final stacked = c.maxWidth < 340;
                final value = Text(
                  r.value,
                  style: TextStyle(
                    color: PaywallCatalog.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                );
                final chip = _PlanChip(label: r.planChip, color: r.color);
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.label, style: TokensStrip.body(color: ink)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: value),
                          chip,
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(r.label, style: TokensStrip.body(color: ink)),
                    ),
                    Expanded(flex: 2, child: value),
                    const SizedBox(width: 8),
                    chip,
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

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
    final chrome = ShellChrome.of(context);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 12),
          child: DecoratedBox(
            decoration: chrome.bottomSheet(radius: PaywallSurface.cardRadius),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Termos e cobrança',
                      style: TokensStrip.h2(color: ink).copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
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
            style: TokensStrip.bodyMuted(color: secondary).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Abrir termos, privacidade e informações de cobrança',
            child: TextButton.icon(
              onPressed: () => showBillingSheet(
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
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);

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

  const PaywallTrustFooter({super.key, required this.mute, required this.primary});

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

// ─── Skeleton ─────────────────────────────────────────────────────────────────

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
          Container(height: 120, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 16),
          Container(height: 56, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14))),
          const SizedBox(height: 16),
          for (var i = 0; i < 3; i++)
            Container(
              height: 180,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(PaywallSurface.cardRadius),
              ),
            ),
        ],
      ),
    );
  }
}

String formatPaywallPriceBrl(double value) {
  if (value == 0) return 'R\$ 0';
  final whole = value == value.roundToDouble();
  return whole
      ? 'R\$ ${value.toStringAsFixed(0)}'
      : 'R\$ ${value.toStringAsFixed(2)}';
}

String paywallMonthlyFromPlano(Plano plano) => formatPaywallPriceBrl(plano.precoMensal);

String paywallAnnualMonthlyEquiv(Plano plano) {
  final annual = plano.precoAnual ?? SubscriptionProducts.referenceAnnualPrice(plano.precoMensal);
  return formatPaywallPriceBrl(annual / 12);
}

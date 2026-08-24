import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/subscription_products.dart';
import 'paywall_catalog.dart';
import 'paywall_compare_logic.dart';
import 'paywall_glass.dart';

/// Fold de planos: hero + abas + um card (IA ChatGPT, visual Home).
class PaywallCompareStage extends StatelessWidget {
  const PaywallCompareStage({
    super.key,
    required this.plans,
    required this.currentPlan,
    required this.selectedPlan,
    required this.comparisonRows,
    required this.billingPeriod,
    required this.onSelectPlan,
    required this.ink,
    required this.mute,
    required this.primary,
    required this.isDark,
    this.line,
    this.roiTag,
    this.onBillingPeriod,
  });

  final List<SubscriptionPlan> plans;
  final SubscriptionPlan currentPlan;
  final SubscriptionPlan selectedPlan;
  final List<PaywallComparisonRow> comparisonRows;
  final SubscriptionBillingPeriod billingPeriod;
  final ValueChanged<SubscriptionPlan> onSelectPlan;
  final ValueChanged<SubscriptionBillingPeriod>? onBillingPeriod;
  final Color ink;
  final Color mute;
  final Color primary;
  final bool isDark;
  final Color? line;
  final String? roiTag;

  @override
  Widget build(BuildContext context) {
    final view = buildPaywallCompareView(
      selected: selectedPlan,
      current: currentPlan,
      rows: comparisonRows,
    );
    final accent = PaywallCatalog.accentForPlan(selectedPlan);
    final reduced = TokensStrip.prefersReducedMotion(context);
    final duration =
        reduced ? Duration.zero : const Duration(milliseconds: 220);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: duration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _CompareHero(
            key: ValueKey(selectedPlan),
            view: view,
            selectedPlan: selectedPlan,
            accent: accent,
            ink: ink,
            mute: mute,
            isDark: isDark,
          ),
        ),
        const SizedBox(height: TokensStrip.s4),
        _PlanTabs(
          plans: plans,
          selected: selectedPlan,
          current: currentPlan,
          ink: ink,
          mute: mute,
          accent: accent,
          onSelect: onSelectPlan,
        ),
        if (view.showBillingToggle && onBillingPeriod != null) ...[
          const SizedBox(height: TokensStrip.s3),
          _BillingTabs(
            period: billingPeriod,
            accent: accent,
            ink: ink,
            mute: mute,
            onChanged: onBillingPeriod!,
          ),
        ],
        const SizedBox(height: TokensStrip.s4),
        AnimatedSwitcher(
          duration: duration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _CompareCard(
            key: ValueKey('${selectedPlan.name}-${view.showTwoColumns}'),
            view: view,
            accent: accent,
            ink: ink,
            mute: mute,
            isDark: isDark,
            line: line,
            roiTag: roiTag,
          ),
        ),
      ],
    );
  }
}

class _CompareHero extends StatelessWidget {
  const _CompareHero({
    super.key,
    required this.view,
    required this.selectedPlan,
    required this.accent,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  final PaywallCompareView view;
  final SubscriptionPlan selectedPlan;
  final Color accent;
  final Color ink;
  final Color mute;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s3),
      child: Column(
        children: [
          PaywallTierMedallion(
            plan: selectedPlan,
            accent: accent,
            isDark: isDark,
            size: TokensStrip.s8,
          ),
          const SizedBox(height: TokensStrip.s4),
          Text(
            view.headline,
            textAlign: TextAlign.center,
            style: FocuxHubTypography.pageTitle(context, color: ink),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            view.subtitle,
            textAlign: TextAlign.center,
            style: FocuxHubTypography.bodyMuted(color: secondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _PlanTabs extends StatelessWidget {
  const _PlanTabs({
    required this.plans,
    required this.selected,
    required this.current,
    required this.ink,
    required this.mute,
    required this.accent,
    required this.onSelect,
  });

  final List<SubscriptionPlan> plans;
  final SubscriptionPlan selected;
  final SubscriptionPlan current;
  final Color ink;
  final Color mute;
  final Color accent;
  final ValueChanged<SubscriptionPlan> onSelect;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Escolher plano',
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s1),
        decoration: fxListCardDecoration(
          context,
          accent: accent,
          radius: TokensStrip.rPill,
        ),
        child: Row(
          children: [
            for (final plan in plans)
              Expanded(
                child: _TabChip(
                  label: paywallTabLabel(plan),
                  semanticLabel:
                      '${paywallPrettyName(plan)}'
                      '${plan == current ? ', plano atual' : ''}',
                  selected: plan == selected,
                  accent: accent,
                  ink: ink,
                  mute: mute,
                  onTap: () {
                    if (plan == selected) return;
                    HapticFeedback.selectionClick();
                    onSelect(plan);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BillingTabs extends StatelessWidget {
  const _BillingTabs({
    required this.period,
    required this.accent,
    required this.ink,
    required this.mute,
    required this.onChanged,
  });

  final SubscriptionBillingPeriod period;
  final Color accent;
  final Color ink;
  final Color mute;
  final ValueChanged<SubscriptionBillingPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Período de cobrança',
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s1),
        decoration: fxListCardDecoration(
          context,
          accent: accent,
          radius: TokensStrip.rPill,
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabChip(
                label: 'Mensal',
                semanticLabel: 'Cobrança mensal',
                selected: period == SubscriptionBillingPeriod.monthly,
                accent: accent,
                ink: ink,
                mute: mute,
                onTap: () {
                  if (period == SubscriptionBillingPeriod.monthly) return;
                  HapticFeedback.selectionClick();
                  onChanged(SubscriptionBillingPeriod.monthly);
                },
              ),
            ),
            Expanded(
              child: _TabChip(
                label: 'Anual',
                semanticLabel: 'Cobrança anual',
                selected: period == SubscriptionBillingPeriod.yearly,
                accent: accent,
                ink: ink,
                mute: mute,
                onTap: () {
                  if (period == SubscriptionBillingPeriod.yearly) return;
                  HapticFeedback.selectionClick();
                  onChanged(SubscriptionBillingPeriod.yearly);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    required this.accent,
    required this.ink,
    required this.mute,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final Color accent;
  final Color ink;
  final Color mute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : mute;
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rPill),
          child: AnimatedContainer(
            duration: TokensStrip.prefersReducedMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 160),
            height: TokensStrip.s7,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(TokensStrip.rPill),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s2),
                child: Text(
                  label,
                  maxLines: 1,
                  style: FocuxHubTypography.chip(fg),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({
    super.key,
    required this.view,
    required this.accent,
    required this.ink,
    required this.mute,
    required this.isDark,
    this.line,
    this.roiTag,
  });

  final PaywallCompareView view;
  final Color accent;
  final Color ink;
  final Color mute;
  final bool isDark;
  final Color? line;
  final String? roiTag;

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    return PaywallGlassCard(
      accent: accent,
      glow: !TokensStrip.prefersReducedMotion(context),
      glowStrength: 0.28,
      blur: false,
      elevationLevel: 10,
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s4,
        TokensStrip.s4,
        TokensStrip.s3,
      ),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          _HeaderRow(
            showTwo: view.showTwoColumns,
            baseline: view.baselineColumnLabel,
            selected: view.selectedColumnLabel,
            ink: ink,
            mute: secondary,
            accent: accent,
          ),
          const SizedBox(height: TokensStrip.s3),
          for (var i = 0; i < view.rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: TokensStrip.s4,
                color:
                    line ?? ink.withValues(alpha: isDark ? 0.12 : 0.06),
              ),
            _FeatureRow(
              row: view.rows[i],
              showTwo: view.showTwoColumns,
              accent: accent,
              ink: ink,
              mute: secondary,
            ),
          ],
          if (roiTag != null && roiTag!.trim().isNotEmpty) ...[
            const SizedBox(height: TokensStrip.s3),
            Text(
              roiTag!.trim(),
              textAlign: TextAlign.center,
              style: FocuxHubTypography.chip(accent),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.showTwo,
    required this.baseline,
    required this.selected,
    required this.ink,
    required this.mute,
    required this.accent,
  });

  final bool showTwo;
  final String baseline;
  final String selected;
  final Color ink;
  final Color mute;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            'Recursos',
            style: FocuxHubTypography.chip(mute),
          ),
        ),
        if (showTwo)
          SizedBox(
            width: 56,
            child: Text(
              baseline,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.chip(mute),
            ),
          ),
        SizedBox(
          width: 64,
          child: Text(
            selected,
            textAlign: TextAlign.center,
            style: FocuxHubTypography.chip(accent),
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.row,
    required this.showTwo,
    required this.accent,
    required this.ink,
    required this.mute,
  });

  final PaywallCompareRow row;
  final bool showTwo;
  final Color accent;
  final Color ink;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              row.feature,
              style: TokensStrip.body(color: ink).copyWith(
                fontSize: TokensStrip.fontBodySm,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
          if (showTwo)
            SizedBox(
              width: 56,
              child: _Cell(value: row.baseline, accent: mute, muted: true),
            ),
          SizedBox(
            width: 64,
            child: _Cell(value: row.selected, accent: accent, muted: false),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.value,
    required this.accent,
    required this.muted,
  });

  final String value;
  final Color accent;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (!paywallCompareCellIncluded(value)) {
      return Text(
        '—',
        textAlign: TextAlign.center,
        style: FocuxHubTypography.chip(accent.withValues(alpha: 0.55)),
      );
    }
    if (value.trim() == '✓') {
      return Icon(
        Icons.check_rounded,
        size: 20,
        color: muted ? accent.withValues(alpha: 0.7) : accent,
      );
    }
    return Text(
      value,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: FocuxHubTypography.chip(accent),
    );
  }
}

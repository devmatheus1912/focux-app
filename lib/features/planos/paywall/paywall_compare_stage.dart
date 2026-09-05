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

/// Colunas de valor — mesma largura no header e na célula (eixo único).
const double _kValueCol = 80;

/// Números da paywall — Barlow Condensed, mesmo role KPI da Home.
TextStyle paywallNumberStyle({
  required Color color,
  double fontSize = TokensStrip.fontBodySm,
}) {
  return FocuxHubTypography.kpi(
    color: color,
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
  );
}

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
    required this.isDark,
    this.line,
    this.roiTag,
    this.onBillingPeriod,
    this.fillViewport = false,
    this.managementMode = false,
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
  final bool isDark;
  final Color? line;
  final String? roiTag;

  /// Preenche o viewport restante (sem faixa branca entre o card e o sticky).
  final bool fillViewport;

  /// Plano máximo ativo: status / loja / cancelar — não vitrine de upgrade.
  final bool managementMode;

  @override
  Widget build(BuildContext context) {
    final view = buildPaywallCompareView(
      selected: selectedPlan,
      current: currentPlan,
      rows: comparisonRows,
      managementMode: managementMode,
    );
    final accent = PaywallCatalog.accentForPlan(selectedPlan);
    final reduced = TokensStrip.prefersReducedMotion(context);
    final duration =
        reduced ? Duration.zero : const Duration(milliseconds: 220);
    final managingCurrent =
        managementMode && selectedPlan == currentPlan;
    final tag = managingCurrent
        ? null
        : (roiTag != null && roiTag!.trim().isNotEmpty)
            ? roiTag!.trim()
            : PaywallCatalog.roiTagForPlan(selectedPlan);

    final card = AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: fillViewport
          ? SizedBox.expand(
              key: ValueKey('${selectedPlan.name}-${view.showTwoColumns}'),
              child: _CompareCard(
                view: view,
                accent: accent,
                ink: ink,
                mute: mute,
                isDark: isDark,
                line: line,
                roiTag: tag,
                expand: true,
              ),
            )
          : _CompareCard(
              key: ValueKey('${selectedPlan.name}-${view.showTwoColumns}'),
              view: view,
              accent: accent,
              ink: ink,
              mute: mute,
              isDark: isDark,
              line: line,
              roiTag: tag,
            ),
    );

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
        const SizedBox(height: TokensStrip.s3),
        _PlanTabs(
          plans: plans,
          selected: selectedPlan,
          current: currentPlan,
          mute: mute,
          accent: accent,
          onSelect: onSelectPlan,
        ),
        if (view.showBillingToggle && onBillingPeriod != null) ...[
          const SizedBox(height: TokensStrip.s2),
          _BillingTabs(
            period: billingPeriod,
            accent: accent,
            mute: mute,
            onChanged: onBillingPeriod!,
          ),
        ],
        const SizedBox(height: TokensStrip.s3),
        if (fillViewport) Expanded(child: card) else card,
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
      padding: const EdgeInsets.only(top: TokensStrip.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: PaywallTierMedallion(
              plan: selectedPlan,
              accent: accent,
              isDark: isDark,
              size: TokensStrip.s7,
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          Text(
            view.headline,
            textAlign: TextAlign.center,
            style: FocuxHubTypography.sectionTitle(context, color: ink),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            view.subtitle,
            textAlign: TextAlign.center,
            style: FocuxHubTypography.bodyMuted(
              color: secondary,
              height: 1.35,
            ),
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
    required this.mute,
    required this.accent,
    required this.onSelect,
  });

  final List<SubscriptionPlan> plans;
  final SubscriptionPlan selected;
  final SubscriptionPlan current;
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
                key: ValueKey('paywall-tab-${plan.name}'),
                child: _TabChip(
                  label: paywallTabLabel(plan),
                  semanticLabel:
                      '${paywallPrettyName(plan)}'
                      '${plan == current ? ', plano atual' : ''}',
                  selected: plan == selected,
                  accent: accent,
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
    required this.mute,
    required this.onChanged,
  });

  final SubscriptionBillingPeriod period;
  final Color accent;
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
                caption: '2 meses grátis',
                semanticLabel: 'Cobrança anual, 2 meses grátis',
                selected: period == SubscriptionBillingPeriod.yearly,
                accent: accent,
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
    required this.mute,
    required this.onTap,
    this.caption,
  });

  final String label;
  final String? caption;
  final String semanticLabel;
  final bool selected;
  final Color accent;
  final Color mute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? TokensStrip.cardBg : mute;
    final labelStyle = FocuxHubTypography.chip(fg);
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
            padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s2),
            decoration: BoxDecoration(
              color: selected ? accent : Colors.transparent,
              borderRadius: BorderRadius.circular(TokensStrip.rPill),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
                if (caption != null)
                  Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: labelStyle.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
              ],
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
    this.expand = false,
  });

  final PaywallCompareView view;
  final Color accent;
  final Color ink;
  final Color mute;
  final bool isDark;
  final Color? line;
  final String? roiTag;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    final selectedAccent =
        view.selected == SubscriptionPlan.FREE ? ink : accent;
    final divider = line ?? ink.withValues(alpha: isDark ? 0.12 : 0.06);
    final tag = roiTag?.trim();

    final table = _CompareTable(
      view: view,
      accent: selectedAccent,
      ink: ink,
      mute: secondary,
      divider: divider,
    );
    final footer = <Widget>[
      if (tag != null && tag.isNotEmpty) ...[
        const SizedBox(height: TokensStrip.s3),
        Text(
          tag,
          textAlign: TextAlign.center,
          style: FocuxHubTypography.chip(selectedAccent),
        ),
      ],
    ];

    final body = expand
        ? ListView(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            children: [table, ...footer],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [table, ...footer],
          );

    final card = PaywallGlassCard(
      accent: accent,
      glow: !TokensStrip.prefersReducedMotion(context),
      glowStrength: 0.28,
      blur: false,
      expand: expand,
      elevationLevel: 10,
      padding: const EdgeInsets.fromLTRB(
        TokensStrip.s4,
        TokensStrip.s4,
        TokensStrip.s4,
        TokensStrip.s4,
      ),
      margin: EdgeInsets.zero,
      child: expand ? SizedBox.expand(child: body) : body,
    );
    if (!expand) return card;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) return card;
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: card,
        );
      },
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({
    required this.view,
    required this.accent,
    required this.ink,
    required this.mute,
    required this.divider,
  });

  final PaywallCompareView view;
  final Color accent;
  final Color ink;
  final Color mute;
  final Color divider;

  @override
  Widget build(BuildContext context) {
    final showTwo = view.showTwoColumns;
    return Table(
      columnWidths: {
        0: const FlexColumnWidth(1),
        if (showTwo) 1: const FixedColumnWidth(_kValueCol),
        showTwo ? 2 : 1: const FixedColumnWidth(_kValueCol),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      border: TableBorder(
        horizontalInside: BorderSide(color: divider),
      ),
      children: [
        TableRow(
          children: [
            _labelCell(
              'Recursos',
              style: FocuxHubTypography.chip(mute),
              align: TextAlign.start,
            ),
            if (showTwo)
              _labelCell(
                view.baselineColumnLabel,
                style: FocuxHubTypography.chip(mute),
              ),
            _labelCell(
              view.selectedColumnLabel,
              style: FocuxHubTypography.chip(accent),
            ),
          ],
        ),
        for (final row in view.rows)
          TableRow(
            children: [
              _labelCell(
                row.feature,
                style: FocuxHubTypography.cardTitle(color: ink),
                align: TextAlign.start,
              ),
              if (showTwo)
                _Cell(value: row.baseline, accent: mute, muted: true),
              _Cell(value: row.selected, accent: accent, muted: false),
            ],
          ),
      ],
    );
  }

  Widget _labelCell(
    String text, {
    required TextStyle style,
    TextAlign align = TextAlign.center,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
      child: Text(
        text,
        textAlign: align,
        style: style,
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
    final child = !paywallCompareCellIncluded(value)
        ? Text(
            '—',
            textAlign: TextAlign.center,
            style: FocuxHubTypography.chip(accent.withValues(alpha: 0.55)),
          )
        : value.trim() == '✓'
        ? Icon(
            Icons.check_rounded,
            size: 20,
            color: muted ? accent.withValues(alpha: 0.7) : accent,
          )
        : Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: paywallNumberStyle(color: accent),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensStrip.s2),
      child: Center(child: child),
    );
  }
}

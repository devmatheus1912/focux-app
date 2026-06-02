import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_typography.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../assinatura/data/plano.dart';
import '../../subscription/models/subscription_plan.dart';
import 'paywall_catalog.dart';
// subscriptionPlanFromApi → subscription_plan.dart
import 'paywall_components.dart';

/// Card único para assinante — alterna tier no mesmo shell (preço + features + compare).
class PaywallPlanStudio extends StatelessWidget {
  const PaywallPlanStudio({
    super.key,
    required this.currentPlan,
    required this.selectedPlan,
    required this.studioPlanos,
    required this.onPlanSelected,
    required this.planContent,
    required this.ink,
    required this.mute,
    required this.isDark,
    this.compareSection,
    this.belowPlanSection,
    this.isMaxTier = false,
    this.roiTag,
  });

  final SubscriptionPlan currentPlan;
  final SubscriptionPlan selectedPlan;
  final List<Plano> studioPlanos;
  final ValueChanged<SubscriptionPlan> onPlanSelected;
  final Widget planContent;
  final Color ink;
  final Color mute;
  final bool isDark;
  final Widget? compareSection;
  final Widget? belowPlanSection;
  final bool isMaxTier;
  final String? roiTag;

  @override
  Widget build(BuildContext context) {
    final secondary = PaywallCatalog.readableSecondary(ink, mute, isDark: isDark);
    final showPicker = studioPlanos.length > 1 && !isMaxTier;

    Plano? currentPlano;
    for (final p in studioPlanos) {
      if (subscriptionPlanFromApi(p.nome) == currentPlan) {
        currentPlano = p;
        break;
      }
    }
    final statusLabel = currentPlano == null
        ? PaywallCatalog.displayPlanName(currentPlan)
        : PaywallCatalog.displayNameFor(
            currentPlano,
            currentPlan,
          );

    return PaywallTierCard(
      plan: selectedPlan,
      isDark: isDark,
      isCurrent: selectedPlan == currentPlan,
      isSelected: true,
      glow: !TokensStrip.prefersReducedMotion(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                PaywallTierMedallion(
                  plan: currentPlan,
                  accent: PaywallCatalog.accentForPlan(currentPlan),
                  isDark: isDark,
                  size: 40,
                ),
                const SizedBox(width: TokensStrip.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PaywallTierBrandPill(
                        label: 'FOCUX · $statusLabel',
                        accent: PaywallCatalog.accentForPlan(currentPlan),
                        isDark: isDark,
                        icon: Icons.verified_rounded,
                      ),
                      const SizedBox(height: TokensStrip.s2),
                      Text(
                        isMaxTier
                            ? 'Plano máximo ativo'
                            : !showPicker
                            ? 'Gerencie na loja do dispositivo'
                            : selectedPlan == currentPlan
                            ? 'Recursos e cobrança do seu plano'
                            : 'O que inclui neste plano',
                        style: TokensStrip.bodyMuted(color: secondary).copyWith(
                          fontSize: TokensStrip.fontBodySm,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showPicker) ...[
            const SizedBox(height: TokensStrip.s3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PaywallStudioPlanPicker(
                planos: studioPlanos,
                currentPlan: currentPlan,
                selectedPlan: selectedPlan,
                isDark: isDark,
                ink: ink,
                mute: mute,
                onSelected: onPlanSelected,
              ),
            ),
          ],
          if (showPicker &&
              currentPlan == SubscriptionPlan.ENTERPRISE &&
              selectedPlan == SubscriptionPlan.ENTERPRISE) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: PaywallProExploreStrip(
                ink: ink,
                mute: mute,
                isDark: isDark,
                roiTag: roiTag,
                onExplorePro: () => onPlanSelected(SubscriptionPlan.ENTERPRISE_PRO),
              ),
            ),
          ],
          const SizedBox(height: TokensStrip.s2),
          AnimatedSwitcher(
            duration: TokensStrip.prefersReducedMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: KeyedSubtree(
              key: ValueKey<SubscriptionPlan>(selectedPlan),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  planContent,
                  if (belowPlanSection != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: belowPlanSection!,
                    ),
                  ],
                  if (compareSection != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      child: compareSection!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaywallStudioPlanPicker extends StatelessWidget {
  const _PaywallStudioPlanPicker({
    required this.planos,
    required this.currentPlan,
    required this.selectedPlan,
    required this.onSelected,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  final List<Plano> planos;
  final SubscriptionPlan currentPlan;
  final SubscriptionPlan selectedPlan;
  final ValueChanged<SubscriptionPlan> onSelected;
  final Color ink;
  final Color mute;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final sorted = [...planos]
      ..sort(
        (a, b) => subscriptionPlanFromApi(a.nome).level.compareTo(
          subscriptionPlanFromApi(b.nome).level,
        ),
      );

    return Semantics(
      label: 'Selecionar plano para visualizar',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TokensStrip.rPill),
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : TokensStrip.pageBg.withValues(alpha: 0.85),
          border: Border.all(
            color: mute.withValues(alpha: isDark ? 0.25 : 0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (var i = 0; i < sorted.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: _PaywallStudioSegment(
                    plano: sorted[i],
                    plan: subscriptionPlanFromApi(sorted[i].nome),
                    isCurrent: subscriptionPlanFromApi(sorted[i].nome) == currentPlan,
                    isSelected:
                        subscriptionPlanFromApi(sorted[i].nome) == selectedPlan,
                    ink: ink,
                    mute: mute,
                    isDark: isDark,
                    onTap: () {
                      final tier = subscriptionPlanFromApi(sorted[i].nome);
                      if (tier != selectedPlan) {
                        HapticFeedback.selectionClick();
                        onSelected(tier);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaywallStudioSegment extends StatelessWidget {
  const _PaywallStudioSegment({
    required this.plano,
    required this.plan,
    required this.isCurrent,
    required this.isSelected,
    required this.onTap,
    required this.ink,
    required this.mute,
    required this.isDark,
  });

  final Plano plano;
  final SubscriptionPlan plan;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback onTap;
  final Color ink;
  final Color mute;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final accent = PaywallCatalog.accentForPlan(plan);
    final label = PaywallCatalog.displayNameFor(plano, plan);
    final short = label.length > 14
        ? switch (plan) {
            SubscriptionPlan.ENTERPRISE_PRO => 'ENT. PRO',
            SubscriptionPlan.ENTERPRISE => 'ENTERPRISE',
            SubscriptionPlan.PREMIUM => 'PREMIUM',
            _ => label,
          }
        : label;

    return Semantics(
      button: true,
      selected: isSelected,
      label: isCurrent
          ? '$label, seu plano atual'
          : isSelected
          ? '$label, selecionado'
          : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rPill),
          child: AnimatedContainer(
            duration: TokensStrip.prefersReducedMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TokensStrip.rPill),
              color: isSelected
                  ? accent.withValues(alpha: isDark ? 0.22 : 0.14)
                  : Colors.transparent,
              border: isSelected
                  ? Border.all(color: accent.withValues(alpha: 0.55), width: 1.5)
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  short,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? PaywallCatalog.readableTierAccent(accent, isDark: isDark)
                        : mute,
                    height: 1.1,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Ativo',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: PaywallCatalog.readableTierAccent(accent, isDark: isDark),
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
}

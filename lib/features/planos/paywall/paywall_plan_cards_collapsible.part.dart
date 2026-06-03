part of 'paywall_components.dart';

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


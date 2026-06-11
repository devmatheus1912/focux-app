part of 'paywall_components.dart';

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
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
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
                detail:
                    usage.alunosAtivos > 0
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

class _PaywallUsageMeterRow extends StatefulWidget {
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
  State<_PaywallUsageMeterRow> createState() => _PaywallUsageMeterRowState();
}

class _PaywallUsageMeterRowState extends State<_PaywallUsageMeterRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _usedTween;
  double _displayUsed = 0;

  @override
  void initState() {
    super.initState();
    _displayUsed = widget.used.toDouble();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _usedTween = AlwaysStoppedAnimation(_displayUsed);
    _pulse.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _displayUsed = widget.used.toDouble();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _PaywallUsageMeterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.used != widget.used) {
      _usedTween = Tween<double>(
        begin: _displayUsed,
        end: widget.used.toDouble(),
      ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOutCubic));
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final animatedUsed = _usedTween.value.round();
        final ratio =
            widget.limit <= 0
                ? 0.0
                : (animatedUsed / widget.limit).clamp(0.0, 1.0);
        final barColor =
            widget.atLimit
                ? EagleTokens.paywallUsageWarn
                : widget.nearLimit
                ? PaywallCatalog.warning
                : widget.accent;
        final rest =
            widget.remaining ??
            (widget.limit - animatedUsed).clamp(0, widget.limit);
        final statusHint =
            widget.atLimit
                ? ', limite atingido'
                : widget.nearLimit
                ? ', perto do limite'
                : '';
        return Semantics(
          label:
              '${widget.label}: $animatedUsed de ${widget.limit}, $rest restantes$statusHint',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TokensStrip.body(
                        color: widget.secondary,
                      ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$animatedUsed / ${widget.limit}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: widget.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '$rest restantes',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: widget.accent.withValues(
                    alpha: widget.isDark ? 0.14 : 0.1,
                  ),
                  color: barColor,
                ),
              ),
            ],
          ),
        );
      },
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
                  style: TokensStrip.body(
                    color: secondary,
                  ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TokensStrip.bodyMuted(
                    color: secondary,
                  ).copyWith(fontSize: 11.5),
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
                color: PaywallCatalog.readableTierAccent(
                  accent,
                  isDark: isDark,
                ),
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
    final secondary = PaywallCatalog.readableSecondary(
      ink,
      mute,
      isDark: isDark,
    );
    final body =
        message?.trim().isNotEmpty == true
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
                style: TokensStrip.body(
                  color: secondary,
                ).copyWith(fontSize: 12.5, height: 1.4),
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
                    color: PaywallCatalog.readableTierAccent(
                      accent,
                      isDark: isDark,
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
          Expanded(child: Text(msg, style: TokensStrip.body(color: ink))),
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
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 6,
                ),
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
                      style: TokensStrip.bodyMuted(
                        color: mute,
                      ).copyWith(fontSize: 11),
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
                          child:
                              row * cols + col < items.length
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

  const _RoiCell({required this.item, required this.line, required this.mute});

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

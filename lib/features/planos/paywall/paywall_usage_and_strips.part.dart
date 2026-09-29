part of 'paywall_components.dart';

/// Frase do banner de contexto: só uso real e limites do plano, sem
/// projeção de faturamento.
String? paywallContextMessage({
  required PlanoUsageSnapshot usage,
  String? blockedFeatureLabel,
  required SubscriptionPlan target,
}) {
  if (blockedFeatureLabel != null && blockedFeatureLabel.isNotEmpty) {
    return 'Você tentou usar $blockedFeatureLabel. '
        'Disponível no plano ${PlanEntitlements.displayPlanName(target)}.';
  }
  if (usage.alunosAtLimit && usage.limiteAlunos != null) {
    final proximo = target == SubscriptionPlan.ENTERPRISE
        ? 'Enterprise libera alunos ilimitados.'
        : 'O Pro libera até 30 alunos.';
    return 'Você atingiu ${usage.limiteAlunos} alunos, o limite do seu plano. '
        '$proximo';
  }
  if (usage.alunosNearLimit && usage.limiteAlunos != null) {
    final left = (usage.limiteAlunos! - usage.alunosAtivos).clamp(0, 99);
    return 'Você tem ${usage.alunosAtivos} alunos — faltam $left para o limite. '
        'Upgrade libera mais vagas.';
  }
  if (usage.iaAtLimit) {
    return 'Você usou ${usage.iaUsadaMes} de ${usage.limiteIaMensal} IA este mês. '
        'Enterprise libera até ${PlanoIaLimits.enterprise} interações.';
  }
  if (usage.iaNearLimit) {
    return 'Você usou ${usage.iaUsadaMes} de ${usage.limiteIaMensal} interações de IA. '
        'Enterprise dá mais folga no Copiloto.';
  }
  if (usage.plano == SubscriptionPlan.FREE) {
    return 'O Pro libera até 30 alunos, cobrança PIX e '
        '${PlanoIaLimits.pro} usos de IA por mês.';
  }
  return null;
}

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

  @override
  Widget build(BuildContext context) {
    final target = PlanEntitlements.resolveUpgradeTarget(
      usage: usage,
      blockedFeatureLabel: blockedFeatureLabel,
      blockedCapability: blockedCapability,
    );
    final msg = paywallContextMessage(
      usage: usage,
      blockedFeatureLabel: blockedFeatureLabel,
      target: target,
    );
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
          const SizedBox(width: TokensStrip.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg, style: TokensStrip.body(color: ink).copyWith(height: 1.4)),
                if (onCta != null)
                  TextButton(
                    onPressed: onCta,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 40),
                      padding: const EdgeInsets.only(top: TokensStrip.s1),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Ver ${PlanEntitlements.displayPlanName(target)}',
                      style: FocuxHubTypography.chip(accent),
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

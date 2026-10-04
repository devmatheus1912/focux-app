part of 'paywall_components.dart';

/// Frase do banner de contexto: só uso real e limites do plano, sem
/// projeção de faturamento.
String? paywallContextMessage({
  required PlanoUsageSnapshot usage,
  String? blockedFeatureLabel,
  required SubscriptionPlan target,
}) {
  if (blockedFeatureLabel != null && blockedFeatureLabel.isNotEmpty) {
    return '$blockedFeatureLabel está no plano '
        '${PlanEntitlements.displayPlanName(target)}.';
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

/// Uma linha dizendo por que a pessoa caiu em Planos. O plano alvo já vem
/// selecionado, então não tem CTA.
class PaywallContextBanner extends StatelessWidget {
  final PlanoUsageSnapshot usage;
  final String? blockedFeatureLabel;
  final String? blockedCapability;
  final Color mute;

  const PaywallContextBanner({
    super.key,
    required this.usage,
    this.blockedFeatureLabel,
    this.blockedCapability,
    required this.mute,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s3),
      child: Row(
        children: [
          Icon(Icons.lock_open_rounded, color: accent, size: 16),
          const SizedBox(width: TokensStrip.s2),
          Expanded(
            child: Text(
              msg,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TokensStrip.body(color: mute),
            ),
          ),
        ],
      ),
    );
  }
}

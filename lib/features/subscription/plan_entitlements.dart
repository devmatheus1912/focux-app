import '../subscription/models/subscription_plan.dart';

/// Copy e plano-alvo para paywalls contextuais (fonte única no app).
class PlanEntitlements {
  PlanEntitlements._();

  static SubscriptionPlan targetPlan({
    String? capability,
    SubscriptionPlan fallback = SubscriptionPlan.PREMIUM,
  }) {
    switch (capability) {
      case 'whiteLabel':
      case 'iaIlimitada':
        return SubscriptionPlan.ENTERPRISE;
      case 'financeiro':
      case 'relatorios':
      case 'iaCopiloto':
      case 'agenda':
        return SubscriptionPlan.PREMIUM;
      default:
        return fallback;
    }
  }

  static LockedOffer lockedOffer({
    required String featureName,
    String? capability,
    SubscriptionPlan? requiredPlan,
  }) {
    final plan = targetPlan(
      capability: capability,
      fallback: requiredPlan ?? SubscriptionPlan.PREMIUM,
    );
    final planLabel = plan == SubscriptionPlan.ENTERPRISE ? 'Enterprise' : 'Premium';

    final headline = switch (capability) {
      'financeiro' => 'Cobre seus alunos com controle total',
      'iaCopiloto' => 'IA Copiloto para escalar sem perder qualidade',
      'iaIlimitada' => 'IA ilimitada para operação em alto volume',
      'whiteLabel' => 'Sua marca em cada touchpoint',
      'relatorios' => 'Relatórios que mostram onde está o dinheiro',
      'agenda' => 'Agenda completa para sua operação',
      _ => 'Desbloqueie $featureName',
    };

    final body = switch (capability) {
      'financeiro' =>
        'Mensalidades, inadimplência e resumo financeiro fazem parte do plano $planLabel. '
            'Personal trainers que cobram no app convertem mais e perdem menos alunos.',
      'iaCopiloto' =>
        'Gere treinos, insights e respostas com IA no plano $planLabel. '
            'No Enterprise, a cota de IA é ilimitada.',
      'iaIlimitada' =>
        'Você atingiu o limite de IA do Premium. No Enterprise, Copiloto e RAG não têm teto mensal.',
      'whiteLabel' =>
        'Cores, logo e identidade visual premium exigem Enterprise — '
            'sua marca em cada tela do app, não um visual genérico.',
      'relatorios' =>
        'Analytics de aderência e visão global do negócio estão no $planLabel.',
      'agenda' =>
        'Recursos avançados de agenda estão no $planLabel ou superior.',
      _ => '"$featureName" faz parte do plano $planLabel. Faça upgrade em um passo.',
    };

    return LockedOffer(
      headline: headline,
      body: body,
      ctaLabel:
          plan == SubscriptionPlan.ENTERPRISE
              ? 'Ver plano Enterprise'
              : 'Assinar Premium',
      targetPlan: plan,
    );
  }

  static PlanoUsageSnapshot snapshotFrom({
    required SubscriptionPlan plano,
    required int alunosAtivos,
    required int? limiteAlunos,
    required int iaUsadaMes,
    required int? limiteIaMensal,
  }) {
    return PlanoUsageSnapshot(
      plano: plano,
      alunosAtivos: alunosAtivos,
      limiteAlunos: limiteAlunos,
      iaUsadaMes: iaUsadaMes,
      limiteIaMensal: limiteIaMensal ?? 0,
    );
  }

  static String? softGateMessage(PlanoUsageSnapshot usage) {
    if (usage.alunosNearLimit) {
      final left = (usage.limiteAlunos! - usage.alunosAtivos).clamp(0, 999);
      return 'Você usa $left de ${usage.limiteAlunos} vagas no ${usage.planoLabel}. '
          'Premium libera até 20 alunos.';
    }
    if (usage.iaNearLimit) {
      return 'Você usou ${usage.iaUsadaMes} de ${usage.limiteIaMensal} interações de IA este mês. '
          'Enterprise remove o teto.';
    }
    return null;
  }

  static SubscriptionPlan? softGateTargetPlan(PlanoUsageSnapshot usage) {
    if (usage.alunosNearLimit) {
      return usage.plano == SubscriptionPlan.FREE
          ? SubscriptionPlan.PREMIUM
          : SubscriptionPlan.ENTERPRISE;
    }
    if (usage.iaNearLimit) return SubscriptionPlan.ENTERPRISE;
    return null;
  }
}

class LockedOffer {
  final String headline;
  final String body;
  final String ctaLabel;
  final SubscriptionPlan targetPlan;

  const LockedOffer({
    required this.headline,
    required this.body,
    required this.ctaLabel,
    required this.targetPlan,
  });
}

/// Métricas de uso vindas de `/api/planos/me`.
class PlanoUsageSnapshot {
  final SubscriptionPlan plano;
  final int alunosAtivos;
  final int? limiteAlunos;
  final int iaUsadaMes;
  final int limiteIaMensal;

  const PlanoUsageSnapshot({
    required this.plano,
    required this.alunosAtivos,
    required this.limiteAlunos,
    required this.iaUsadaMes,
    required this.limiteIaMensal,
  });

  String get planoLabel => plano.apiName;

  bool get alunosNearLimit {
    if (limiteAlunos == null || limiteAlunos! <= 0) return false;
    return alunosAtivos >= (limiteAlunos! * 0.8).ceil();
  }

  bool get alunosAtLimit {
    if (limiteAlunos == null) return false;
    return alunosAtivos >= limiteAlunos!;
  }

  bool get iaNearLimit {
    if (limiteIaMensal <= 0 || plano == SubscriptionPlan.ENTERPRISE) {
      return false;
    }
    return iaUsadaMes >= (limiteIaMensal * 0.8).ceil();
  }
}

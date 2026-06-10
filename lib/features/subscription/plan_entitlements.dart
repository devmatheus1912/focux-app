import '../growth/utils/migracao_foto_limits.dart';
import '../subscription/models/subscription_plan.dart';
import '../subscription/utils/plano_ia_limits.dart';

/// Copy e plano-alvo para paywalls contextuais (fonte única no app).
class PlanEntitlements {
  PlanEntitlements._();

  static String displayPlanName(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.ENTERPRISE_PRO => 'ENTERPRISE PRO',
    _ => plan.apiName,
  };

  /// Infere capability a partir do rótulo exibido no paywall ou deep link `feature=`.
  static String? capabilityFromFeatureLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('editor completo') ||
        lower.contains('landing') ||
        lower.contains('depoimentos') && lower.contains('faq') ||
        lower.contains('formulário meta') ||
        lower.contains('focux.app/p/')) {
      return 'landingCompleta';
    }
    if (lower.contains('loja') ||
        lower.contains('desafio 30') ||
        lower.contains('checkout integrado') ||
        lower.contains('receita passiva')) {
      return 'lojaDigital';
    }
    if (lower.contains('pose coach')) return 'poseCoach';
    if (lower.contains('white-label') ||
        lower.contains('marca própria') ||
        lower.contains('marca propria')) {
      return 'whiteLabel';
    }
    if (lower.contains('automações sequenciais avançadas')) {
      return 'automacoesAvancadas';
    }
    if (lower.contains('automações')) return 'automacoes';
    if (lower.contains('equipe / rbac') || lower.contains('rbac')) {
      return 'equipeRbac';
    }
    if (lower.contains('comunidade + grupos')) return 'comunidadeGrupos';
    if (lower.contains('crm')) return null;
    if (lower.contains('pix') || lower.contains('financeiro')) {
      return 'financeiro';
    }
    if (lower.contains('ia copiloto')) return 'iaCopiloto';
    return null;
  }

  /// Plano-alvo para banner/CTA contextual (feature bloqueada ou soft gate).
  static SubscriptionPlan resolveUpgradeTarget({
    required PlanoUsageSnapshot usage,
    String? blockedFeatureLabel,
    String? blockedCapability,
  }) {
    final cap =
        blockedCapability ??
        (blockedFeatureLabel != null
            ? capabilityFromFeatureLabel(blockedFeatureLabel)
            : null);
    if (cap != null) {
      final plan = targetPlan(capability: cap);
      if (plan.level > usage.plano.level) return plan;
    }
    final soft = softGateTargetPlan(usage);
    if (soft != null && soft.level > usage.plano.level) return soft;
    return switch (usage.plano) {
      SubscriptionPlan.ENTERPRISE => SubscriptionPlan.ENTERPRISE_PRO,
      SubscriptionPlan.PREMIUM => SubscriptionPlan.ENTERPRISE,
      SubscriptionPlan.FREE => SubscriptionPlan.PREMIUM,
      _ => SubscriptionPlan.PREMIUM,
    };
  }

  static SubscriptionPlan targetPlan({
    String? capability,
    SubscriptionPlan fallback = SubscriptionPlan.PREMIUM,
  }) {
    switch (capability) {
      case 'landingCompleta':
      case 'lojaDigital':
      case 'poseCoach':
      case 'automacoesAvancadas':
        return SubscriptionPlan.ENTERPRISE_PRO;
      case 'whiteLabel':
      case 'automacoes':
      case 'comunidadeGrupos':
      case 'equipeRbac':
        return SubscriptionPlan.ENTERPRISE;
      case 'habitCoaching':
      case 'comunidadePrivada':
      case 'financeiro':
      case 'relatorios':
      case 'iaCopiloto':
      case 'migracaoFoto':
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
    final planLabel = switch (plan) {
      SubscriptionPlan.ENTERPRISE_PRO => 'Enterprise Pro',
      SubscriptionPlan.ENTERPRISE => 'Enterprise',
      _ => 'Premium',
    };

    final headline = switch (capability) {
      'financeiro' => 'Cobre seus alunos com controle total',
      'iaCopiloto' => 'IA Copiloto para escalar sem perder qualidade',
      'landingCompleta' =>
        'Landing page completa — vende 24h com depoimentos, FAQ e leads',
      'whiteLabel' => 'Sua marca em cada touchpoint',
      'relatorios' => 'Relatórios que mostram onde está o dinheiro',
      'migracaoFoto' => 'Importe alunos por foto ou print',
      'agenda' => 'Agenda completa para sua operação',
      'habitCoaching' => 'Habit coaching diário para retenção',
      'comunidadePrivada' => 'Comunidade privada de alunos',
      'automacoes' => 'Automações sequenciais para escalar',
      'automacoesAvancadas' => 'Automações avançadas com ramificações',
      'comunidadeGrupos' => 'Desafios e grupos com ranking',
      'equipeRbac' => 'Equipe com permissões granulares',
      'lojaDigital' => 'Loja digital com checkout PIX',
      'poseCoach' => 'Pose Coach — análise de postura ML',
      _ => 'Desbloqueie $featureName',
    };

    final body = switch (capability) {
      'financeiro' =>
        'Mensalidades, inadimplência e resumo financeiro fazem parte do plano $planLabel. '
            'Personal trainers que cobram no app convertem mais e perdem menos alunos.',
      'iaCopiloto' =>
        'Gere treinos, insights e respostas com IA no plano $planLabel '
            '(${PlanoIaLimits.premium} interações/mês). '
            'Enterprise: ${PlanoIaLimits.enterprise}/mês.',
      'migracaoFoto' =>
        'Importar alunos por foto/print (OCR gratuito) está no $planLabel '
            '— ${MigracaoFotoLimits.premium}/mês. Enterprise: ${MigracaoFotoLimits.enterprise}/mês.',
      'landingCompleta' =>
        'Depoimentos ilimitados, galeria, FAQ e formulário Meta exigem Enterprise Pro — '
            'poupa R\$ 1k–3k de agência por +R\$ 50/mês vs Enterprise.',
      'whiteLabel' =>
        'Cores, logo e identidade visual premium exigem Enterprise — '
            'sua marca em cada tela do app, não um visual genérico.',
      'relatorios' =>
        'Analytics de aderência e visão global do negócio estão no $planLabel.',
      'agenda' => 'Agenda completa para sua operação',
      'habitCoaching' =>
        'Hábitos diários (água, sono, passos) fazem parte do plano $planLabel — '
            'personais que acompanham hábitos retêm 35% mais alunos.',
      'comunidadePrivada' =>
        'Comunidade privada fechada para seus alunos está no $planLabel.',
      'automacoes' =>
        'Automações sequenciais (onboarding, winback) exigem Enterprise.',
      'automacoesAvancadas' =>
        'Ramificações e automações avançadas exigem Enterprise Pro.',
      'comunidadeGrupos' =>
        'Desafios com ranking e grupos exigem Enterprise ou superior.',
      'equipeRbac' =>
        'Convide assistentes com permissões granulares no Enterprise '
            '(1 assistente) ou Pro (ilimitado).',
      'lojaDigital' =>
        'Venda programas digitais com checkout PIX no Enterprise Pro.',
      'poseCoach' =>
        'Análise de postura por ML em tempo real no Enterprise Pro.',
      _ =>
        '"$featureName" faz parte do plano $planLabel. Faça upgrade em um passo.',
    };

    return LockedOffer(
      headline: headline,
      body: body,
      ctaLabel: switch (plan) {
        SubscriptionPlan.ENTERPRISE_PRO => 'Ver plano Enterprise Pro',
        SubscriptionPlan.ENTERPRISE => 'Ver plano Enterprise',
        _ => 'Assinar Premium',
      },
      targetPlan: plan,
    );
  }

  static LockedOffer iaQuotaUpgradeOffer({
    required SubscriptionPlan currentPlan,
    SubscriptionPlan? targetPlan,
    int? limiteAtual,
  }) {
    if (currentPlan == SubscriptionPlan.FREE ||
        targetPlan == SubscriptionPlan.PREMIUM) {
      return lockedOffer(
        featureName: 'IA Copiloto',
        capability: 'iaCopiloto',
        requiredPlan: SubscriptionPlan.PREMIUM,
      );
    }
    if (currentPlan == SubscriptionPlan.ENTERPRISE && targetPlan == null) {
      return LockedOffer(
        headline: 'Cota de IA esgotada este mês',
        body:
            'Você usou todas as ${limiteAtual ?? PlanoIaLimits.enterprise} interações do Enterprise. '
            'A cota renova no próximo ciclo mensal.',
        ctaLabel: 'Entendi',
        targetPlan: null,
      );
    }
    return LockedOffer(
      headline: 'Cota de IA esgotada este mês',
      body:
          'Você usou todas as ${limiteAtual ?? PlanoIaLimits.premium} interações do Premium. '
          'No Enterprise são ${PlanoIaLimits.enterprise} interações/mês — mais espaço para Copiloto, treinos e chat.',
      ctaLabel: 'Ver plano Enterprise',
      targetPlan: targetPlan ?? SubscriptionPlan.ENTERPRISE,
    );
  }

  /// Limites exibidos no paywall — prioriza tier da assinatura (loja) sobre `/me` divergente.
  static int? effectiveLimiteAlunos({
    required SubscriptionPlan billingPlan,
    required int? fromApi,
  }) {
    if (billingPlan == SubscriptionPlan.ENTERPRISE ||
        billingPlan == SubscriptionPlan.ENTERPRISE_PRO) {
      return null;
    }
    return fromApi;
  }

  static int effectiveLimiteIaMensal({
    required SubscriptionPlan billingPlan,
    required int? fromApi,
  }) {
    if (fromApi != null && fromApi > 0) return fromApi;
    return switch (billingPlan) {
      SubscriptionPlan.ENTERPRISE ||
      SubscriptionPlan.ENTERPRISE_PRO => PlanoIaLimits.enterprise,
      SubscriptionPlan.PREMIUM => PlanoIaLimits.premium,
      _ => 0,
    };
  }

  static PlanoUsageSnapshot snapshotFrom({
    required SubscriptionPlan plano,
    required int alunosAtivos,
    required int? limiteAlunos,
    required int iaUsadaMes,
    required int? limiteIaMensal,
    int? iaRestantes,
    SubscriptionPlan? billingPlan,
    SubscriptionPlan? serverPlano,
  }) {
    final bill = billingPlan ?? plano;
    final limiteAlunosEff = effectiveLimiteAlunos(
      billingPlan: bill,
      fromApi: limiteAlunos,
    );
    final limiteIa = effectiveLimiteIaMensal(
      billingPlan: bill,
      fromApi: limiteIaMensal,
    );
    return PlanoUsageSnapshot(
      plano: bill,
      serverPlano: serverPlano ?? plano,
      alunosAtivos: alunosAtivos,
      limiteAlunos: limiteAlunosEff,
      iaUsadaMes: iaUsadaMes,
      limiteIaMensal: limiteIa,
      iaRestantes: iaRestantes,
    );
  }

  static String? softGateMessage(PlanoUsageSnapshot usage) {
    if (usage.alunosNearLimit) {
      final left = (usage.limiteAlunos! - usage.alunosAtivos).clamp(0, 999);
      return 'Você usa $left de ${usage.limiteAlunos} vagas no ${usage.planoLabel}. '
          'Premium libera até 20 alunos.';
    }
    if (usage.iaAtLimit) {
      return 'Cota de IA esgotada (${usage.limiteIaMensal}/mês). '
          '${usage.plano == SubscriptionPlan.PREMIUM ? 'Enterprise libera até ${PlanoIaLimits.enterprise} interações/mês.' : 'Renova no próximo ciclo.'}';
    }
    if (usage.iaNearLimit) {
      return 'Você usou ${usage.iaUsadaMes} de ${usage.limiteIaMensal} interações de IA este mês. '
          '${usage.plano == SubscriptionPlan.PREMIUM ? 'Enterprise sobe para ${PlanoIaLimits.enterprise}/mês.' : 'Use com parcimônia até renovar.'}';
    }
    return null;
  }

  static SubscriptionPlan? softGateTargetPlan(PlanoUsageSnapshot usage) {
    if (usage.alunosNearLimit) {
      return switch (usage.plano) {
        SubscriptionPlan.FREE => SubscriptionPlan.PREMIUM,
        SubscriptionPlan.PREMIUM => SubscriptionPlan.ENTERPRISE,
        _ => null,
      };
    }
    if (usage.iaNearLimit || usage.iaAtLimit) {
      return usage.plano == SubscriptionPlan.PREMIUM
          ? SubscriptionPlan.ENTERPRISE
          : null;
    }
    return null;
  }
}

class LockedOffer {
  final String headline;
  final String body;
  final String ctaLabel;
  final SubscriptionPlan? targetPlan;

  const LockedOffer({
    required this.headline,
    required this.body,
    required this.ctaLabel,
    this.targetPlan,
  });
}

/// Métricas de uso vindas de `/api/planos/me`.
class PlanoUsageSnapshot {
  final SubscriptionPlan plano;
  final SubscriptionPlan? serverPlano;
  final int alunosAtivos;
  final int? limiteAlunos;
  final int iaUsadaMes;
  final int limiteIaMensal;
  final int? iaRestantes;

  const PlanoUsageSnapshot({
    required this.plano,
    this.serverPlano,
    required this.alunosAtivos,
    required this.limiteAlunos,
    required this.iaUsadaMes,
    required this.limiteIaMensal,
    this.iaRestantes,
  });

  bool get planMismatch =>
      serverPlano != null && serverPlano!.level != plano.level;

  int get iaRestantesEfetivos {
    if (iaRestantes != null) return iaRestantes!.clamp(0, limiteIaMensal);
    if (limiteIaMensal <= 0) return 0;
    return (limiteIaMensal - iaUsadaMes).clamp(0, limiteIaMensal);
  }

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
    if (limiteIaMensal <= 0) return false;
    if (iaAtLimit) return false;
    return iaUsadaMes >= (limiteIaMensal * 0.8).ceil();
  }

  bool get iaAtLimit {
    if (limiteIaMensal <= 0) return false;
    return iaUsadaMes >= limiteIaMensal;
  }
}

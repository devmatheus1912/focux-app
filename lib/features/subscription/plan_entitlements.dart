import '../growth/utils/migracao_foto_limits.dart';
import '../subscription/models/subscription_plan.dart';
import '../subscription/utils/plano_ia_limits.dart';

/// Copy e plano-alvo para paywalls contextuais (fonte única no app).
class PlanEntitlements {
  PlanEntitlements._();

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
      _ => '"$featureName" faz parte do plano $planLabel. Faça upgrade em um passo.',
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
    if (currentPlan == SubscriptionPlan.FREE || targetPlan == SubscriptionPlan.PREMIUM) {
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
    if (limiteIaMensal <= 0) return false;
    if (iaAtLimit) return false;
    return iaUsadaMes >= (limiteIaMensal * 0.8).ceil();
  }

  bool get iaAtLimit {
    if (limiteIaMensal <= 0) return false;
    return iaUsadaMes >= limiteIaMensal;
  }
}

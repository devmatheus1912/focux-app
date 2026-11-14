import '../ia/utils/ia_cota.dart';
import '../planos/data/plano_recurso.dart';
import '../planos/data/plano_recurso_textos.dart';
import '../subscription/models/subscription_plan.dart';
import '../subscription/utils/plano_ia_limits.dart';

/// Copy e plano-alvo para paywalls contextuais (fonte única no app).
class PlanEntitlements {
  PlanEntitlements._();

  static String displayPlanName(SubscriptionPlan plan) => plan.label;

  /// Converte o enum de `detalhes.feature` do backend (`FEEDBACK_VIDEO`,
  /// `IA_COPILOTO`, …) para a capability camelCase que o paywall já conhece.
  ///
  /// Sem este mapa a sheet não sabe qual copy mostrar, e `upgradePlano`
  /// sozinho não preenche o título. Os 16 nomes são os de
  /// `PlanoVerificationService` no contrato §2.3.
  static String? capabilityFromBackendFeature(String? feature) {
    if (feature == null || feature.isEmpty) return null;
    const map = {
      'IA_COPILOTO': 'iaCopiloto',
      'WHITE_LABEL': 'whiteLabel',
      'LANDING_COMPLETA': 'landingCompleta',
      'HABIT_COACHING': 'habitCoaching',
      'COMUNIDADE_PRIVADA': 'comunidadePrivada',
      'AUTOMACOES': 'automacoes',
      'AUTOMACOES_AVANCADAS': 'automacoesAvancadas',
      'COMUNIDADE_GRUPOS': 'comunidadeGrupos',
      'EQUIPE_RBAC': 'equipeRbac',
      'LOJA_DIGITAL': 'lojaDigital',
      'FEEDBACK_VIDEO': 'feedbackVideo',
      'FINANCEIRO': 'financeiro',
      'RELATORIOS': 'relatorios',
      'AGENDA': 'agenda',
      'LEADS': 'leads',
      'NFSE': 'nfse',
    };
    return map[feature.trim().toUpperCase()];
  }

  static String featureNameFromBackendFeature(
    String? feature, {
    String fallback = 'recurso',
  }) => PlanoRecursoTextos.nome(
    capabilityFromBackendFeature(feature),
    fallback: fallback,
  );

  /// Infere capability a partir do rótulo exibido no paywall ou deep link `feature=`.
  static String? capabilityFromFeatureLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('editor completo') ||
        lower.contains('landing') ||
        lower.contains('depoimentos') && lower.contains('faq') ||
        lower.contains('formulário meta') ||
        lower.contains('focux.app/p/') ||
        lower.contains('focuxpersonal.com/p/')) {
      return 'landingCompleta';
    }
    if (lower.contains('loja') ||
        lower.contains('desafio 30') ||
        lower.contains('checkout integrado') ||
        lower.contains('receita passiva')) {
      return 'lojaDigital';
    }
    if (lower.contains('feedback em vídeo')) return 'feedbackVideo';
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
      SubscriptionPlan.ENTERPRISE => SubscriptionPlan.ENTERPRISE,
      SubscriptionPlan.PRO => SubscriptionPlan.ENTERPRISE,
      SubscriptionPlan.FREE => SubscriptionPlan.PRO,
    };
  }

  static SubscriptionPlan targetPlan({
    String? capability,
    SubscriptionPlan fallback = SubscriptionPlan.PRO,
  }) {
    final recurso = PlanoRecursoKeys.fromCapability(capability);
    return recurso == null ? fallback : PlanoRecursoKeys.matrix[recurso]!;
  }

  static LockedOffer lockedOffer({
    required String featureName,
    String? capability,
    SubscriptionPlan? requiredPlan,
    SubscriptionPlan? upgradePlano,
  }) {
    // `upgradePlano` do servidor é a fonte da verdade quando veio no erro.
    // Sem ele, a matriz local vale (telas que bloqueiam antes da API).
    final plan = upgradePlano ??
        targetPlan(
          capability: capability,
          fallback: requiredPlan ?? SubscriptionPlan.PRO,
        );
    final planLabel = plan == SubscriptionPlan.FREE ? 'Pro' : displayPlanName(plan);
    final texto = PlanoRecursoTextos.de(capability);
    final nome = texto?.nome ?? featureName;
    final ia =
        PlanoRecursoKeys.fromCapability(capability) == PlanoRecursoKeys.ia;
    return LockedOffer(
      headline: texto?.frase ?? nome,
      // Só a folha de cota da IA mostra o corpo.
      body:
          ia
              ? 'Análises e próximos passos com IA no plano $planLabel '
                  '(${PlanoIaLimits.pro} usos de IA por mês). '
                  'Enterprise: ${PlanoIaLimits.enterprise}/mês.'
              : '$nome faz parte do plano $planLabel.',
      ctaLabel: switch (plan) {
        SubscriptionPlan.ENTERPRISE => 'Ver plano Enterprise',
        _ => 'Assinar Pro',
      },
      targetPlan: plan,
    );
  }

  /// Os 3 benefícios do recurso ([PlanoRecursoTextos]); vazio para
  /// capability desconhecida (o contrato de testes não deixa chegar aqui).
  static List<String> salesBenefits(String? capability) =>
      PlanoRecursoTextos.de(capability)?.beneficios ?? const [];

  static LockedOffer iaQuotaUpgradeOffer({
    required SubscriptionPlan currentPlan,
    SubscriptionPlan? targetPlan,
    int? limiteAtual,
    DateTime? agora,
  }) {
    final volta = iaCotaVoltaLabel(agora ?? DateTime.now());
    if (currentPlan == SubscriptionPlan.FREE ||
        targetPlan == SubscriptionPlan.PRO) {
      return lockedOffer(
        featureName: 'IA Focux',
        capability: 'iaCopiloto',
        requiredPlan: SubscriptionPlan.PRO,
      );
    }
    if (currentPlan == SubscriptionPlan.ENTERPRISE && targetPlan == null) {
      return LockedOffer(
        headline: 'Usos de IA acabaram este mês',
        body:
            'Seus ${limiteAtual ?? PlanoIaLimits.enterprise} usos de IA acabaram. '
            'Voltam em $volta.',
        ctaLabel: 'Entendi',
        targetPlan: null,
      );
    }
    return LockedOffer(
      headline: 'Usos de IA acabaram este mês',
      body:
          'Seus ${limiteAtual ?? PlanoIaLimits.pro} usos de IA acabaram. Voltam em $volta. '
          'No Enterprise são ${PlanoIaLimits.enterprise} por mês.',
      ctaLabel: 'Ver plano Enterprise',
      targetPlan: targetPlan ?? SubscriptionPlan.ENTERPRISE,
    );
  }

  /// Limites exibidos no paywall — prioriza tier da assinatura (loja) sobre `/me` divergente.
  static int? effectiveLimiteAlunos({
    required SubscriptionPlan billingPlan,
    required int? fromApi,
  }) {
    if (billingPlan == SubscriptionPlan.ENTERPRISE) {
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
      SubscriptionPlan.ENTERPRISE => PlanoIaLimits.enterprise,
      SubscriptionPlan.PRO => PlanoIaLimits.pro,
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
          'Pro libera até ${PlanoAlunosLimits.pro} alunos.';
    }
    if (usage.iaAtLimit) {
      return 'Usos de IA acabaram (${usage.limiteIaMensal}/mês). '
          '${usage.plano == SubscriptionPlan.PRO ? 'Enterprise libera até ${PlanoIaLimits.enterprise} por mês.' : 'Voltam em ${iaCotaVoltaLabel(DateTime.now())}.'}';
    }
    if (usage.iaNearLimit) {
      return 'Você usou ${usage.iaUsadaMes} de ${usage.limiteIaMensal} usos de IA este mês. '
          '${usage.plano == SubscriptionPlan.PRO ? 'Enterprise sobe para ${PlanoIaLimits.enterprise}/mês.' : 'Use com parcimônia até renovar.'}';
    }
    return null;
  }

  static SubscriptionPlan? softGateTargetPlan(PlanoUsageSnapshot usage) {
    if (usage.alunosNearLimit) {
      return switch (usage.plano) {
        SubscriptionPlan.FREE => SubscriptionPlan.PRO,
        SubscriptionPlan.PRO => SubscriptionPlan.ENTERPRISE,
        _ => null,
      };
    }
    if (usage.iaNearLimit || usage.iaAtLimit) {
      return usage.plano == SubscriptionPlan.PRO
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

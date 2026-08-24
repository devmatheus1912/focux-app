import 'package:flutter/material.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../assinatura/data/plano.dart';
import '../../subscription/models/subscription_plan.dart';

/// Catálogo estático de educação e vitrine — preços vêm do backend/loja.
class PaywallCatalog {
  PaywallCatalog._();

  static const Color brand = BrandPalette.defaultPrimary;

  /// Teal profundo — tier ENTERPRISE PRO e CTAs de upgrade.
  static const Color brandDeep = BrandPalette.defaultInk;

  /// Teal slate — tier ENTERPRISE (premium, sem ouro).
  static const Color tierEnterprise = EagleTokens.tierEnterprise;

  /// Legado vitrine/API (`badgeColor: gold`) — mapeado para [tierEnterprise] na UI.
  static const Color gold = tierEnterprise;
  static const Color green = EagleTokens.brightGreen;
  static const Color warning = EagleTokens.warn;

  /// Chrome neutro para blocos secundários (accordions, downgrade).
  static Color chromeNeutral(Color ink, {required bool isDark}) =>
      isDark ? EagleTokens.chromeNeutralDark : ink.withValues(alpha: 0.38);

  /// Texto secundário com contraste AA em fundos claros (ui-ux-pro-max).
  static Color readableSecondary(
    Color ink,
    Color mute, {
    required bool isDark,
  }) => isDark ? mute.withValues(alpha: 0.92) : ink.withValues(alpha: 0.58);

  /// Remove marcadores tipográficos (✦/✨) — o ícone vai no widget, não no texto.
  static ({String label, bool pro}) parseFeatureLabel(String raw) {
    var t = raw.trim();
    final pro = t.contains('✦') || t.contains('✨');
    t = t.replaceAll(RegExp(r'[✦✨]\s*'), '').trim();
    return (label: t, pro: pro);
  }

  static IconData tierIconFor(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.PREMIUM => Icons.trending_up_rounded,
    SubscriptionPlan.ENTERPRISE => Icons.diamond_outlined,
    SubscriptionPlan.ENTERPRISE_PRO => Icons.workspace_premium_rounded,
    _ => Icons.layers_outlined,
  };

  static Color accentForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.PREMIUM => brand,
    SubscriptionPlan.ENTERPRISE => tierEnterprise,
    SubscriptionPlan.ENTERPRISE_PRO => brandDeep,
    _ => EagleTokens.darkInkMute,
  };

  /// Labels e ícones do tier em card claro (contraste AA, independente da marca do personal).
  static Color tierAccentOnSurface(
    SubscriptionPlan plan, {
    required bool isDark,
  }) {
    if (isDark) return accentForPlan(plan);
    return switch (plan) {
      SubscriptionPlan.ENTERPRISE => EagleTokens.tierEnterpriseInk,
      SubscriptionPlan.ENTERPRISE_PRO => EagleTokens.tierEnterpriseProInk,
      SubscriptionPlan.PREMIUM => brandDeep,
      _ => accentForPlan(plan),
    };
  }

  /// Versão por [accent] (seções internas do card sem [SubscriptionPlan]).
  static Color readableTierAccent(Color accent, {required bool isDark}) {
    if (isDark) return accent;
    if (accent == tierEnterprise || accent == gold) {
      return EagleTokens.tierEnterpriseInk;
    }
    if (accent == brandDeep) return EagleTokens.tierEnterpriseProInk;
    if (accent == brand) return brandDeep;
    return accent;
  }

  static String? badgeForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.PREMIUM => 'MAIS POPULAR',
    SubscriptionPlan.ENTERPRISE => 'TRIAL 14 DIAS',
    SubscriptionPlan.ENTERPRISE_PRO => 'MÁXIMO ROI',
    _ => null,
  };

  static String displayPlanName(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.ENTERPRISE_PRO => 'ENTERPRISE PRO',
    _ => plan.apiName,
  };

  static String displayNameFor(Plano plano, SubscriptionPlan plan) {
    final api = plano.displayName?.trim();
    if (api != null && api.isNotEmpty) return api;
    return displayPlanName(plan);
  }

  static String subtitleFor(Plano plano, SubscriptionPlan plan) {
    final api = plano.subtitle?.trim();
    if (api != null && api.isNotEmpty) return api;
    return subtitleForPlan(plan);
  }

  static String? badgeFor(Plano plano, SubscriptionPlan plan) {
    final api = plano.badge?.trim();
    if (api != null && api.isNotEmpty) return api;
    return badgeForPlan(plan);
  }

  static String? roiTagFor(Plano plano, SubscriptionPlan plan) {
    final api = plano.roiTag?.trim();
    if (api != null && api.isNotEmpty) return api;
    return roiTagForPlan(plan);
  }

  static String subtitleForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.FREE => 'Para começar',
    SubscriptionPlan.PREMIUM => 'Para crescer',
    SubscriptionPlan.ENTERPRISE => 'Para escalar com sua marca',
    SubscriptionPlan.ENTERPRISE_PRO => 'Seu app. Sua marca. Sua página.',
  };

  static String? roiTagForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.PREMIUM => 'Custa menos que 1 falta de aluno',
    SubscriptionPlan.ENTERPRISE => '1 aluno novo paga o plano inteiro',
    SubscriptionPlan.ENTERPRISE_PRO => 'Poupa R\$ 1k–3k de agência',
    _ => null,
  };

  static String descriptionForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.FREE =>
      'Sem cartão. Sem risco. Para testar com seus primeiros alunos.',
    SubscriptionPlan.PREMIUM =>
      'Para o personal que quer organizar, cobrar e reter alunos.',
    SubscriptionPlan.ENTERPRISE =>
      'Alunos ilimitados + marca própria + CRM. Landing completa no Enterprise Pro.',
    SubscriptionPlan.ENTERPRISE_PRO =>
      'Tudo do Enterprise + landing completa + loja digital com PIX.',
  };

  static const List<({String value, String label})> socialProof = [
    (value: '2.847', label: 'personais ativos'),
    (value: '4.9★', label: 'App Store · 312 avaliações'),
    (value: '43', label: 'upgrades esta semana'),
  ];

  static const List<({String value, String label, Color color})> roiStrip = [
    (value: '5×', label: 'ROI médio em 2 anos', color: brand),
    (value: '25%+', label: 'Lucro com +5% retenção', color: tierEnterprise),
    (value: 'R\$ 8.000', label: 'MRR com 20 alunos', color: green),
    (value: '< 1%', label: 'Faturamento = Premium', color: brand),
    (
      value: 'R\$ 50/mês',
      label: 'Substitui R\$ 1–3k agência',
      color: brandDeep,
    ),
    (value: '40%', label: 'Menos inadimplência c/ PIX', color: green),
  ];

  static const List<PaywallComparisonRow> comparisonRows = [
    PaywallComparisonRow(
      feature: 'PIX + QR Code',
      free: '—',
      premium: '✓',
      enterprise: '✓',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: 'IA Copiloto',
      free: '—',
      premium: '120/mês',
      enterprise: '400+/mês',
      enterprisePro: '400+/mês',
    ),
    PaywallComparisonRow(
      feature: FocuxMicrocopy.commandCenterPlusScoreCompact,
      free: '—',
      premium: '✓',
      enterprise: '✓',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: 'Marca própria',
      free: '—',
      premium: '—',
      enterprise: '✓',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: 'Landing page COMPLETA',
      free: '—',
      premium: '—',
      enterprise: '—',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: 'Alunos',
      free: '5',
      premium: '20',
      enterprise: '∞',
      enterprisePro: '∞',
    ),
    PaywallComparisonRow(
      feature: 'Recovery Score',
      free: '—',
      premium: '✓',
      enterprise: '✓',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: 'Habit coaching ✦',
      free: '—',
      premium: '✓',
      enterprise: '✓',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: 'Pose Coach ML ✦',
      free: '—',
      premium: '—',
      enterprise: '—',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: 'Loja digital ✦',
      free: '—',
      premium: '—',
      enterprise: '—',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: 'Equipe / RBAC ✦',
      free: '—',
      premium: '—',
      enterprise: '✓',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: 'NFS-e automática',
      free: '—',
      premium: '—',
      enterprise: '✓',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: 'Domínio customizado',
      free: '—',
      premium: '—',
      enterprise: '✓',
      enterprisePro: '✓',
    ),
    PaywallComparisonRow(
      feature: '50 fotos migração/mês',
      free: '—',
      premium: '—',
      enterprise: '—',
      enterprisePro: '✓',
    ),
  ];

  static const List<PaywallRoiRow> roiRows = [
    PaywallRoiRow(
      label: 'Salvar 1 aluno em risco/mês',
      value: 'R\$ 300–600 recuperados',
      planChip: 'PREMIUM',
      color: brand,
    ),
    PaywallRoiRow(
      label: 'Cobrar via PIX no app',
      value: '40% menos inadimplência',
      planChip: 'PREMIUM',
      color: brand,
    ),
    PaywallRoiRow(
      label: 'IA monta treino (5h/sem economizadas)',
      value: 'R\$ 1.280+/mês em produtividade',
      planChip: 'PREMIUM',
      color: brand,
    ),
    PaywallRoiRow(
      label: 'Recovery Score evita lesão',
      value: 'Menos churn por lesão',
      planChip: 'PREMIUM',
      color: brand,
    ),
    PaywallRoiRow(
      label: 'Marca própria no app',
      value: '+20–30% no valor percebido',
      planChip: 'ENTERPRISE',
      color: tierEnterprise,
    ),
    PaywallRoiRow(
      label: 'Alunos ilimitados — sem teto',
      value: 'Cada novo = R\$ 300–600/mês',
      planChip: 'ENTERPRISE',
      color: tierEnterprise,
    ),
    PaywallRoiRow(
      label: 'NFS-e automática (PJ)',
      value: 'Zero burocracia fiscal',
      planChip: 'ENTERPRISE',
      color: tierEnterprise,
    ),
    PaywallRoiRow(
      label: 'Landing page completa',
      value: 'Poupa R\$ 1k–3k de agência',
      planChip: 'ENT. PRO',
      color: brandDeep,
    ),
    PaywallRoiRow(
      label: 'Link na bio que converte',
      value: 'Lead → aluno 24h/dia',
      planChip: 'ENT. PRO',
      color: brandDeep,
    ),
    PaywallRoiRow(
      label: 'Loja de programas digitais ✦',
      value: 'Receita passiva enquanto dorme',
      planChip: 'ENT. PRO',
      color: brandDeep,
    ),
  ];

  static const List<PaywallTopFeature> topFeatures = [
    PaywallTopFeature(
      rank: 1,
      icon: Icons.qr_code_2_rounded,
      title: 'PIX com QR Code no chat',
      badge: 'EXCLUSIVO BR',
      badgeColor: brand,
      description:
          'Cobra sem constrangimento. QR Code gerado e enviado direto no chat do aluno.',
      roiMoney: '1 mensalidade recuperada = 5× o custo do Premium',
      planChips: ['PREMIUM', 'ENTERPRISE', 'ENT. PRO'],
    ),
    PaywallTopFeature(
      rank: 2,
      icon: Icons.smart_toy_outlined,
      title: 'IA Copiloto com contexto real',
      badge: 'TOP CONVERSÃO',
      badgeColor: brand,
      description:
          'Conhece histórico, aderência e Recovery Score. Monta treino em minutos.',
      roiMoney: '5h economizadas/semana = R\$ 1.280+/mês',
      planChips: ['PREMIUM', 'ENTERPRISE', 'ENT. PRO'],
    ),
    PaywallTopFeature(
      rank: 3,
      icon: Icons.dashboard_outlined,
      title: FocuxMicrocopy.commandCenterPlusFocuxScore,
      badge: 'ÚNICO NO MERCADO',
      badgeColor: tierEnterprise,
      description:
          'Painel do CEO do personal: churn, inadimplência e próxima ação em 2 min.',
      roiMoney: 'Salvar 1 aluno/mês = R\$ 400+ = Premium pago 5×',
      planChips: ['PREMIUM', 'ENTERPRISE', 'ENT. PRO'],
    ),
    PaywallTopFeature(
      rank: 4,
      icon: Icons.palette_outlined,
      title: 'Marca própria — seu app, sua marca',
      badge: 'SÓ ENTERPRISE+',
      badgeColor: tierEnterprise,
      description:
          'Seus alunos abrem SEU app com SEU logo. Posicionamento premium.',
      roiMoney: 'Personais com marca própria cobram 20–30% mais',
      planChips: ['ENTERPRISE', 'ENT. PRO'],
    ),
    PaywallTopFeature(
      rank: 5,
      icon: Icons.language_rounded,
      title: 'Landing page COMPLETA',
      badge: 'MÁXIMO ROI',
      badgeColor: brandDeep,
      description:
          'Depoimentos, galeria, FAQ e formulário. Link na bio que vende 24h/dia.',
      roiMoney: 'Poupa R\$ 1k–3k de agência — por +R\$ 50/mês',
      planChips: ['ENT. PRO'],
    ),
    PaywallTopFeature(
      rank: 6,
      icon: Icons.watch_rounded,
      title: 'Recovery Score + relógio',
      badge: 'NÍVEL GLOBAL',
      badgeColor: brand,
      description:
          'Apple Health, Google Fit, Garmin. Sabe se o aluno dormiu bem antes do treino.',
      roiMoney: 'Menos lesão = menos cancelamento',
      planChips: ['PREMIUM', 'ENTERPRISE', 'ENT. PRO'],
    ),
    PaywallTopFeature(
      rank: 7,
      icon: Icons.track_changes_rounded,
      title: 'Habit Coaching ✦',
      badge: 'LIVE',
      badgeColor: green,
      description:
          'Hábitos diários: água, sono, passos. Acompanhe a vida, não só o treino.',
      roiMoney: 'Personais que acompanham hábitos retêm 35% mais',
      planChips: ['PREMIUM', 'ENTERPRISE', 'ENT. PRO'],
    ),
    PaywallTopFeature(
      rank: 8,
      icon: Icons.accessibility_new_rounded,
      title: 'Pose Coach — análise de postura ✦',
      badge: 'LIVE',
      badgeColor: green,
      description:
          'Análise de postura por ML em tempo real. Nenhum app nacional chega perto.',
      roiMoney: 'Diferencial sem custo extra — ML na stack',
      planChips: ['ENT. PRO'],
    ),
    PaywallTopFeature(
      rank: 9,
      icon: Icons.storefront_outlined,
      title: 'Loja de programas digitais ✦',
      badge: 'LIVE',
      badgeColor: green,
      description:
          'Venda treinos avulsos e desafios com checkout PIX integrado.',
      roiMoney: 'Receita passiva enquanto dorme',
      planChips: ['ENT. PRO'],
    ),
    PaywallTopFeature(
      rank: 10,
      icon: Icons.groups_outlined,
      title: 'Equipe & RBAC ✦',
      badge: 'LIVE',
      badgeColor: green,
      description:
          'Assistentes ou sócios com permissões granulares. Escala com controle.',
      roiMoney: 'Escala sem contratar full-time',
      planChips: ['ENTERPRISE', 'ENT. PRO'],
    ),
  ];

  /// Mensagem do catálogo de gatilhos para modal in-app (não usar na vitrine Planos).
  static String? modalMessageFor({String? capability, String? featureName}) {
    final cap = (capability ?? '').trim().toLowerCase();
    final feat = (featureName ?? '').trim().toLowerCase();
    if (cap.isEmpty && feat.isEmpty) return null;

    int? index;
    switch (cap) {
      case 'financeiro':
        index = 1;
      case 'iacopiloto':
        final quotaExhausted =
            feat.contains('limite') ||
            feat.contains('cota') ||
            feat.contains('esgot') ||
            feat.contains('110');
        index = quotaExhausted ? 5 : 2;
      case 'whitelabel':
        index = 4;
      case 'landingcompleta':
        index = 6;
      default:
        if (feat.contains('pix') || feat.contains('financeiro')) {
          index = 1;
        } else if (feat.contains('white')) {
          index = 4;
        } else if (feat.contains('landing')) {
          index = 6;
        } else if (feat.contains('meta') ||
            feat.contains('tráfego') ||
            feat.contains('trafego')) {
          index = 7;
        } else if (feat.contains('copiloto') || feat.contains(' ia')) {
          index = 2;
        }
    }

    if (index == null || index < 0 || index >= upgradeTriggers.length) {
      return null;
    }
    return upgradeTriggers[index].message;
  }

  /// Copy para modais in-app (`UpgradePromptSheet`) — não exibir na vitrine Planos.
  static const List<PaywallUpgradeTrigger> upgradeTriggers = [
    PaywallUpgradeTrigger(
      number: '01',
      title: '4 alunos cadastrados (não 5)',
      transition: 'FREE → PREMIUM',
      message:
          'Você está a 1 aluno de lotar. Com 20 alunos a R\$ 400 = R\$ 8.000/mês. '
          'Upgrade por R\$ 79 — menos que 1 sessão avulsa.',
    ),
    PaywallUpgradeTrigger(
      number: '02',
      title: 'Tenta cobrar via PIX (bloqueado)',
      transition: 'FREE → PREMIUM',
      message:
          'Personais que cobram pelo app têm 40% menos inadimplência. Desbloqueie por R\$ 79/mês.',
    ),
    PaywallUpgradeTrigger(
      number: '03',
      title: 'IA Copiloto bloqueado',
      transition: 'FREE → PREMIUM',
      message:
          'Sua IA está aguardando. Monte o próximo treino em 3 minutos, não 30. Upgrade por R\$ 79.',
    ),
    PaywallUpgradeTrigger(
      number: '04',
      title: '17 alunos ativos (não 20)',
      transition: 'PREMIUM → ENTERPRISE',
      message:
          'Você está a 3 alunos de lotar. Cada novo = R\$ 400+/mês. Enterprise libera ilimitados.',
    ),
    PaywallUpgradeTrigger(
      number: '05',
      title: 'Clica em marca própria (bloqueado)',
      transition: 'PREMIUM → ENTERPRISE',
      message:
          'Seus alunos veem Focux. Com Enterprise, veem SEU logo. Seu app, sua marca.',
    ),
    PaywallUpgradeTrigger(
      number: '06',
      title: '110+ interações de IA no mês',
      transition: 'PREMIUM → ENTERPRISE',
      message:
          'Você está chegando no limite de IA. Enterprise dá 400/mês + contexto avançado.',
    ),
    PaywallUpgradeTrigger(
      number: '07',
      title: 'Acessa landing page (padrão Focux)',
      transition: 'ENTERPRISE → ENT. PRO',
      message:
          'Sua landing está no padrão Focux. Por +R\$ 50 você libera depoimentos, galeria e FAQ.',
    ),
    PaywallUpgradeTrigger(
      number: '08',
      title: 'Tráfego pago / anúncio no Meta',
      transition: 'ENTERPRISE → ENT. PRO',
      message:
          'Investe em tráfego mas manda para página genérica? Landing que converte lead 24h/dia.',
    ),
  ];
}

class PaywallComparisonRow {
  final String feature;
  final String free;
  final String premium;
  final String enterprise;
  final String enterprisePro;

  const PaywallComparisonRow({
    required this.feature,
    required this.free,
    required this.premium,
    required this.enterprise,
    this.enterprisePro = '—',
  });

  String valueFor(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.FREE => free,
    SubscriptionPlan.PREMIUM => premium,
    SubscriptionPlan.ENTERPRISE => enterprise,
    SubscriptionPlan.ENTERPRISE_PRO => enterprisePro,
  };
}

class PaywallRoiRow {
  final String label;
  final String value;
  final String planChip;
  final Color color;

  const PaywallRoiRow({
    required this.label,
    required this.value,
    required this.planChip,
    required this.color,
  });
}

class PaywallTopFeature {
  final int rank;
  final IconData icon;
  final String title;
  final String badge;
  final Color badgeColor;
  final String description;
  final String roiMoney;
  final List<String> planChips;
  final bool comingSoon;

  const PaywallTopFeature({
    required this.rank,
    required this.icon,
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.description,
    required this.roiMoney,
    required this.planChips,
    this.comingSoon = false,
  });
}

class PaywallUpgradeTrigger {
  final String number;
  final String title;
  final String transition;
  final String message;

  const PaywallUpgradeTrigger({
    required this.number,
    required this.title,
    required this.transition,
    required this.message,
  });
}

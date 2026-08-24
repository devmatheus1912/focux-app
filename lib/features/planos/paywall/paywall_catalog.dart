import 'package:flutter/material.dart';

import '../../../core/brand/focux_microcopy.dart';
import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../assinatura/data/plano.dart';
import '../../subscription/models/subscription_plan.dart';
import 'paywall_price.dart';

/// Catálogo estático de educação e vitrine — preços vêm do backend/loja.
class PaywallCatalog {
  PaywallCatalog._();

  static const Color brand = BrandPalette.defaultPrimary;

  /// Teal profundo — tier ENTERPRISE e CTAs de upgrade.
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
    SubscriptionPlan.PRO => Icons.trending_up_rounded,
    SubscriptionPlan.ENTERPRISE => Icons.diamond_outlined,
    _ => Icons.layers_outlined,
  };

  static Color accentForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.PRO => brand,
    SubscriptionPlan.ENTERPRISE => brandDeep,
    _ => EagleTokens.darkInkMute,
  };

  /// Labels e ícones do tier em card claro (contraste AA, independente da marca do personal).
  static Color tierAccentOnSurface(
    SubscriptionPlan plan, {
    required bool isDark,
  }) {
    if (isDark) return accentForPlan(plan);
    return switch (plan) {
      SubscriptionPlan.ENTERPRISE => EagleTokens.tierEnterpriseProInk,
      SubscriptionPlan.PRO => brandDeep,
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
    SubscriptionPlan.PRO => 'MAIS POPULAR',
    SubscriptionPlan.ENTERPRISE => 'TRIAL $kPaywallMaxPlanTrialDays DIAS',
    _ => null,
  };

  static String displayPlanName(SubscriptionPlan plan) => plan.apiName;

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
    SubscriptionPlan.PRO => 'Para crescer e cobrar',
    SubscriptionPlan.ENTERPRISE => 'Sua marca. Seu time. Seu crescimento.',
  };

  static String? roiTagForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.PRO => 'Custa menos que 1 falta de aluno',
    SubscriptionPlan.ENTERPRISE =>
      'Substitui R\$ 1–3k de agência · 1 aluno novo paga o plano',
    _ => null,
  };

  static String descriptionForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.FREE =>
      'Sem cartão. Sem risco. Para testar com seus primeiros alunos.',
    SubscriptionPlan.PRO =>
      'Para o personal que quer organizar, cobrar e reter alunos.',
    SubscriptionPlan.ENTERPRISE =>
      'Alunos ilimitados, marca própria, landing, loja e equipe.',
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
    (value: '< 1%', label: 'Faturamento = Pro', color: brand),
    (
      value: 'R\$ 50/mês',
      label: 'Substitui R\$ 1–3k agência',
      color: brandDeep,
    ),
    (value: '40%', label: 'Menos inadimplência c/ PIX', color: green),
  ];

  static const List<PaywallComparisonRow> comparisonFreeVsPro = [
    PaywallComparisonRow(feature: 'Alunos', free: '3', paid: '30'),
    PaywallComparisonRow(feature: 'PIX / financeiro', free: '—', paid: '✓'),
    PaywallComparisonRow(feature: 'IA / mês', free: '—', paid: '200'),
    PaywallComparisonRow(feature: 'CRM / leads', free: '—', paid: '✓'),
    PaywallComparisonRow(
      feature: FocuxMicrocopy.commandCenterPlusScoreCompact,
      free: '—',
      paid: '✓',
    ),
    PaywallComparisonRow(
      feature: 'White-label / landing / loja / Pose / NFSe / equipe',
      free: '—',
      paid: '—',
    ),
  ];

  static const List<PaywallComparisonRow> comparisonFreeVsEnterprise = [
    PaywallComparisonRow(feature: 'Alunos', free: '3', paid: '∞'),
    PaywallComparisonRow(feature: 'PIX / financeiro', free: '—', paid: '✓'),
    PaywallComparisonRow(feature: 'IA / mês', free: '—', paid: '600'),
    PaywallComparisonRow(feature: 'CRM / leads', free: '—', paid: '✓'),
    PaywallComparisonRow(
      feature: FocuxMicrocopy.commandCenterPlusScoreCompact,
      free: '—',
      paid: '✓',
    ),
    PaywallComparisonRow(
      feature: 'White-label + domínio',
      free: '—',
      paid: '✓',
    ),
    PaywallComparisonRow(feature: 'Landing + loja', free: '—', paid: '✓'),
    PaywallComparisonRow(feature: 'Pose Coach', free: '—', paid: '✓'),
    PaywallComparisonRow(feature: 'NFSe + equipe (5)', free: '—', paid: '✓'),
  ];

  static const List<PaywallComparisonRow> comparisonRows = comparisonFreeVsPro;


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
      title: '2 alunos cadastrados (não 3)',
      transition: 'FREE → PRO',
      message:
          'Você está a 1 aluno de lotar. Com 30 alunos a R\$ 400 = R\$ 12.000/mês. '
          'Upgrade por R\$ 99,90 — menos que 1 falta de aluno.',
    ),
    PaywallUpgradeTrigger(
      number: '02',
      title: 'Tenta cobrar via PIX (bloqueado)',
      transition: 'FREE → PRO',
      message:
          'Personais que cobram pelo app têm 40% menos inadimplência. Desbloqueie por R\$ 99,90/mês.',
    ),
    PaywallUpgradeTrigger(
      number: '03',
      title: 'IA Copiloto bloqueado',
      transition: 'FREE → PRO',
      message:
          'Sua IA está aguardando. Monte o próximo treino em 3 minutos, não 30. Upgrade por R\$ 99,90.',
    ),
    PaywallUpgradeTrigger(
      number: '04',
      title: '27 alunos ativos (não 30)',
      transition: 'PRO → ENTERPRISE',
      message:
          'Você está a 3 alunos de lotar. Cada novo = R\$ 400+/mês. Enterprise libera ilimitados.',
    ),
    PaywallUpgradeTrigger(
      number: '05',
      title: 'Clica em marca própria (bloqueado)',
      transition: 'PRO → ENTERPRISE',
      message:
          'Seus alunos veem Focux. Com Enterprise, veem SEU logo. Seu app, sua marca.',
    ),
    PaywallUpgradeTrigger(
      number: '06',
      title: '110+ interações de IA no mês',
      transition: 'PRO → ENTERPRISE',
      message:
          'Você está chegando no limite de IA. Enterprise dá 600/mês + landing, loja e equipe.',
    ),
    PaywallUpgradeTrigger(
      number: '07',
      title: 'Acessa landing page (padrão Focux)',
      transition: 'PRO → ENTERPRISE',
      message:
          'Sua landing está no padrão Focux. No Enterprise você libera depoimentos, galeria e FAQ.',
    ),
    PaywallUpgradeTrigger(
      number: '08',
      title: 'Tráfego pago / anúncio no Meta',
      transition: 'PRO → ENTERPRISE',
      message:
          'Investe em tráfego mas manda para página genérica? Landing que converte lead 24h/dia.',
    ),
  ];
}

class PaywallComparisonRow {
  final String feature;
  final String free;
  final String paid;

  const PaywallComparisonRow({
    required this.feature,
    required this.free,
    required this.paid,
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

import 'package:flutter/material.dart';

import '../../assinatura/data/assinatura_repository.dart';
import '../../subscription/models/subscription_plan.dart';

/// Catálogo estático de educação e vitrine — preços vêm do backend/loja.
class PaywallCatalog {
  PaywallCatalog._();

  static const Color brand = Color(0xFF13C2C2);
  static const Color gold = Color(0xFFE5B84C);
  static const Color purple = Color(0xFFA78BFA);
  static const Color green = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFB5760A);

  static Color accentForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.PREMIUM => brand,
    SubscriptionPlan.ENTERPRISE => gold,
    SubscriptionPlan.ENTERPRISE_PRO => purple,
    _ => const Color(0xFF7A8A96),
  };

  static String? badgeForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.PREMIUM => 'MAIS POPULAR',
    SubscriptionPlan.ENTERPRISE => 'TRIAL 14 DIAS',
    SubscriptionPlan.ENTERPRISE_PRO => 'MÁXIMO ROI',
    _ => null,
  };

  static String subtitleForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.FREE => 'Para começar',
    SubscriptionPlan.PREMIUM => 'Para personal em crescimento',
    SubscriptionPlan.ENTERPRISE => 'Para escalar com sua marca',
    SubscriptionPlan.ENTERPRISE_PRO => 'Seu app. Sua marca. Sua página.',
  };

  static String? roiTagForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.PREMIUM => '💰 Custa menos que 1 falta de aluno',
    SubscriptionPlan.ENTERPRISE => '💰 1 aluno novo paga o plano inteiro',
    SubscriptionPlan.ENTERPRISE_PRO => '💰 Poupa R\$ 1k–3k de agência',
    _ => null,
  };

  static String descriptionForPlan(SubscriptionPlan plan) => switch (plan) {
    SubscriptionPlan.FREE =>
      'Sem cartão. Sem risco. Para testar com seus primeiros alunos.',
    SubscriptionPlan.PREMIUM =>
      'Para o personal que quer organizar, cobrar e reter alunos.',
    SubscriptionPlan.ENTERPRISE =>
      'Alunos ilimitados + white-label + sua identidade no app.',
    SubscriptionPlan.ENTERPRISE_PRO =>
      'Tudo do Enterprise + landing completa + loja digital (em breve).',
  };

  static const List<({String value, String label})> socialProof = [
    (value: '2.847', label: 'personais ativos'),
    (value: '4.9★', label: 'App Store · 312 avaliações'),
    (value: '43', label: 'upgrades esta semana'),
  ];

  static const List<({String value, String label, Color color})> roiStrip = [
    (value: '5×', label: 'ROI médio em 2 anos', color: brand),
    (value: '< 1%', label: 'do faturamento = Premium', color: brand),
    (value: 'R\$ 8.000', label: 'MRR com 20 alunos', color: green),
    (value: 'R\$ 50/mês', label: 'vs R\$ 1–3k em agência', color: purple),
  ];

  static List<PaywallFeatureEducation> featuresForPlan(
    Plano plano,
    SubscriptionPlan plan,
  ) {
    final unlimited = plano.limiteAlunos == null;
    final alunosLabel =
        unlimited ? 'Alunos ILIMITADOS' : 'Até ${plano.limiteAlunos} alunos';
    final rows = <PaywallFeatureRow>[
      PaywallFeatureRow(label: alunosLabel, included: true, highlight: unlimited),
      if (plan != SubscriptionPlan.FREE)
        PaywallFeatureRow(
          label: plan == SubscriptionPlan.ENTERPRISE
              ? 'IA Copiloto — 400+ interações/mês'
              : 'IA Copiloto — 120 interações/mês',
          included: true,
          highlight: true,
        ),
      if (plan != SubscriptionPlan.FREE)
        PaywallFeatureRow(
          label: 'PIX com QR Code + cobrança no chat',
          included: plano.temFinanceiro,
          highlight: plano.temFinanceiro,
        ),
      if (plan != SubscriptionPlan.FREE)
        PaywallFeatureRow(
          label: 'Command Center + Focux Score™',
          included: plano.temRelatorios,
          highlight: plano.temRelatorios,
        ),
      if (plan == SubscriptionPlan.ENTERPRISE || plan == SubscriptionPlan.ENTERPRISE_PRO)
        PaywallFeatureRow(
          label: 'White-label — seu logo e suas cores',
          included: plano.temWhiteLabel,
          highlight: true,
        ),
      if (plan == SubscriptionPlan.ENTERPRISE_PRO)
        PaywallFeatureRow(
          label: 'Landing page COMPLETA',
          included: plano.temLandingCompleta,
          highlight: true,
        ),
      if (plan == SubscriptionPlan.FREE) ...[
        PaywallFeatureRow(label: 'PIX com QR Code no chat', included: false),
        PaywallFeatureRow(label: 'IA Copiloto', included: false),
        PaywallFeatureRow(label: 'CRM + landing page', included: false),
      ],
    ];
    return rows
        .map(
          (r) => PaywallFeatureEducation(
            row: r,
            education: educationByLabel[r.label],
          ),
        )
        .toList();
  }

  static const Map<String, PaywallEducationContent> educationByLabel = {
    'PIX com QR Code + cobrança no chat': PaywallEducationContent(
      id: 'pix_chat',
      title: 'PIX + QR Code no chat',
      whatIs:
          'Você gera um QR Code de cobrança direto na conversa com o aluno. '
          'Ele escaneia e paga na hora — sem sair do app.',
      whyMatters:
          'Personais que cobram pelo app têm 40% menos inadimplência. '
          'Chega de cobrar no WhatsApp sem saber se foi pago.',
      roiStatement: '💰 1 mensalidade recuperada = 5× o custo do Premium',
      plans: ['PREMIUM', 'ENTERPRISE'],
    ),
    'IA Copiloto — 120 interações/mês': PaywallEducationContent(
      id: 'ia_copiloto',
      title: 'IA Copiloto',
      whatIs:
          'IA que conhece o histórico, aderência e Recovery Score de cada aluno. '
          'Monta treino e responde em minutos.',
      whyMatters:
          'Treino pronto em 3 minutos, não 30. Você escala sem perder qualidade.',
      roiStatement: '💰 5h/semana = R\$ 1.280+/mês em produtividade',
      plans: ['PREMIUM', 'ENTERPRISE'],
    ),
    'IA Copiloto — 400+ interações/mês': PaywallEducationContent(
      id: 'ia_copiloto_ent',
      title: 'IA Copiloto avançada',
      whatIs:
          'Mesma IA com mais interações e contexto avançado por aluno.',
      whyMatters:
          'Ideal para operações com muitos alunos e alto volume de ajustes.',
      roiStatement: '💰 Escala sem contratar assistente full-time',
      plans: ['ENTERPRISE'],
    ),
    'Command Center + Focux Score™': PaywallEducationContent(
      id: 'command_center',
      title: 'Command Center + Focux Score™',
      whatIs:
          'Painel do CEO do personal: quem vai cancelar, inadimplência e próxima ação.',
      whyMatters:
          'Em 2 minutos você sabe o que priorizar — sem planilha.',
      roiStatement: '💰 Salvar 1 aluno/mês = R\$ 300–600',
      plans: ['PREMIUM', 'ENTERPRISE'],
    ),
    'White-label — seu logo e suas cores': PaywallEducationContent(
      id: 'white_label',
      title: 'White-label',
      whatIs:
          'Seus alunos abrem o app com SEU logo e SUAS cores — não um visual genérico.',
      whyMatters:
          'Posicionamento premium que justifica cobrar 20–30% mais.',
      roiStatement: '💰 Diferencial de marca = ticket maior',
      plans: ['ENTERPRISE'],
    ),
    'Alunos ILIMITADOS': PaywallEducationContent(
      id: 'alunos_ilimitados',
      title: 'Alunos ilimitados',
      whatIs: 'Sem teto de cadastro de alunos ativos no app.',
      whyMatters:
          'Cada novo aluno = R\$ 300–600/mês. O teto do plano anterior vira receita perdida.',
      roiStatement: '💰 ROI imediato no 1º aluno extra',
      plans: ['ENTERPRISE'],
    ),
  };

  static const List<PaywallComparisonRow> comparisonRows = [
    PaywallComparisonRow(feature: 'PIX + QR Code', free: '—', premium: '✓', enterprise: '✓'),
    PaywallComparisonRow(
      feature: 'IA Copiloto',
      free: '—',
      premium: '120/mês',
      enterprise: '400+/mês',
    ),
    PaywallComparisonRow(
      feature: 'Command Center+Score™',
      free: '—',
      premium: '✓',
      enterprise: '✓',
    ),
    PaywallComparisonRow(feature: 'White-label', free: '—', premium: '—', enterprise: '✓'),
    PaywallComparisonRow(feature: 'Alunos', free: '5', premium: '20', enterprise: '∞'),
    PaywallComparisonRow(feature: 'Recovery Score', free: '—', premium: '✓', enterprise: '✓'),
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
      label: 'Alunos ilimitados — sem teto',
      value: 'Cada novo = R\$ 300–600/mês',
      planChip: 'ENTERPRISE',
      color: gold,
    ),
  ];
}

class PaywallFeatureRow {
  final String label;
  final bool included;
  final bool highlight;
  final bool comingSoon;

  const PaywallFeatureRow({
    required this.label,
    required this.included,
    this.highlight = false,
    this.comingSoon = false,
  });
}

class PaywallFeatureEducation {
  final PaywallFeatureRow row;
  final PaywallEducationContent? education;

  const PaywallFeatureEducation({required this.row, this.education});
}

class PaywallEducationContent {
  final String id;
  final String title;
  final String whatIs;
  final String whyMatters;
  final String? roiStatement;
  final List<String> plans;

  const PaywallEducationContent({
    required this.id,
    required this.title,
    required this.whatIs,
    required this.whyMatters,
    this.roiStatement,
    required this.plans,
  });
}

class PaywallComparisonRow {
  final String feature;
  final String free;
  final String premium;
  final String enterprise;

  const PaywallComparisonRow({
    required this.feature,
    required this.free,
    required this.premium,
    required this.enterprise,
  });
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

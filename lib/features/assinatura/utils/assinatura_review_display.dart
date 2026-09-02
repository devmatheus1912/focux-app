import '../../../core/brand/focux_microcopy.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/store_subscription_policy.dart';
import '../../subscription/subscription_products.dart';

String assinaturaReviewTitle() => 'Confirmar assinatura';

String assinaturaReviewConfirmLabel() => 'Confirmar e assinar';

String assinaturaReviewBackLabel() => 'Voltar';

String assinaturaReviewEmptyTitle() => 'Preço indisponível';

String assinaturaReviewEmptySubtitle() =>
    'Não encontramos o valor deste plano na loja. Volte e tente de novo.';

String assinaturaReviewBillingLine(SubscriptionBillingPeriod period) {
  final freq = assinaturaReviewFrequency(period);
  return 'Cobrança $freq · renovação automática';
}

String assinaturaReviewFrequency(SubscriptionBillingPeriod period) =>
    period == SubscriptionBillingPeriod.yearly ? 'Anual' : 'Mensal';

String assinaturaReviewNextBillLabel(DateTime nextBill) {
  final day = nextBill.day.toString().padLeft(2, '0');
  final month = nextBill.month.toString().padLeft(2, '0');
  return 'Próxima cobrança estimada: $day/$month/${nextBill.year}';
}

DateTime assinaturaReviewNextBill(
  DateTime now,
  SubscriptionBillingPeriod period,
) {
  return now.add(
    Duration(days: period == SubscriptionBillingPeriod.yearly ? 365 : 30),
  );
}

String assinaturaReviewPlanLabel(SubscriptionPlan plan) =>
    PaywallCatalog.displayPlanName(plan);

List<String> assinaturaReviewTopFeatures(SubscriptionPlan plan) =>
    switch (plan) {
      SubscriptionPlan.ENTERPRISE => const [
        'Landing page completa com depoimentos e FAQ',
        'Marca própria e domínio customizado',
        'Alunos ilimitados + IA 600/mês + equipe (5)',
      ],
      SubscriptionPlan.PRO => [
        'Até 30 alunos ativos',
        'PIX e financeiro no app',
        'IA Copiloto e ${FocuxMicrocopy.commandCenter}',
        'Agenda e relatórios avançados',
      ],
      _ => const ['Recursos do plano selecionado'],
    };

String assinaturaReviewLegalBody({
  required String price,
  required SubscriptionBillingPeriod period,
}) {
  final freq = assinaturaReviewFrequency(period);
  final channel = subscriptionChannelLabel();
  return 'Ao confirmar, você autoriza a cobrança de $price na forma de pagamento '
      'da $channel. A assinatura renova automaticamente ($freq) até ser cancelada. '
      'Cancele quando quiser em Ajustes > Assinaturas.\n\n'
      'Base legal (LGPD): execução de contrato para processar pagamento e entregar o serviço. '
      'Dados de pagamento são processados pela $channel — a Focux não armazena número de cartão.';
}

/// Copy de falha da loja. Nunca ecoa `PurchaseError.message` cru.
String assinaturaStoreFailureCopy() =>
    'Não foi possível concluir a compra na loja. Tente de novo.';

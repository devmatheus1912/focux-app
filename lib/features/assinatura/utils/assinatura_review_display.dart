import '../../subscription/utils/plano_ia_limits.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/store_subscription_policy.dart';
import '../../subscription/subscription_products.dart';

String assinaturaReviewTitle() => 'Confirmar assinatura';

/// O botão diz o que acontece ao tocar.
String assinaturaReviewConfirmLabel({required String price, int? trialDias}) =>
    trialDias == null ? 'Assinar por $price' : 'Começar $trialDias dias grátis';

String assinaturaReviewBackLabel() => 'Voltar';

String assinaturaReviewEmptyTitle() => 'Preço indisponível';

String assinaturaReviewEmptySubtitle() =>
    'Não encontramos o valor deste plano na loja. Volte e tente de novo.';

String assinaturaReviewFrequency(SubscriptionBillingPeriod period) =>
    period == SubscriptionBillingPeriod.yearly ? 'Anual' : 'Mensal';

String _data(DateTime dia) {
  final d = dia.day.toString().padLeft(2, '0');
  final m = dia.month.toString().padLeft(2, '0');
  return '$d/$m/${dia.year}';
}

/// Com teste, a cobrança vem no fim dele, em qualquer período.
DateTime assinaturaReviewNextBill(
  DateTime now,
  SubscriptionBillingPeriod period, {
  int? trialDias,
}) {
  final dias =
      trialDias ?? (period == SubscriptionBillingPeriod.yearly ? 365 : 30);
  return now.add(Duration(days: dias));
}

/// Quanto sai hoje e o que vem depois.
List<({String quando, String valor})> assinaturaReviewLinhas({
  required DateTime now,
  required SubscriptionBillingPeriod period,
  required String price,
  int? trialDias,
}) {
  final proxima = _data(
    assinaturaReviewNextBill(now, period, trialDias: trialDias),
  );
  if (trialDias != null) {
    return [
      (quando: 'Hoje', valor: 'R\$ 0,00'),
      (quando: proxima, valor: price),
    ];
  }
  return [
    (quando: 'Hoje', valor: price),
    (quando: 'Renova em $proxima', valor: price),
  ];
}

/// Fica sempre à vista; o texto completo abre em "Detalhes da cobrança".
String assinaturaReviewResumo({int? trialDias}) {
  final onde = subscriptionCancelWhere();
  return trialDias == null
      ? 'Renova sozinha até você cancelar. Cancele $onde até 24 horas antes da renovação.'
      : 'Depois do teste, renova sozinha. Cancele $onde até 24 horas antes do fim do teste para não ser cobrado.';
}

String assinaturaReviewPlanLabel(SubscriptionPlan plan) =>
    PaywallCatalog.displayPlanName(plan);

List<String> assinaturaReviewTopFeatures(SubscriptionPlan plan) =>
    switch (plan) {
      SubscriptionPlan.ENTERPRISE => const [
        'Alunos sem limite e 600 usos de IA por mês',
        'Landing page completa com depoimentos e FAQ',
        'Marca própria no app e na landing',
      ],
      SubscriptionPlan.PRO => [
        'Até ${PlanoAlunosLimits.pro} alunos ativos',
        'PIX e financeiro no app',
        'IA Copiloto e ${FocuxMicrocopy.commandCenter}',
      ],
      _ => const ['Recursos do plano selecionado'],
    };

String assinaturaReviewLegalBody({
  required String price,
  required SubscriptionBillingPeriod period,
}) {
  final freq = assinaturaReviewFrequency(period);
  return 'Ao confirmar, você autoriza a cobrança de $price na forma de pagamento '
      '${subscriptionChannelWith(ChannelPreposition.de)}. A assinatura renova automaticamente ($freq) até ser cancelada. '
      'Cancele quando quiser ${subscriptionCancelWhere()}, até 24 horas antes da renovação.\n\n'
      'Base legal (LGPD): execução de contrato para processar pagamento e entregar o serviço. '
      'Dados de pagamento são processados ${subscriptionChannelWith(ChannelPreposition.por)} — a Focux não armazena número de cartão.';
}

/// Copy de falha da loja. Nunca ecoa `PurchaseError.message` cru.
String assinaturaStoreFailureCopy() =>
    'Não foi possível concluir a compra na loja. Tente de novo.';

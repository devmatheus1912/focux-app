import '../../subscription/utils/plano_ia_limits.dart';
import '../../../core/brand/focux_microcopy.dart';
import '../../planos/paywall/paywall_catalog.dart';
import '../../subscription/models/subscription_plan.dart';
import '../../subscription/store_subscription_policy.dart';
import '../../subscription/subscription_products.dart';
import '../../../l10n/pt.dart';

String assinaturaReviewTitle() => ptS.assinaturaConfirmarAssinatura;

/// O botão diz o que acontece ao tocar.
String assinaturaReviewConfirmLabel({required String price, int? trialDias}) =>
    trialDias == null ? ptS.assinaturaAssinarPor(price) : ptS.assinaturaComecarDiasGratis(trialDias);

String assinaturaReviewBackLabel() => ptS.anamneseAlunoVoltar;

String assinaturaReviewEmptyTitle() => ptS.assinaturaPrecoIndisponivel;

String assinaturaReviewEmptySubtitle() =>
    ptS.assinaturaNaoEncontramosOValorDeste;

String assinaturaReviewFrequency(SubscriptionBillingPeriod period) =>
    period == SubscriptionBillingPeriod.yearly ? ptS.assinaturaAnual : ptS.assinaturaMensal;

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
      (quando: ptS.dockHoje, valor: ptS.assinaturaR000),
      (quando: proxima, valor: price),
    ];
  }
  return [
    (quando: ptS.dockHoje, valor: price),
    (quando: ptS.assinaturaRenovaEm(proxima), valor: price),
  ];
}

/// Fica sempre à vista; o texto completo abre em "Detalhes da cobrança".
String assinaturaReviewResumo({int? trialDias}) {
  final onde = subscriptionCancelWhere();
  return trialDias == null
      ? ptS.assinaturaRenovaSozinhaAteVoceCancelar(onde)
      : ptS.assinaturaDepoisDoTesteRenovaSozinha(onde);
}

String assinaturaReviewPlanLabel(SubscriptionPlan plan) =>
    PaywallCatalog.displayPlanName(plan);

List<String> assinaturaReviewTopFeatures(SubscriptionPlan plan) =>
    switch (plan) {
      SubscriptionPlan.ENTERPRISE => [
        ptS.assinaturaAlunosSemLimiteE600,
        ptS.assinaturaLandingPageCompletaComDepoimentos,
        ptS.assinaturaMarcaPropriaNoAppE,
      ],
      SubscriptionPlan.PRO => [
        ptS.assinaturaAteAlunosAtivos(PlanoAlunosLimits.pro),
        ptS.assinaturaPixEFinanceiroNoApp,
        ptS.assinaturaIaCopilotoE(FocuxMicrocopy.commandCenter),
      ],
      _ => [ptS.assinaturaRecursosDoPlanoSelecionado],
    };

String assinaturaReviewLegalBody({
  required String price,
  required SubscriptionBillingPeriod period,
}) {
  final freq = assinaturaReviewFrequency(period);
  return ptS.assinaturaAoConfirmarVoceAutorizaA(price) +
      ptS.assinaturaAAssinaturaRenovaAutomaticamenteAte(subscriptionChannelWith(ChannelPreposition.de), freq) +
      ptS.assinaturaCanceleQuandoQuiserAte24(subscriptionCancelWhere()) +
      ptS.assinaturaBaseLegalLgpdExecucaoDe +
      ptS.assinaturaDadosDePagamentoSaoProcessados(subscriptionChannelWith(ChannelPreposition.por));
}

/// Copy de falha da loja. Nunca ecoa `PurchaseError.message` cru.
String assinaturaStoreFailureCopy() =>
    ptS.assinaturaNaoFoiPossivelConcluirA;

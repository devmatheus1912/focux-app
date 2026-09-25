import '../../../l10n/app_localizations.dart';
import '../data/referral_info.dart';

/// Tom visual de um status; o widget traduz para cor.
enum ReferralTone { positive, neutral, warning, negative }

/// Aviso de topo do painel, em ordem de prioridade.
enum ReferralBanner { none, campaignInactive, limitReached, underReview }

String referralCodigoLabel(String? codigo) {
  final value = codigo?.trim();
  if (value == null || value.isEmpty) return '—';
  return value;
}

bool referralTemLink(String? link) {
  final value = link?.trim();
  return value != null && value.isNotEmpty;
}

bool _temDesconto(ReferralInfo info) =>
    info.campanhaAtiva && (info.descontoIndicadoPct ?? 0) > 0;

bool _temRecompensa(ReferralInfo info) =>
    info.campanhaAtiva && (info.diasPorIndicacao ?? 0) > 0;

String referralInviteText(S l10n, ReferralInfo info) {
  final codigo = referralCodigoLabel(info.codigo);
  final link = info.linkCompartilhamento.trim();
  if (_temDesconto(info)) {
    return l10n.referralInviteTextDiscount(
      codigo,
      info.descontoIndicadoPct!,
      link,
    );
  }
  return l10n.referralInviteText(codigo, link);
}

String referralHubSubtitle(S l10n, ReferralInfo? info, String? freshness) {
  final base = info == null
      ? l10n.referralTitle
      : _temRecompensa(info)
      ? l10n.referralHubSubtitle(info.diasPorIndicacao!)
      : l10n.referralCampaignInactiveShort;
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String? referralRewardHeadline(S l10n, ReferralInfo info) {
  if (!_temRecompensa(info)) return null;
  return l10n.referralRewardHeadline(info.diasPorIndicacao!);
}

String? referralDiscountLine(S l10n, ReferralInfo info) {
  if (!_temDesconto(info)) return null;
  return l10n.referralDiscountLine(info.descontoIndicadoPct!);
}

/// "X de N" recompensas; nulo sem campanha (o servidor não mandou o limite).
String? referralRewardsProgress(S l10n, ReferralInfo info) {
  final max = info.maxRecompensas;
  if (!info.campanhaAtiva || max == null) return null;
  return l10n.referralRewardsProgress(info.recompensasConcedidas, max);
}

/// "Y de M dias"; sem campanha mostra só o acumulado.
String referralDaysProgress(S l10n, ReferralInfo info) {
  final teto = info.tetoDias;
  if (!info.campanhaAtiva || teto == null) return '${info.diasGanhos}';
  return l10n.referralDaysProgress(info.diasGanhos, teto);
}

ReferralBanner referralBanner(ReferralInfo info) {
  if (!info.campanhaAtiva) return ReferralBanner.campaignInactive;
  if (info.recompensasEmAnalise > 0) return ReferralBanner.underReview;
  if (info.limiteAtingido) return ReferralBanner.limitReached;
  return ReferralBanner.none;
}

String? referralBannerText(S l10n, ReferralInfo info) {
  switch (referralBanner(info)) {
    case ReferralBanner.none:
      return null;
    case ReferralBanner.campaignInactive:
      return l10n.referralCampaignInactive;
    case ReferralBanner.limitReached:
      return l10n.referralLimitReachedBanner;
    case ReferralBanner.underReview:
      return l10n.referralUnderReviewBanner(info.recompensasEmAnalise);
  }
}

String referralStatusLabel(S l10n, ReferralIndicacao item) {
  switch (item.status) {
    case ReferralIndicacaoStatus.pending:
      return l10n.referralStatusPending;
    case ReferralIndicacaoStatus.trial:
      return l10n.referralStatusTrial;
    case ReferralIndicacaoStatus.rewardGranted:
      return l10n.referralStatusGranted(item.dias);
    case ReferralIndicacaoStatus.underReview:
      return l10n.referralStatusUnderReview;
    case ReferralIndicacaoStatus.noReward:
      return l10n.referralStatusNoReward;
    case ReferralIndicacaoStatus.reversed:
      return l10n.referralStatusReversed;
    case ReferralIndicacaoStatus.notEligible:
      return l10n.referralStatusNotEligible;
  }
}

ReferralTone referralStatusTone(ReferralIndicacaoStatus status) {
  switch (status) {
    case ReferralIndicacaoStatus.rewardGranted:
      return ReferralTone.positive;
    case ReferralIndicacaoStatus.underReview:
      return ReferralTone.warning;
    case ReferralIndicacaoStatus.reversed:
    case ReferralIndicacaoStatus.notEligible:
      return ReferralTone.negative;
    case ReferralIndicacaoStatus.pending:
    case ReferralIndicacaoStatus.trial:
    case ReferralIndicacaoStatus.noReward:
      return ReferralTone.neutral;
  }
}

/// Passos do "Como funciona" com os números da campanha vigente (nunca fixos no app).
List<({String titulo, String detalhe})> referralComoFuncionaPassos(
  S l10n,
  ReferralInfo info,
) {
  final dias = info.diasPorIndicacao;
  final max = info.maxRecompensas;
  final teto = info.tetoDias;
  final comValores =
      info.campanhaAtiva && dias != null && max != null && teto != null;
  return [
    (titulo: l10n.referralStep1Title, detalhe: l10n.referralStep1Detail),
    (titulo: l10n.referralStep2Title, detalhe: l10n.referralStep2Detail),
    comValores
        ? (
            titulo: l10n.referralStep3Title(dias),
            detalhe: l10n.referralStep3Detail(max, teto),
          )
        : (
            titulo: l10n.referralStep3TitleGeneric,
            detalhe: l10n.referralStep3DetailGeneric,
          ),
  ];
}

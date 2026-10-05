import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/operational_metric_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../dashboard/widgets/dashboard_section_header.dart';
import '../data/referral_info.dart';
import '../utils/referral_display.dart';

Color referralToneColor(ReferralTone tone, Color neutral) {
  switch (tone) {
    case ReferralTone.positive:
      return EagleTokens.good;
    case ReferralTone.warning:
      return EagleTokens.warn;
    case ReferralTone.negative:
      return EagleTokens.bad;
    case ReferralTone.neutral:
      return neutral;
  }
}

class ReferralBody extends StatelessWidget {
  const ReferralBody({
    super.key,
    required this.info,
    required this.isDark,
    required this.onShare,
    required this.onCopyLink,
  });

  final ReferralInfo info;
  final bool isDark;
  final VoidCallback onShare;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final chrome = ShellChrome.forBrightness(context, isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final banner = referralBannerText(l10n, info);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(TokensStrip.s4),
      children: [
        if (banner != null) ...[
          _ReferralBannerCard(
            text: banner,
            accent: referralBanner(info) == ReferralBanner.underReview
                ? EagleTokens.warn
                : chrome.mute,
            ink: chrome.ink,
          ),
          const SizedBox(height: TokensStrip.s3),
        ],
        _ReferralCodeCard(
          info: info,
          isDark: isDark,
          onShare: onShare,
          onCopyLink: onCopyLink,
        ),
        const SizedBox(height: TokensStrip.s4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: OperationalMetricTile(
                label: l10n.referralRewardsMetric,
                value: referralRewardsProgress(l10n, info) ?? '—',
                hint: l10n.referralConvertedCount(info.usosTotais),
                color: primary,
                isDark: isDark,
                emphasis: info.limiteAtingido
                    ? OperationalMetricEmphasis.muted
                    : OperationalMetricEmphasis.normal,
              ),
            ),
            const SizedBox(width: TokensStrip.s2),
            Expanded(
              child: OperationalMetricTile(
                label: l10n.referralDaysMetric,
                value: referralDaysProgress(l10n, info),
                color: EagleTokens.good,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensStrip.s4),
        DashboardSectionHeader(title: l10n.referralListTitle),
        const SizedBox(height: TokensStrip.s2),
        if (info.indicacoes.isEmpty)
          FxEmptyState(
            icon: 'users',
            title: l10n.referralListEmptyTitle,
            subtitle: l10n.referralListEmptySubtitle,
            quiet: true,
          )
        else
          for (final item in info.indicacoes)
            FxSatelliteListTile(
              title: item.nomeMascarado,
              titleCase: false,
              accent: referralToneColor(
                referralStatusTone(item.status),
                chrome.mute,
              ),
              subtitle: Text(
                referralStatusLabel(l10n, item),
                style: FocuxHubTypography.body(
                  color: referralToneColor(
                    referralStatusTone(item.status),
                    chrome.mute,
                  ),
                ),
              ),
            ),
        const SizedBox(height: TokensStrip.s4),
        DashboardSectionHeader(title: l10n.referralHowItWorks),
        const SizedBox(height: TokensStrip.s2),
        for (final passo in referralComoFuncionaPassos(l10n, info))
          FxSatelliteListTile(
            title: passo.titulo,
            titleCase: false,
            subtitle: Text(passo.detalhe),
          ),
      ],
    );
  }
}

class _ReferralBannerCard extends StatelessWidget {
  const _ReferralBannerCard({
    required this.text,
    required this.accent,
    required this.ink,
  });

  final String text;
  final Color accent;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return FxStripCard(
      accent: accent,
      semanticsLabel: text,
      child: Text(text, style: FocuxHubTypography.body(color: ink)),
    );
  }
}

class _ReferralCodeCard extends StatelessWidget {
  const _ReferralCodeCard({
    required this.info,
    required this.isDark,
    required this.onShare,
    required this.onCopyLink,
  });

  final ReferralInfo info;
  final bool isDark;
  final VoidCallback onShare;
  final VoidCallback onCopyLink;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final chrome = ShellChrome.forBrightness(context, isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final codigo = referralCodigoLabel(info.codigo);
    final headline = referralRewardHeadline(l10n, info);
    final desconto = referralDiscountLine(l10n, info);
    return FxStripCard(
      emphasize: true,
      semanticsLabel: l10n.referralCodeSemantics(codigo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.referralYourCode,
            style: FocuxHubTypography.chip(chrome.mute),
          ),
          const SizedBox(height: 6),
          SelectableText(
            codigo,
            style: FocuxHubTypography.kpi(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          if (headline != null) ...[
            const SizedBox(height: 6),
            Text(
              headline,
              style: FocuxHubTypography.body(
                color: chrome.ink,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          if (desconto != null) ...[
            const SizedBox(height: 4),
            Text(desconto, style: FocuxHubTypography.body(color: chrome.mute)),
          ],
          const SizedBox(height: TokensStrip.s3),
          Wrap(
            spacing: TokensStrip.s2,
            runSpacing: TokensStrip.s2,
            children: [
              FxActionChip(
                label: l10n.referralCopyInvite,
                accent: primary,
                isDark: isDark,
                onPressed: onShare,
              ),
              if (referralTemLink(info.linkCompartilhamento))
                FxActionChip(
                  label: l10n.referralCopyLinkOnly,
                  accent: chrome.mute,
                  isDark: isDark,
                  onPressed: onCopyLink,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

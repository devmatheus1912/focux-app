import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../core/widgets/fx_empty_state.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_strip_card.dart';
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
        _ReferralProgresso(info: info, isDark: isDark),
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
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: Text(
              l10n.referralHowItWorks,
              style: FocuxHubTypography.sectionTitle(
                context,
                color: chrome.ink,
              ),
            ),
            children: [
              for (final passo in referralComoFuncionaPassos(l10n, info))
                FxSatelliteListTile(
                  title: passo.titulo,
                  titleCase: false,
                  subtitle: Text(passo.detalhe),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReferralProgresso extends StatelessWidget {
  const _ReferralProgresso({required this.info, required this.isDark});

  final ReferralInfo info;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final chrome = ShellChrome.forBrightness(context, isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final texto = [
      if (referralRewardsProgress(l10n, info) case final premios?) premios,
      referralDaysProgress(l10n, info),
    ].join(' · ');
    return FxStripCard(
      semanticsLabel: texto,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.referralRewardsMetric,
            style: FocuxHubTypography.chip(chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(texto, style: FocuxHubTypography.cardTitle(color: chrome.ink)),
          const SizedBox(height: TokensStrip.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensStrip.s1),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: referralProgressoFracao(info),
              color: primary,
              backgroundColor: primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
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
    final codigo = referralCodigoLabel(info.codigo);
    final headline = referralRewardHeadline(l10n, info);
    final desconto = referralDiscountLine(l10n, info);
    return FxStripCard(
      emphasize: true,
      semanticsLabel: l10n.referralCodeSemantics(codigo),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headline != null) ...[
            Text(
              headline,
              style: FocuxHubTypography.cardTitle(color: chrome.ink),
            ),
            const SizedBox(height: TokensStrip.s1),
          ],
          if (desconto != null) ...[
            Text(
              desconto,
              style: FocuxHubTypography.bodyMuted(color: chrome.mute),
            ),
            const SizedBox(height: TokensStrip.s3),
          ],
          Text(
            l10n.referralYourCode,
            style: FocuxHubTypography.chip(chrome.mute),
          ),
          const SizedBox(height: 2),
          SelectableText(
            codigo,
            style: FocuxHubTypography.metric(
              color: chrome.ink,
              fontSize: FocuxHubTypography.metricLg,
            ),
          ),
          const SizedBox(height: TokensStrip.s3),
          FxLiquidPrimaryButton(
            label: l10n.referralCopyInvite,
            onPressed: onShare,
          ),
          if (referralTemLink(info.linkCompartilhamento)) ...[
            const SizedBox(height: TokensStrip.s2),
            FxTonalButton(
              label: l10n.referralCopyLinkOnly,
              expanded: true,
              onPressed: onCopyLink,
            ),
          ],
        ],
      ),
    );
  }
}

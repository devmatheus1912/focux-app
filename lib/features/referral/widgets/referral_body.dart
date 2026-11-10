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
import '../../../core/theme/fx_icons.dart';

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
    required this.onCopyCode,
  });

  final ReferralInfo info;
  final bool isDark;
  final VoidCallback onShare;
  final VoidCallback onCopyLink;
  final VoidCallback onCopyCode;

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
          onShare: onShare,
          onCopyLink: onCopyLink,
          onCopyCode: onCopyCode,
        ),
        if (referralMostraProgresso(info)) ...[
          const SizedBox(height: TokensStrip.s4),
          _ReferralProgresso(info: info, isDark: isDark),
        ],
        const SizedBox(height: TokensStrip.s4),
        DashboardSectionHeader(title: l10n.referralListTitle),
        const SizedBox(height: TokensStrip.s2),
        if (info.indicacoes.isEmpty)
          FxEmptyState(
            icon: FxIcons.grupo,
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
        _ComoFunciona(
          info: info,
          // Quem já indicou conhece as regras: começa fechado.
          abertoNoInicio: info.indicacoes.isEmpty,
        ),
      ],
    );
  }
}

/// Regras completas num lugar só, recolhível, no desenho dos outros cartões.
class _ComoFunciona extends StatefulWidget {
  const _ComoFunciona({required this.info, required this.abertoNoInicio});

  final ReferralInfo info;
  final bool abertoNoInicio;

  @override
  State<_ComoFunciona> createState() => _ComoFuncionaState();
}

class _ComoFuncionaState extends State<_ComoFunciona> {
  late bool _aberto = widget.abertoNoInicio;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final chrome = ShellChrome.of(context);
    return FxStripCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _aberto,
            child: InkWell(
              onTap: () => setState(() => _aberto = !_aberto),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.referralHowItWorks,
                        style: FocuxHubTypography.cardTitle(color: chrome.ink),
                      ),
                    ),
                    Icon(
                      _aberto ? FxIcons.chevronCima : FxIcons.chevronBaixo,
                      size: 20,
                      color: chrome.mute,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_aberto)
            for (final passo in referralComoFuncionaPassos(l10n, widget.info))
              Padding(
                padding: const EdgeInsets.only(top: TokensStrip.s3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passo.titulo,
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      passo.detalhe,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  ],
                ),
              ),
        ],
      ),
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
    final texto = referralProgressoTexto(l10n, info);
    return FxStripCard(
      semanticsLabel: texto,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
    required this.onShare,
    required this.onCopyLink,
    required this.onCopyCode,
  });

  final ReferralInfo info;
  final VoidCallback onShare;
  final VoidCallback onCopyLink;
  final VoidCallback onCopyCode;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final sobre = fxPaletaSobreMarca(context);
    final codigo = referralCodigoLabel(info.codigo);
    final headline = referralRewardHeadline(l10n, info);
    final desconto = referralDiscountLine(l10n, info);
    final temLink = referralTemLink(info.linkCompartilhamento);
    return FxStripCard(
      marca: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (headline != null)
            Text(
              headline,
              style: FocuxHubTypography.cardTitle(color: sobre.ink),
            ),
          if (desconto != null) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(
              desconto,
              style: FocuxHubTypography.bodyMuted(color: sobre.mute),
            ),
          ],
          const SizedBox(height: TokensStrip.s3),
          Text(
            l10n.referralYourCode,
            style: FocuxHubTypography.chip(sobre.mute),
          ),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: l10n.referralCodeSemantics(
                    referralCodigoSoletrado(codigo),
                  ),
                  excludeSemantics: true,
                  child: SelectableText(
                    codigo,
                    style: FocuxHubTypography.metric(
                      color: sobre.ink,
                      fontSize: TokensStrip.fontTitulo,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.referralCopiarCodigo,
                onPressed: onCopyCode,
                icon: Icon(FxIcons.copiar, color: sobre.ink),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s3),
          FxLiquidPrimaryButton(
            label: l10n.referralCopyInvite,
            onPressed: onShare,
          ),
          if (temLink) ...[
            const SizedBox(height: TokensStrip.s2),
            // Sobre o bloco: cor da paleta da marca, não o tonal do tema
            // (que sai quase preto sobre o teal).
            FxTonalButton(
              label: l10n.referralCopyLinkOnly,
              expanded: true,
              fundo: sobre.ink.withValues(alpha: 0.14),
              texto: sobre.ink,
              onPressed: onCopyLink,
            ),
            const SizedBox(height: TokensStrip.s2),
            Text(
              l10n.referralLinkLevaCodigo,
              style: FocuxHubTypography.bodyMuted(color: sobre.mute),
            ),
          ],
        ],
      ),
    );
  }
}

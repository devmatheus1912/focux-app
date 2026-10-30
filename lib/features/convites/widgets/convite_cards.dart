import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';

/// Sem convite: o que acontece, em dois passos.
class ConvitePassos extends StatelessWidget {
  const ConvitePassos({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.conviteTitulo,
          style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
        ),
        const SizedBox(height: TokensStrip.s3),
        Text(s.convitePasso1, style: FocuxHubTypography.body(color: chrome.ink)),
        const SizedBox(height: TokensStrip.s1),
        Text(s.convitePasso2, style: FocuxHubTypography.body(color: chrome.ink)),
        const SizedBox(height: TokensStrip.s2),
        Text(
          s.conviteRegra,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
      ],
    );
  }
}

/// Link pronto: mostra a mensagem que vai para o aluno.
class ConviteLinkCard extends StatelessWidget {
  const ConviteLinkCard({
    super.key,
    required this.mensagem,
    required this.validade,
    required this.onWhatsapp,
    required this.onCopiar,
    this.email,
  });

  final String mensagem;
  final String validade;
  final String? email;
  final VoidCallback onWhatsapp;
  final VoidCallback onCopiar;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(
        context,
        accent: Theme.of(context).colorScheme.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.conviteProntoTitulo,
            style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(
            _detalhe(s, validade, email),
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s3),
          Text(mensagem, style: FocuxHubTypography.body(color: chrome.ink)),
          const SizedBox(height: TokensStrip.s3),
          FxLiquidPrimaryButton(
            label: s.conviteEnviarWhatsapp,
            onPressed: onWhatsapp,
          ),
          const SizedBox(height: TokensStrip.s2),
          FxTonalButton(
            label: s.conviteCopiar,
            expanded: true,
            onPressed: onCopiar,
          ),
        ],
      ),
    );
  }
}

/// Convite vivo, mas o link só existe no momento em que é gerado.
class ConviteAtivoCard extends StatelessWidget {
  const ConviteAtivoCard({super.key, required this.validade, this.email});

  final String validade;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    return Container(
      padding: const EdgeInsets.all(TokensStrip.s3),
      decoration: fxListCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.conviteAtivoTitulo,
            style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
          ),
          const SizedBox(height: TokensStrip.s1),
          Text(
            _detalhe(s, validade, email),
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
          const SizedBox(height: TokensStrip.s2),
          Text(
            s.conviteAtivoTexto,
            style: FocuxHubTypography.body(color: chrome.ink),
          ),
        ],
      ),
    );
  }
}

String _detalhe(S s, String validade, String? email) {
  final e = email?.trim() ?? '';
  final vale = s.conviteValePor(validade);
  return e.isEmpty ? vale : '$vale · ${s.conviteSoPara(e)}';
}

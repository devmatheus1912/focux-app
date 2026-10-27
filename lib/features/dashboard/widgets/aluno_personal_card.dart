import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../core/widgets/fx_tonal_button.dart';
import '../../../l10n/app_localizations.dart';

/// Assinatura do personal na Home do aluno: logo, nome, slogan e um botão
/// para conversar. Sem slogan, só logo e nome.
class AlunoPersonalCard extends StatelessWidget {
  const AlunoPersonalCard({
    super.key,
    required this.nome,
    required this.onConversar,
    this.logoUrl,
    this.slogan,
  });

  final String nome;
  final String? logoUrl;
  final String? slogan;
  final VoidCallback onConversar;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nomeLimpo = nome.trim();
    if (nomeLimpo.isEmpty) return const SizedBox.shrink();
    final logo = logoUrl?.trim() ?? '';
    final frase = slogan?.trim() ?? '';

    return Semantics(
      container: true,
      label: s.alunoPersonalCardSemantica(nomeLimpo),
      child: FxStripCard(
        glowStrength: 0.04,
        padding: const EdgeInsets.all(TokensStrip.s3),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: BrandPalette.soft(primary, dark: isDark),
              backgroundImage:
                  logo.isEmpty
                      ? null
                      : fxCachedNetworkImageProvider(logo, maxWidth: 96),
              child:
                  logo.isEmpty
                      ? Text(
                        nomeLimpo[0].toUpperCase(),
                        style: FocuxHubTypography.cardTitle(color: primary),
                      )
                      : null,
            ),
            const SizedBox(width: TokensStrip.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.alunoPersonalCardEyebrow,
                    style: FocuxHubTypography.eyebrow(
                      context,
                      color: chrome.mute,
                    ),
                  ),
                  Text(
                    nomeLimpo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                  if (frase.isNotEmpty)
                    Text(
                      frase,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                ],
              ),
            ),
            const SizedBox(width: TokensStrip.s2),
            FxTonalButton(
              label: s.alunoPersonalCardConversar,
              icon: Icons.chat_bubble_outline_rounded,
              compact: true,
              onPressed: onConversar,
            ),
          ],
        ),
      ),
    );
  }
}

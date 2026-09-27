import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/aluno_home_texts.dart';

/// Saudação + linha do personal (logo 24 px); toque abre o chat.
class AlunoHomeHeader extends StatelessWidget {
  const AlunoHomeHeader({
    super.key,
    required this.alunoNome,
    required this.nomePersonal,
    required this.onOpenChat,
    this.logoUrl,
  });

  final String alunoNome;
  final String nomePersonal;
  final String? logoUrl;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primeiroNome = alunoPrimeiroNome(alunoNome);
    final personal = nomePersonal.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            primeiroNome.isEmpty
                ? s.alunoHomeSaudacaoSemNome
                : s.alunoHomeSaudacao(primeiroNome),
            style: FocuxHubTypography.sectionTitle(context, color: chrome.ink),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (personal.isNotEmpty)
          _PersonalLine(nome: personal, logoUrl: logoUrl, onTap: onOpenChat),
      ],
    );
  }
}

class _PersonalLine extends StatelessWidget {
  const _PersonalLine({
    required this.nome,
    required this.logoUrl,
    required this.onTap,
  });

  final String nome;
  final String? logoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final mute = ShellChrome.of(context).mute;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logo = logoUrl?.trim() ?? '';

    return Semantics(
      button: true,
      label: s.alunoHomeAbrirConversa(nome),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TokensStrip.rMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: BrandPalette.soft(primary, dark: isDark),
                backgroundImage:
                    logo.isEmpty
                        ? null
                        : fxCachedNetworkImageProvider(logo, maxWidth: 48),
                child:
                    logo.isEmpty
                        ? Text(
                          nome[0].toUpperCase(),
                          style: FocuxHubTypography.chip(primary),
                        )
                        : null,
              ),
              const SizedBox(width: TokensStrip.s2),
              Flexible(
                child: Text(
                  s.alunoHomeSeuPersonal(nome),
                  style: FocuxHubTypography.bodyMuted(
                    color: mute,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: mute),
            ],
          ),
        ),
      ),
    );
  }
}

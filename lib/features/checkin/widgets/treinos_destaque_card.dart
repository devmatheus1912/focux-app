import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_action_chip.dart';
import '../../../core/widgets/fx_motion.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../../../l10n/app_localizations.dart';
import '../utils/treinos_hub_texts.dart';
import '../utils/treinos_hub_view.dart';

/// Única superfície com `emphasize` na aba Treinos. O corpo abre a prévia (ou o
/// detalhe do feito hoje); o botão inicia ou continua direto.
class TreinosDestaqueCard extends StatelessWidget {
  const TreinosDestaqueCard({
    super.key,
    required this.destaque,
    required this.hoje,
    required this.onAction,
    this.onOpen,
  });

  final TreinosDestaque destaque;
  final DateTime hoje;
  final VoidCallback onAction;

  /// Null em preparação: não há prévia a abrir.
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final texto = treinosDestaqueTexto(s, destaque, hoje: hoje);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final concluido = destaque.tipo == TreinosDestaqueTipo.concluidoHoje;

    final corpo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (concluido) ...[
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: EagleTokens.good,
              ),
              const SizedBox(width: TokensStrip.s1),
            ],
            Flexible(
              child: Text(
                texto.eyebrow,
                style: FocuxHubTypography.eyebrow(context, color: chrome.mute),
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensStrip.s2),
        Text(
          texto.titulo,
          style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: TokensStrip.s2),
        Text(
          texto.detalhe,
          style: FocuxHubTypography.bodyMuted(color: chrome.mute),
        ),
        if (texto.progresso case final p?) ...[
          const SizedBox(height: TokensStrip.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 4,
              backgroundColor: chrome.line,
              valueColor: AlwaysStoppedAnimation(primary),
            ),
          ),
        ],
        if (texto.prazo case final prazo?) ...[
          const SizedBox(height: TokensStrip.s1),
          Text(prazo, style: FocuxHubTypography.bodyMuted(color: chrome.mute)),
        ],
      ],
    );

    return FxStripCard(
      emphasize: true,
      glowStrength: 0.08,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: onOpen != null,
            label: treinosDestaqueSemantics(texto),
            excludeSemantics: true,
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              child: corpo,
            ),
          ),
          if (texto.cta case final cta?) ...[
            const SizedBox(height: TokensStrip.s3),
            if (concluido)
              Align(
                alignment: Alignment.centerLeft,
                child: FxActionChip(
                  label: cta,
                  accent: primary,
                  isDark: isDark,
                  onPressed: onAction,
                  maxLines: 2,
                ),
              )
            else
              FxLiquidPrimaryButton(
                label: cta,
                icon: Icons.play_arrow_rounded,
                onPressed: onAction,
              ),
          ],
        ],
      ),
    );
  }
}

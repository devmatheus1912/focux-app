import 'package:flutter/material.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_cached_network_image.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../../l10n/app_localizations.dart';
import '../models/treino_previa.dart';
import '../utils/treino_previa_view.dart';

class TreinoPreviaCabecalho extends StatelessWidget {
  const TreinoPreviaCabecalho({super.key, required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Text(
    texto,
    style: FocuxHubTypography.bodyMuted(
      color: ShellChrome.of(context).mute,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// Exercício prescrito: número, nome, prescrição, miniatura e a observação do
/// personal inteira (é a orientação dele, não se corta).
class TreinoPreviaExercicioTile extends StatelessWidget {
  const TreinoPreviaExercicioTile({
    super.key,
    required this.numero,
    required this.exercicio,
  });

  final int numero;
  final TreinoPreviaExercicio exercicio;

  static const double miniatura = 48;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final prescricao = treinoPreviaPrescricao(s, exercicio);
    final obs = exercicio.observacoes;
    final imagem = exercicio.imagemUrl;

    return Semantics(
      container: true,
      label: [
        '$numero. ${exercicio.exercicioNome}',
        if (prescricao.isNotEmpty) prescricao,
        if (exercicio.temVideo) s.treinoPreviaComVideo,
        if (obs != null) obs,
      ].join(', '),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(TokensStrip.s3),
        decoration: fxListCardDecoration(context, accent: primary),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: BrandPalette.soft(primary, dark: isDark),
                shape: BoxShape.circle,
              ),
              child: Text('$numero', style: FocuxHubTypography.chip(primary)),
            ),
            const SizedBox(width: TokensStrip.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercicio.exercicioNome,
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (prescricao.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      prescricao,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  ],
                  if (exercicio.temVideo) ...[
                    const SizedBox(height: TokensStrip.s1),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_outline_rounded,
                          size: 16,
                          color: primary,
                        ),
                        const SizedBox(width: TokensStrip.s1),
                        Text(
                          s.treinoPreviaComVideo,
                          style: FocuxHubTypography.bodyMuted(
                            color: chrome.mute,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (obs != null) ...[
                    const SizedBox(height: TokensStrip.s2),
                    Text(
                      obs,
                      style: FocuxHubTypography.bodyMuted(
                        color: chrome.ink,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (imagem != null) ...[
              const SizedBox(width: TokensStrip.s3),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FxCachedNetworkImage(
                  imageUrl: imagem,
                  width: miniatura,
                  height: miniatura,
                  errorBuilder:
                      (_, __, ___) =>
                          const SizedBox(width: miniatura, height: miniatura),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

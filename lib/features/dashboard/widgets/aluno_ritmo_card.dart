import 'package:flutter/material.dart';

import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_strip_card.dart';
import '../utils/aluno_ritmo_linha.dart';

/// Linha quieta do ritmo. O card de treino continua sendo o único com ênfase.
class AlunoRitmoCard extends StatelessWidget {
  const AlunoRitmoCard({super.key, required this.linha});

  final AlunoRitmoLinha linha;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final frase = linha.frase;
    final leitura = [
      linha.sobrancelha,
      linha.titulo,
      if (frase != null) frase,
    ].join('. ');

    return Semantics(
      container: true,
      label: leitura,
      excludeSemantics: true,
      child: FxStripCard(
        glowStrength: 0.08,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              linha.sobrancelha,
              style: FocuxHubTypography.eyebrow(context, color: chrome.mute),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: TokensStrip.s2),
            Text(
              linha.titulo,
              style: FocuxHubTypography.pageTitle(context, color: chrome.ink),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (frase != null) ...[
              const SizedBox(height: TokensStrip.s1),
              Text(
                frase,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../models/trilha.dart';
import '../utils/trilhas_display.dart';

/// Barra em segmentos, um por etapa: feitas na cor da marca, a atual com
/// contorno, as seguintes vazias. Mesma peça para personal e aluno.
class TrilhaSegmentos extends StatelessWidget {
  const TrilhaSegmentos({super.key, required this.trilha});

  final TrilhaModel trilha;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final etapas = trilhaEtapas(trilha);
    final atual = trilhaEtapaAtual(trilha);
    return Semantics(
      label: trilhaResumoLinha(trilha),
      excludeSemantics: true,
      child: Row(
        children: [
          for (final (i, e) in etapas.indexed) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: e.concluido ? primary : chrome.line.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                  border:
                      e.id == atual?.id
                          ? Border.all(color: primary, width: 1.5)
                          : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cartão da trilha na lista (personal e aluno): nome, prazo, segmentos e
/// "Etapa 2 de 5 · Próxima: …". Tocar abre o detalhe.
class TrilhaCartao extends StatelessWidget {
  const TrilhaCartao({super.key, required this.trilha, required this.onTap});

  final TrilhaModel trilha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final hoje = DateTime.now();
    final prazo = trilhaPrazoLabel(trilha, hoje);
    final vencido = trilhaPrazoVencido(trilha, hoje);
    final aviso = chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensStrip.s2),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          onTap: onTap,
          child: Ink(
            decoration: fxListCardDecoration(context),
            padding: const EdgeInsets.all(TokensStrip.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        trilha.titulo,
                        style: FocuxHubTypography.cardTitle(color: chrome.ink),
                      ),
                    ),
                    if (prazo != null) ...[
                      const SizedBox(width: TokensStrip.s2),
                      Text(
                        prazo,
                        style: FocuxHubTypography.bodyMuted(
                          color: vencido ? aviso : chrome.mute,
                          fontWeight: vencido ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: TokensStrip.s2),
                TrilhaSegmentos(trilha: trilha),
                const SizedBox(height: TokensStrip.s2),
                Text(
                  trilhaResumoLinha(trilha),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

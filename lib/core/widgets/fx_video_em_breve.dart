import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

/// Aviso no lugar da demonstração de um exercício oficial ainda sem vídeo.
/// Não é botão e não abre nada.
class FxVideoEmBreve extends StatelessWidget {
  const FxVideoEmBreve({super.key, this.apoio, this.semCartao = false})
    : linha = false;

  /// Versão em uma linha, para lista e espaço apertado.
  const FxVideoEmBreve.linha({super.key})
    : apoio = null,
      semCartao = false,
      linha = true;

  final String? apoio;

  /// Quando o palco em volta já tem fundo.
  final bool semCartao;
  final bool linha;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    if (linha) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_outlined, size: 16, color: primary),
          const SizedBox(width: TokensStrip.s1),
          Text(
            s.videoEmBreve,
            style: FocuxHubTypography.bodyMuted(color: chrome.mute),
          ),
        ],
      );
    }
    final conteudo = Center(
      child: Padding(
        padding: const EdgeInsets.all(TokensStrip.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: chrome.isDark ? 0.22 : 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.videocam_outlined, color: primary, size: 26),
            ),
            const SizedBox(height: TokensStrip.s2),
            Text(
              s.videoEmBreve,
              textAlign: TextAlign.center,
              style: FocuxHubTypography.cardTitle(color: chrome.ink),
            ),
            if (apoio != null) ...[
              const SizedBox(height: TokensStrip.s1),
              Text(
                apoio!,
                textAlign: TextAlign.center,
                style: FocuxHubTypography.bodyMuted(color: chrome.mute),
              ),
            ],
          ],
        ),
      ),
    );
    return Semantics(
      label: [s.videoEmBreve, if (apoio != null) apoio!].join('. '),
      excludeSemantics: true,
      child:
          semCartao
              ? conteudo
              : Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 180),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: chrome.isDark ? 0.14 : 0.06),
                  borderRadius: BorderRadius.circular(TokensStrip.rCard),
                ),
                child: conteudo,
              ),
    );
  }
}

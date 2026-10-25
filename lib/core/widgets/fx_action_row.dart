import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_action_chip.dart';

/// Uma pessoa, um motivo e um verbo ("Chamar", "Cobrar", "Renovar").
/// A linha toda toca; o verbo à direita só mostra o que vai acontecer.
class FxActionRow extends StatelessWidget {
  const FxActionRow({
    super.key,
    required this.titulo,
    required this.motivo,
    required this.verbo,
    required this.onTap,
    this.leading,
  });

  final String titulo;
  final String motivo;

  /// Rótulo do verbo. Nunca o nome da pessoa.
  final String verbo;
  final VoidCallback onTap;
  final IconData? leading;

  static const double alturaMin = 56;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final bg = FxActionChip.solidBackground(chrome.brand, isDark: chrome.isDark);
    final fg = FxActionChip.solidForeground(isDark: chrome.isDark);

    return Semantics(
      button: true,
      label: '$verbo, $titulo, $motivo',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          child: Ink(
            decoration: BoxDecoration(
              color: chrome.cardFill,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              border: Border.all(color: chrome.lineStrong),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s3,
              vertical: TokensStrip.s2,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: alturaMin - 16),
              child: Row(
                children: [
                  if (leading != null) ...[
                    Icon(leading, color: chrome.mute),
                    const SizedBox(width: TokensStrip.s3),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.cardTitle(color: chrome.ink),
                        ),
                        Text(
                          motivo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: FocuxHubTypography.cardSubtitle(color: chrome.mute),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TokensStrip.s2),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TokensStrip.s3,
                        vertical: TokensStrip.s2,
                      ),
                      child: Text(verbo, style: FocuxHubTypography.chip(fg)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

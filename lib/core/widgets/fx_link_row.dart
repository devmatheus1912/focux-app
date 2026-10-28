import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

/// Linha inteira tocável para "ver mais" / "abrir": fundo de cartão, ícone
/// opcional, rótulo e seta. É a forma padrão de navegação que antes era um
/// texto solto ("Ver todos os 5 sinais"). Alvo de 56, sem competir com o
/// botão principal da tela.
class FxLinkRow extends StatelessWidget {
  const FxLinkRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.detalhe,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  /// Texto curto à direita, antes da seta ("12").
  final String? detalhe;

  static const double alturaMin = 56;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: detalhe == null ? label : '$label, $detalhe',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TokensStrip.rCard),
          onTap:
              enabled
                  ? () {
                    HapticFeedback.selectionClick();
                    onTap!();
                  }
                  : null,
          child: Ink(
            decoration: BoxDecoration(
              color: chrome.cardFill,
              borderRadius: BorderRadius.circular(TokensStrip.rCard),
              border: Border.all(color: chrome.lineStrong),
            ),
            padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s3),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: alturaMin),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: chrome.brand, size: 20),
                    const SizedBox(width: TokensStrip.s3),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FocuxHubTypography.cardTitle(color: chrome.ink),
                    ),
                  ),
                  if (detalhe != null) ...[
                    const SizedBox(width: TokensStrip.s2),
                    Text(
                      detalhe!,
                      style: FocuxHubTypography.bodyMuted(color: chrome.mute),
                    ),
                  ],
                  const SizedBox(width: TokensStrip.s1),
                  Icon(Icons.chevron_right_rounded, color: chrome.mute),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

enum FxPillTone { neutral, accent, success, warning, danger }

/// Selo de estado ("Pronto", "Em montagem", "Vence em 7 dias").
/// O texto sempre vem junto da cor; `success` ganha um check por padrão
/// para o significado não depender só de cor.
class FxStatusPill extends StatelessWidget {
  const FxStatusPill({
    super.key,
    required this.label,
    this.tone = FxPillTone.neutral,
    this.icon,
  });

  final String label;
  final FxPillTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final scheme = Theme.of(context).colorScheme;
    final (Color cor, Color fundo) = switch (tone) {
      FxPillTone.neutral => (chrome.mute, chrome.line.withValues(alpha: 0.5)),
      FxPillTone.accent || FxPillTone.success => (
        chrome.brand,
        chrome.brand.withValues(alpha: chrome.isDark ? 0.22 : 0.10),
      ),
      FxPillTone.warning => (
        chrome.isDark ? EagleTokens.warnDark : EagleTokens.warn,
        chrome.isDark ? EagleTokens.warnSurfaceDark : EagleTokens.warnSoft,
      ),
      FxPillTone.danger => (
        scheme.error,
        scheme.error.withValues(alpha: chrome.isDark ? 0.22 : 0.10),
      ),
    };
    final simbolo = icon ?? (tone == FxPillTone.success ? Icons.check_rounded : null);

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fundo,
          borderRadius: BorderRadius.circular(TokensStrip.rPill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TokensStrip.s2 + 2,
            vertical: TokensStrip.s1,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (simbolo != null) ...[
                Icon(simbolo, size: 14, color: cor),
                const SizedBox(width: TokensStrip.s1),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FocuxHubTypography.chip(cor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

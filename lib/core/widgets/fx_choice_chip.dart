import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

/// Chip de escolha única (dias por semana, A/B/C/D, Semanas/Sessões).
/// Largura intrínseca: nunca estica numa `Wrap` ou `Row`. A cápsula é menor
/// que o alvo de toque, que segue com 48 dp.
class FxChoiceChip extends StatelessWidget {
  const FxChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  static const double alvoMin = 48;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final enabled = onTap != null;
    final foreground = !enabled
        ? chrome.mute.withValues(alpha: 0.5)
        : selected
        ? chrome.brand
        : chrome.ink;

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: alvoMin,
          minWidth: alvoMin,
        ),
        child: Center(
          widthFactor: 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled
                  ? () {
                      HapticFeedback.selectionClick();
                      onTap!();
                    }
                  : null,
              borderRadius: BorderRadius.circular(TokensStrip.rPill),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensStrip.s4,
                  vertical: TokensStrip.s2,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? chrome.brand.withValues(alpha: chrome.isDark ? 0.22 : 0.10)
                      : chrome.cardFill,
                  borderRadius: BorderRadius.circular(TokensStrip.rPill),
                  border: Border.all(
                    color: selected ? chrome.brand : chrome.lineStrong,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: FocuxHubTypography.cardTitle(color: foreground),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

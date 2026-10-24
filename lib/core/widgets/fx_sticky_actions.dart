import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_motion.dart';

/// Barra de ações fixa embaixo: um botão principal e um secundário em
/// contorno. Fica fora da lista (numa `Column`), então a lista termina
/// acima dela e nada fica escondido. Respeita a área segura.
class FxStickyActions extends StatelessWidget {
  const FxStickyActions({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.loading = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String primaryLabel;
  final VoidCallback? onPrimary;
  final bool loading;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: chrome.sheetFill,
        border: Border(top: BorderSide(color: chrome.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(TokensStrip.s3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FxLiquidPrimaryButton(
                label: primaryLabel,
                loading: loading,
                onPressed: loading ? null : onPrimary,
              ),
              if (secondaryLabel != null) ...[
                const SizedBox(height: TokensStrip.s2),
                OutlinedButton(
                  onPressed: loading ? null : onSecondary,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: chrome.ink,
                    side: BorderSide(color: chrome.lineStrong),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    secondaryLabel!,
                    style: FocuxHubTypography.cardTitle(color: chrome.ink),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

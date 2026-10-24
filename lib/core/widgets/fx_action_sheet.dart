import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_home_sheet.dart';

class FxActionSheetItem<T> {
  const FxActionSheetItem({
    required this.value,
    required this.label,
    required this.icon,
    this.destructive = false,
  });

  final T value;
  final String label;
  final IconData icon;
  final bool destructive;
}

/// Menu "…" com ações nomeadas. Devolve o valor escolhido ou null.
Future<T?> showFxActionSheet<T>(
  BuildContext context, {
  required List<FxActionSheetItem<T>> itens,
  String? title,
}) {
  return showFxHomeSheet<T>(
    context,
    builder: (sheetContext) {
      final chrome = ShellChrome.of(sheetContext);
      final erro = Theme.of(sheetContext).colorScheme.error;
      return DecoratedBox(
        decoration: BoxDecoration(
          color: chrome.sheetFill,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(TokensStrip.r2xl),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(TokensStrip.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensStrip.s2),
                    child: Text(
                      title,
                      style: FocuxHubTypography.sectionTitle(
                        sheetContext,
                        color: chrome.ink,
                      ),
                    ),
                  ),
                for (final item in itens)
                  Semantics(
                    button: true,
                    label: item.label,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(item.value),
                      borderRadius: BorderRadius.circular(TokensStrip.rCard),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: item.destructive ? erro : chrome.brand,
                            ),
                            const SizedBox(width: TokensStrip.s3),
                            Expanded(
                              child: Text(
                                item.label,
                                style: FocuxHubTypography.cardTitle(
                                  color: item.destructive ? erro : chrome.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

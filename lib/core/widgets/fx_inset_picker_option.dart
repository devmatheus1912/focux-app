import 'package:flutter/material.dart';

import '../theme/fx_settings_layout.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

/// Linha de opção única dentro de [FxSettingsGroup] — paridade picker Perfil/iOS.
class FxInsetPickerOption extends StatelessWidget {
  const FxInsetPickerOption({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.showDivider = true,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = selected ? accent : chrome.ink;
    final line = chrome.line;

    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$label, selecionado' : label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FxSettingsLayout.rowMinHeight,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color:
                  selected ? accent.withValues(alpha: 0.08) : Colors.transparent,
              border:
                  showDivider
                      ? Border(
                        bottom: BorderSide(
                          color: line,
                          width: FxSettingsLayout.dividerThickness,
                        ),
                      )
                      : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: TokensStrip.s3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: FxSettingsLayout.rowLabel(color: ink).copyWith(
                        fontWeight: selected ? FontWeight.w800 : null,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_rounded,
                      color: accent,
                      size: FxSettingsLayout.iconSize,
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

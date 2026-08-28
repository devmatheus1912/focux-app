import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_palette.dart';
import '../theme/fx_settings_layout.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_shell_scaffold.dart';

/// Picker inset dentro de [FxSettingsGroup] — ícone alinhado a
/// [FxInputDeco.insetGrouped] / [AlunoInsetFormField].
class FxInsetPickerRow extends StatelessWidget {
  const FxInsetPickerRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.iconColor,
    this.showDivider = true,
    this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? iconColor;
  final bool showDivider;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final mute = chrome.mute;
    final primary = Theme.of(context).colorScheme.primary;
    final soft = iconColor ?? BrandPalette.softened(primary);
    final ink = fxScreenInk(context);
    final spoken = semanticsLabel ?? '$label. $value';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: spoken,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: FxSettingsLayout.insetPrefixWidth,
                  child: Align(
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      size: FxSettingsLayout.iconSize,
                      color: soft,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: TokensStrip.s3,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: FxSettingsLayout.rowLabel(color: ink),
                          ),
                        ),
                        if (value.isNotEmpty) ...[
                          const SizedBox(width: TokensStrip.s2),
                          Flexible(
                            child: Text(
                              value,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: FxSettingsLayout.rowValue(color: mute),
                            ),
                          ),
                        ],
                        const SizedBox(width: TokensStrip.s1),
                        Icon(
                          Icons.unfold_more,
                          size: FxSettingsLayout.chevronSize,
                          color: mute,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: FxSettingsLayout.dividerThickness,
            color: chrome.line,
          ),
      ],
    );
  }
}

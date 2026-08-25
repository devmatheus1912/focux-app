import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/brand_palette.dart';
import '../theme/design_tokens.dart';
import '../theme/fx_settings_layout.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_icon.dart';

/// Linha de ajustes inset — anatomia ChatGPT/iOS, pele da Home.
class FxSettingsTile extends StatelessWidget {
  const FxSettingsTile({
    super.key,
    this.icon,
    this.fxIcon,
    required this.label,
    required this.value,
    required this.onTap,
    this.mute,
    this.line,
    this.accent,
    this.danger = false,
    this.showDivider = true,
    this.locked = false,
    this.highlight = false,
    this.picker = false,
    this.numeric = false,
    this.onLongPress,
    this.upgradeTierLabel,
  }) : assert(icon != null || fxIcon != null);

  final IconData? icon;
  final String? fxIcon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Color? mute;
  final Color? line;
  final Color? accent;
  final bool danger;
  final bool showDivider;
  final bool locked;
  final bool highlight;
  final bool picker;
  final bool numeric;
  final String? upgradeTierLabel;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final mute = this.mute ?? chrome.mute;
    final line = this.line ?? chrome.line;
    final brand =
        accent ??
        BrandPalette.softened(Theme.of(context).colorScheme.primary);
    final ink =
        danger
            ? EagleTokens.bad
            : highlight
            ? brand
            : chrome.ink;
    final inkMuted = locked ? ink.withValues(alpha: 0.55) : ink;
    final iconColor =
        danger
            ? EagleTokens.bad
            : locked
            ? brand.withValues(alpha: 0.55)
            : brand;
    final a11y =
        danger
            ? '$label. Ação destrutiva'
            : locked
            ? '$label trancado. Plano ${upgradeTierLabel ?? 'upgrade'}'
            : (value.isEmpty ? label : '$label. $value');

    return Semantics(
      button: true,
      label: a11y,
      hint: danger ? 'Confirmação será solicitada' : null,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        onLongPress:
            onLongPress == null
                ? null
                : () {
                  HapticFeedback.selectionClick();
                  onLongPress!();
                },
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: FxSettingsLayout.rowMinHeight,
          ),
          child: Row(
            children: [
              fxIcon != null
                  ? FxIcon(
                    name: fxIcon!,
                    size: FxSettingsLayout.iconSize,
                    color: iconColor,
                  )
                  : Icon(
                    icon!,
                    size: FxSettingsLayout.iconSize,
                    color: iconColor,
                  ),
              const SizedBox(width: FxSettingsLayout.iconGap),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
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
                      vertical: TokensStrip.s3,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: FxSettingsLayout.rowLabel(color: inkMuted),
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
                              style:
                                  numeric
                                      ? FxSettingsLayout.rowMetric(
                                        color: danger ? ink : mute,
                                      )
                                      : FxSettingsLayout.rowValue(
                                        color: danger ? ink : mute,
                                      ),
                            ),
                          ),
                        ],
                        if (!danger) ...[
                          const SizedBox(width: TokensStrip.s1),
                          Icon(
                            locked
                                ? Icons.lock_outline_rounded
                                : picker
                                ? Icons.unfold_more
                                : Icons.chevron_right,
                            size: FxSettingsLayout.chevronSize,
                            color: mute,
                          ),
                        ],
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
  }
}

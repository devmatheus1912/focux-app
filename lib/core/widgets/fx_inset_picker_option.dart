import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/fx_settings_layout.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';

/// Especificação de uma linha para [FxInsetPickerOption.list].
class FxInsetPickerOptionSpec {
  const FxInsetPickerOptionSpec({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
}

/// Linha de opção única dentro de [FxSettingsGroup] — paridade picker Perfil/iOS.
///
/// Use com [FxSettingsGroup.edgeToEdgeRows] para o destaque de seleção ir
/// de borda a borda do card.
class FxInsetPickerOption extends StatelessWidget {
  const FxInsetPickerOption({
    super.key,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.showDivider = true,
    this.isFirst = false,
    this.isLast = false,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool showDivider;
  final bool isFirst;
  final bool isLast;

  /// Monta linhas com [isFirst]/[isLast] corretos para listas de picker.
  static List<Widget> list({
    required List<FxInsetPickerOptionSpec> items,
    required Color accent,
  }) {
    return [
      for (var i = 0; i < items.length; i++)
        FxInsetPickerOption(
          label: items[i].label,
          subtitle: items[i].subtitle,
          icon: items[i].icon,
          selected: items[i].selected,
          accent: accent,
          isFirst: i == 0,
          isLast: i == items.length - 1,
          showDivider: i < items.length - 1,
          onTap: items[i].onTap,
        ),
    ];
  }

  BorderRadius? _selectionRadius() {
    if (!selected) return null;
    final r = Radius.circular(FxSettingsLayout.groupRadius - 1);
    return BorderRadius.vertical(
      top: isFirst ? r : Radius.zero,
      bottom: isLast && !showDivider ? r : Radius.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final ink = selected ? accent : chrome.ink;
    final line = chrome.line;
    final fill =
        selected
            ? accent.withValues(alpha: chrome.isDark ? 0.16 : 0.10)
            : Colors.transparent;
    final detail = subtitle?.trim();
    final hasSubtitle = detail != null && detail.isNotEmpty;
    final spoken = hasSubtitle ? '$label. $detail' : label;

    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$spoken, selecionado' : spoken,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Ink(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: _selectionRadius(),
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FxSettingsLayout.rowMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: FxSettingsLayout.groupPadH,
                  vertical: TokensStrip.s3,
                ),
                child: Row(
                  children: [
                    if (icon != null) ...[
                      Icon(
                        icon,
                        size: FxSettingsLayout.iconSize,
                        color: accent,
                      ),
                      const SizedBox(width: FxSettingsLayout.iconGap),
                    ],
                    Expanded(
                      child:
                          hasSubtitle
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: FxSettingsLayout.rowLabel(
                                      color: ink,
                                    ).copyWith(
                                      fontWeight:
                                          selected ? FontWeight.w800 : null,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: FxSettingsLayout.captionAfterHeader,
                                  ),
                                  Text(
                                    detail,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: FxSettingsLayout.subhead(
                                      color: chrome.mute,
                                    ),
                                  ),
                                ],
                              )
                              : Text(
                                label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: FxSettingsLayout.rowLabel(
                                  color: ink,
                                ).copyWith(
                                  fontWeight:
                                      selected ? FontWeight.w800 : null,
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
      ),
    );
  }
}

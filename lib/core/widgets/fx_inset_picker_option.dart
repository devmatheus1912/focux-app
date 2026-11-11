import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/fx_settings_layout.dart';
import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import '../theme/fx_icons.dart';

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
/// A escolhida ganha um fundo recuado e arredondado (não uma faixa de borda a
/// borda, que cortava o cartão no meio da lista); o toque vale a linha toda.
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
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final bool showDivider;

  /// Monta as linhas de uma lista de picker (divisor entre elas).
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
          showDivider: i < items.length - 1,
          onTap: items[i].onTap,
        ),
    ];
  }

  /// Recuo do fundo da escolhida em relação às bordas da linha.
  static const recuoSelecao = 4.0;

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
              padding: const EdgeInsets.all(recuoSelecao),
              child: DecoratedBox(
                key:
                    selected ? const ValueKey('fx-inset-picker-selecao') : null,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(TokensStrip.rSm),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: FxSettingsLayout.rowMinHeight - 2 * recuoSelecao,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FxSettingsLayout.groupPadH - recuoSelecao,
                      vertical: TokensStrip.s3 - recuoSelecao,
                    ),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Icon(
                            icon,
                            size: FxSettingsLayout.iconSize,
                            color: selected ? accent : chrome.mute,
                          ),
                          const SizedBox(width: FxSettingsLayout.iconGap),
                        ],
                        Expanded(
                          child:
                              hasSubtitle
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: FxSettingsLayout.rowLabel(
                                          color: ink,
                                        ).copyWith(
                                          fontWeight:
                                              selected ? FontWeight.w700 : null,
                                        ),
                                      ),
                                      const SizedBox(
                                        height:
                                            FxSettingsLayout.captionAfterHeader,
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
                                          selected ? FontWeight.w700 : null,
                                    ),
                                  ),
                        ),
                        if (selected)
                          Icon(
                            FxIcons.check,
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
        ),
      ),
    );
  }
}

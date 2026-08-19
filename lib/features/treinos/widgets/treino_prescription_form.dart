import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';
import '../../dashboard/utils/dashboard_readability.dart';
import '../constants/treinos_layout.dart';

InputDecoration treinoPrescriptionDecoration(
  BuildContext context, {
  required bool isDark,
  String? hint,
}) {
  final chrome = ShellChrome.forDark(isDark);
  final primary = Theme.of(context).colorScheme.primary;
  final fill = isDark ? EagleTokens.darkCardHi : const Color(0xFFEEF2F5);
  final radius = BorderRadius.circular(TokensStrip.rXl);

  return InputDecoration(
    hintText: hint,
    isDense: false,
    filled: true,
    fillColor: fill,
    hintStyle: FocuxHubTypography.bodyMuted(
      color: dashboardReadableCaption(
        context,
        isDark: isDark,
      ).withValues(alpha: 0.62),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: FxInputDeco.outlineBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: chrome.lineStrong),
    ),
    enabledBorder: FxInputDeco.outlineBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: chrome.lineStrong),
    ),
    focusedBorder: FxInputDeco.outlineBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: primary, width: 1.6),
    ),
  );
}

class TreinoPrescriptionField extends StatelessWidget {
  const TreinoPrescriptionField({
    super.key,
    required this.label,
    required this.isDark,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final bool isDark;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final caption = dashboardReadableCaption(context, isDark: isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FocuxHubTypography.bodyMuted(
            color: caption,
            fontWeight: FontWeight.w800,
          ).copyWith(fontSize: 12, letterSpacing: 0.1),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          minLines: minLines,
          maxLines: maxLines,
          style: FocuxHubTypography.body(
            color: chrome.ink,
          ).copyWith(fontWeight: FontWeight.w700),
          decoration: treinoPrescriptionDecoration(
            context,
            isDark: isDark,
            hint: hint,
          ),
        ),
      ],
    );
  }
}

class TreinoTipoSeriePicker extends StatelessWidget {
  const TreinoTipoSeriePicker({
    super.key,
    required this.value,
    required this.isDark,
    required this.enabled,
    required this.onChanged,
  });

  final String value;
  final bool isDark;
  final bool enabled;
  final ValueChanged<String> onChanged;

  static const options = <(String, String)>[
    ('NORMAL', 'Normal'),
    ('SUPERSET', 'Superset'),
    ('DROPSET', 'Drop set'),
  ];

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.forDark(isDark);
    final primary = Theme.of(context).colorScheme.primary;
    final caption = dashboardReadableCaption(context, isDark: isDark);
    final fill = isDark ? EagleTokens.darkCardHi : const Color(0xFFEEF2F5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de série',
          style: FocuxHubTypography.bodyMuted(
            color: caption,
            fontWeight: FontWeight.w800,
          ).copyWith(fontSize: 12, letterSpacing: 0.1),
        ),
        SizedBox(height: TokensStrip.s2),
        DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(TokensStrip.rXl),
            border: Border.all(color: chrome.lineStrong),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                for (final option in options)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: value == option.$1,
                      label: 'Tipo de série: ${option.$2}',
                      child: Material(
                        color: fxTransparent,
                        child: InkWell(
                          onTap: enabled ? () => onChanged(option.$1) : null,
                          borderRadius: BorderRadius.circular(12),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: TreinosLayout.touchTarget,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                color:
                                    value == option.$1
                                        ? BrandPalette.soft(
                                          primary,
                                          dark: isDark,
                                        )
                                        : fxTransparent,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    value == option.$1
                                        ? Border.all(
                                          color: primary.withValues(
                                            alpha: 0.42,
                                          ),
                                        )
                                        : null,
                              ),
                              child: Center(
                                child: Text(
                                  option.$2,
                                  style: FocuxHubTypography.cardTitle(
                                    color:
                                        value == option.$1 ? primary : caption,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

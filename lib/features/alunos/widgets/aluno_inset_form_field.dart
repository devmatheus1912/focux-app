import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_shell_scaffold.dart';

/// Campo inset dentro de [FxSettingsGroup] — paridade Editar Perfil.
class AlunoInsetFormField extends StatelessWidget {
  const AlunoInsetFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.focusNode,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.showDivider = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final fieldHint = hint ?? label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: label,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            inputFormatters: inputFormatters,
            validator: validator,
            maxLines: maxLines,
            style: FxSettingsLayout.rowLabel(color: fxScreenInk(context)),
            decoration: FxInputDeco.insetGrouped(
              context,
              icon: icon,
              hint: fieldHint,
              iconColor: soft,
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

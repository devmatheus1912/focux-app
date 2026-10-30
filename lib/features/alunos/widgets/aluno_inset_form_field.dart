import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/brand_palette.dart';
import '../../../core/theme/fx_settings_layout.dart';
import '../../../core/theme/shell_chrome.dart';
import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';
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
    this.maxLength,
    this.showDivider = true,
    this.rotuloVisivel = false,
    this.obrigatorio = false,
    this.ajuda,
    this.rotuloFlutuante = false,
  });

  /// Rótulo pequeno acima do valor, dentro da linha: o campo cheio continua
  /// dizendo o que é.
  final bool rotuloFlutuante;

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
  final int? maxLength;
  final bool showDivider;

  /// Mostra o [label] acima do campo, com borda de campo, em vez de só o [hint]
  /// (que some ao digitar). Quem usa o campo em formulário longo liga.
  final bool rotuloVisivel;

  /// Com [rotuloVisivel]: marca "obrigatório" ou "opcional" ao lado do rótulo.
  final bool obrigatorio;

  /// Com [rotuloVisivel]: frase de ajuda embaixo do campo.
  final String? ajuda;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final soft = BrandPalette.softened(primary);
    final fieldHint = hint ?? label;

    if (rotuloVisivel) {
      return _comRotulo(context, chrome, soft, fieldHint);
    }

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
            maxLength: maxLength,
            textInputAction:
                maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
            onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
            style: FxSettingsLayout.rowLabel(color: fxScreenInk(context)),
            decoration: FxInputDeco.insetGrouped(
              context,
              icon: icon,
              hint: fieldHint,
              iconColor: soft,
            ).copyWith(
              // Contador só nos campos curtos (BE @Size ≤ 50).
              counterText: (maxLength != null && maxLength! <= 50) ? null : '',
              labelText: rotuloFlutuante ? label : null,
              floatingLabelBehavior: rotuloFlutuante
                  ? FloatingLabelBehavior.always
                  : null,
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

  Widget _comRotulo(
    BuildContext context,
    ShellPalette chrome,
    Color soft,
    String fieldHint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: TokensStrip.s2, bottom: TokensStrip.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: TokensStrip.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                label,
                style: FxSettingsLayout.subhead(
                  color: chrome.ink,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                obrigatorio ? 'obrigatório' : 'opcional',
                style: FxSettingsLayout.subhead(color: chrome.mute),
              ),
            ],
          ),
          const SizedBox(height: TokensStrip.s1),
          DecoratedBox(
            decoration: BoxDecoration(
              color: chrome.cardFill,
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              border: Border.all(color: chrome.lineStrong),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s3),
              child: Semantics(
                label: label,
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  inputFormatters: inputFormatters,
                  validator: validator,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  textInputAction: maxLines > 1
                      ? TextInputAction.newline
                      : TextInputAction.next,
                  onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
                  style: FxSettingsLayout.rowLabel(color: fxScreenInk(context)),
                  decoration: FxInputDeco.insetGrouped(
                    context,
                    icon: icon,
                    hint: fieldHint,
                    iconColor: soft,
                  ).copyWith(counterText: ''),
                ),
              ),
            ),
          ),
          if (ajuda != null) ...[
            const SizedBox(height: TokensStrip.s1),
            Text(
              ajuda!,
              style: FxSettingsLayout.footer(color: chrome.mute),
            ),
          ],
        ],
      ),
    );
  }
}

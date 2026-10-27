import 'package:flutter/material.dart';

import '../theme/shell_chrome.dart';
import '../theme/tokens_strip.dart';
import 'fx_icon.dart';
import 'fx_input_deco.dart';
import 'fx_keyboard_dismiss_scope.dart';

/// Busca com borda e ícone para usar dentro de folhas.
class FxSheetSearchField extends StatelessWidget {
  const FxSheetSearchField({
    super.key,
    required this.dica,
    required this.onChanged,
    this.controller,
    this.autofocus = false,
  });

  final String dica;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final chrome = ShellChrome.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    InputBorder borda(Color cor, [double largura = 1]) =>
        FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(TokensStrip.rInput),
          borderSide: BorderSide(color: cor, width: largura),
        );
    return Semantics(
      textField: true,
      label: dica,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
        decoration: InputDecoration(
          isDense: true,
          hintText: dica,
          hintStyle: TextStyle(color: chrome.mute, fontWeight: FontWeight.w600),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: FxIcon(name: 'search', size: 18, color: chrome.mute),
          ),
          filled: true,
          fillColor: chrome.cardFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: borda(chrome.lineStrong),
          enabledBorder: borda(chrome.lineStrong),
          focusedBorder: borda(primary, 1.6),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import '../../../core/theme/tokens_strip.dart';
import '../../../core/widgets/fx_input_deco.dart';
import '../../../core/widgets/fx_keyboard_dismiss_scope.dart';

/// Alvo mínimo de toque dos chips de sensação.
const double checkinFeedbackChipMin = 48;

class CheckinSerieField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Color ink;
  final Color mute;
  final Color line;
  final bool dark;

  const CheckinSerieField({
    super.key,
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.keyboardType,
    this.inputFormatters,
    required this.ink,
    required this.mute,
    required this.line,
    required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: ink, fontWeight: FontWeight.w900),
      onTapOutside: (_) => FxKeyboardDismissScope.dismiss(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: mute, fontWeight: FontWeight.w700),
        suffixText: suffix,
        suffixStyle: TextStyle(color: mute, fontWeight: FontWeight.w800),
        prefixIcon: Icon(icon, color: mute, size: 18),
        filled: true,
        fillColor:
            dark
                ? Colors.white.withValues(alpha: 0.05)
                : TokensStrip.borderDefault,
        enabledBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: FxInputDeco.outlineBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}

class CheckinFeedbackChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const CheckinFeedbackChip({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: checkinFeedbackChipMin,
            minWidth: checkinFeedbackChipMin,
          ),
          padding: const EdgeInsets.symmetric(horizontal: TokensStrip.s4),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: color.withValues(alpha: selected ? 0.0 : 0.22),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


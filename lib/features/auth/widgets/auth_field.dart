import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/focux_hub_typography.dart';
import '../../../core/theme/hero_teal.dart';
import '../../../core/theme/tokens_strip.dart';
import 'package:focux_app/core/widgets/fx_input_deco.dart';

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.suffix,
    this.focusNode,
    this.inputFormatters,
    this.autofillHints,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FocuxHubTypography.chip(heroTealSurface(0.86)).copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          validator: validator,
          obscureText: obscureText,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          onFieldSubmitted: onFieldSubmitted,
          style: FocuxHubTypography.body(color: heroTealInk()),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: FocuxHubTypography.body(color: heroTealSurface(0.72)),
            prefixIcon:
                icon == null
                    ? null
                    : Icon(icon, color: heroTealSurface(0.78), size: 18),
            suffixIcon: suffix,
            filled: true,
            fillColor: TokensStrip.glassFill(dark: true, opacity: 0.55),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TokensStrip.s4,
              vertical: TokensStrip.s3,
            ),
            enabledBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              borderSide: BorderSide(color: primary.withValues(alpha: 0.18)),
            ),
            focusedBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              borderSide: BorderSide(color: primary, width: 1.35),
            ),
            errorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              borderSide: BorderSide(color: EagleTokens.authErrorBorder),
            ),
            focusedErrorBorder: FxInputDeco.outlineBorder(
              borderRadius: BorderRadius.circular(TokensStrip.rInput),
              borderSide: BorderSide(color: EagleTokens.authErrorBorder),
            ),
            errorStyle: const TextStyle(
              color: EagleTokens.authErrorSoft,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}

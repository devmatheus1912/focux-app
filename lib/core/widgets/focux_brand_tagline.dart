import 'package:flutter/material.dart';

import '../theme/focux_hub_typography.dart';
import '../theme/tokens_strip.dart';
import '../brand/focux_brand_copy.dart';

/// Tagline de marca — hook unificado em splash, login e onboarding.
class FocuxBrandTagline extends StatelessWidget {
  const FocuxBrandTagline({
    super.key,
    this.center = true,
    this.fontSize = 14,
    this.maxWidth = 320,
    this.aluno = false,
  });

  final bool center;
  final double fontSize;
  final double maxWidth;
  final bool aluno;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mute = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : TokensStrip.textPrimary.withValues(alpha: 0.88);
    final align = center ? TextAlign.center : TextAlign.left;
    final hook =
        aluno ? FocuxBrandCopy.onboardingHookAluno : FocuxBrandCopy.onboardingHook;
    final highlight =
        aluno
            ? FocuxBrandCopy.onboardingHookAlunoHighlight
            : FocuxBrandCopy.onboardingHookHighlight;
    final prefix = hook.substring(0, hook.length - highlight.length);

    return Semantics(
      label: hook,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: RichText(
          textAlign: align,
          text: TextSpan(
            style: FocuxHubTypography.body(
              color: mute,
            ).copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: 0.06,
            ),
            children: [
              TextSpan(text: prefix),
              TextSpan(
                text: highlight,
                style: TextStyle(
                  color: primary.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

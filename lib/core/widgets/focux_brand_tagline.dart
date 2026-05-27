import 'package:flutter/material.dart';

import '../brand/focux_brand_copy.dart';
import '../theme/design_tokens.dart';

/// Tagline de marca — mesma tipografia em login, splash e onboarding.
class FocuxBrandTagline extends StatelessWidget {
  const FocuxBrandTagline({
    super.key,
    this.center = true,
    this.fontSize = 14,
    this.maxWidth = 320,
  });

  final bool center;
  final double fontSize;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final align = center ? TextAlign.center : TextAlign.left;

    return Semantics(
      label: FocuxBrandCopy.tagline,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: RichText(
          textAlign: align,
          text: TextSpan(
            style: AppTypography.inter(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: 0.08,
            ),
            children: [
              const TextSpan(text: 'Gestão '),
              TextSpan(
                text: 'inteligente',
                style: TextStyle(
                  color: primary.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const TextSpan(text: ' para personal trainers.'),
            ],
          ),
        ),
      ),
    );
  }
}

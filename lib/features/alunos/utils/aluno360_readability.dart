import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';

/// WCAG-friendly muted copy for Aluno 360 surfaces.
Color aluno360ReadableMuted(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return EagleTokens.darkInkMute.withValues(alpha: 0.92);
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.76);
}

Color aluno360ReadableCaption(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return EagleTokens.darkInkMute.withValues(alpha: 0.88);
  }
  return TokensStrip.textSecondary;
}

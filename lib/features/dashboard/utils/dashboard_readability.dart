import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';

/// Texto secundário do dashboard com contraste ≥ 4.5:1 (WCAG AA) em fundos claros.
Color dashboardReadableMuted(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return EagleTokens.darkInkMute.withValues(alpha: 0.92);
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.72);
}

Color dashboardReadableCaption(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return EagleTokens.darkInkMute.withValues(alpha: 0.85);
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.65);
}

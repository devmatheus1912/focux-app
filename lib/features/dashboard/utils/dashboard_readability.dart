import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/tokens_strip.dart';

/// Texto secundário do dashboard com contraste ≥ ~4.5:1 em fundos claros.
Color dashboardReadableMuted(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return EagleTokens.darkInkMute.withValues(alpha: 0.88);
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.68);
}

Color dashboardReadableCaption(BuildContext context, {required bool isDark}) {
  if (isDark) {
    return EagleTokens.darkInkMute.withValues(alpha: 0.78);
  }
  return TokensStrip.textPrimary.withValues(alpha: 0.58);
}

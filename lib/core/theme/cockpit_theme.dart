import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Dark cockpit surfaces for screens rendered over the cinematic mesh.
abstract class CockpitTheme {
  static const bool enabled = true;

  static Color get card => EagleTokens.darkCard;
  static Color get cardHi => EagleTokens.darkCardHi;
  static Color get line => EagleTokens.darkLine;
  static Color get ink => EagleTokens.darkInk;
  static Color get mute => EagleTokens.darkInkMute;

  static BoxDecoration glassPanel({Color? tint, double radius = 20}) {
    return BoxDecoration(
      color: EagleTokens.darkCard.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: EagleTokens.glassBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.22),
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -8,
        ),
      ],
    );
  }
}

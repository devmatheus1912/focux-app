import 'package:flutter/material.dart';

import 'design_tokens.dart';
import 'shell_chrome.dart';

/// Dark cockpit surfaces — delegates to [ShellPalette] for consistency.
abstract class CockpitTheme {
  static const bool enabled = true;

  static Color get card => EagleTokens.darkCard;
  static Color get cardHi => EagleTokens.darkCardHi;
  static Color get line => EagleTokens.darkLine;
  static Color get ink => EagleTokens.darkInk;
  static Color get mute => EagleTokens.darkInkMute;

  static BoxDecoration glassPanel({Color? tint, double radius = 20}) =>
      ShellChrome.forDark(true).panel(radius: radius, accent: tint);
}

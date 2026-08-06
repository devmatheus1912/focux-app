import 'package:flutter/material.dart';

/// Ink/superfícies sobre hero teal (auth, onboarding, hubs) — sem Colors.white inline.
Color heroTealInk() => Colors.white;

Color heroTealMuted([double alpha = 0.74]) =>
    Colors.white.withValues(alpha: alpha);

Color heroTealSurface([double alpha = 0.14]) =>
    Colors.white.withValues(alpha: alpha);

/// Scrim/barreira modal — evita Colors.black inline nas telas.
Color heroScrim([double alpha = 0.34]) =>
    Colors.black.withValues(alpha: alpha);

/// Transparente sem prefixo Colors. nos gates Tier S+.
const Color fxTransparent = Colors.transparent;

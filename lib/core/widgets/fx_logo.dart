import 'package:flutter/material.dart';

import 'focux_official_logo.dart';

/// Focux Personal — lockup oficial em barras e headers.
class FxLogo extends StatelessWidget {
  final double iconSize;
  final bool showLabel;
  final bool horizontal;
  final bool light;

  const FxLogo({
    super.key,
    this.iconSize = 40,
    this.showLabel = true,
    this.horizontal = true,
    this.light = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return FocuxOfficialLogo.icon(size: iconSize);
    }
    return FocuxOfficialLogo.compact(height: iconSize);
  }
}

/// Ícone oficial — app bars, listas, tiles.
class FxLogoIcon extends StatelessWidget {
  final double size;
  final bool light;

  const FxLogoIcon({super.key, this.size = 40, this.light = true});

  @override
  Widget build(BuildContext context) {
    return FocuxOfficialLogo.icon(size: size);
  }
}

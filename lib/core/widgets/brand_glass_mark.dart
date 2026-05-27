import 'package:flutter/material.dart';

import 'focux_official_logo.dart';

enum BrandGlassTone {
  /// Auth / dark surfaces.
  dark,

  /// Dashboard light mode.
  light,
}

/// Marca Focux — delega para a logo oficial (ou white-label).
@Deprecated('Use FocuxOfficialLogo directly')
class BrandGlassMark extends StatelessWidget {
  const BrandGlassMark({
    super.key,
    required this.size,
    this.logoUrl,
    this.glowColor,
    this.shimmerAlpha,
    this.tone = BrandGlassTone.dark,
    this.enableBackdropBlur = true,
    this.bare = true,
    this.fullLockup = false,
  });

  final double size;
  final String? logoUrl;
  final Color? glowColor;
  final double? shimmerAlpha;
  final BrandGlassTone tone;
  final bool enableBackdropBlur;
  final bool bare;

  /// true = lockup completo; false = só ícone.
  final bool fullLockup;

  @override
  Widget build(BuildContext context) {
    if (fullLockup) {
      return FocuxOfficialLogo.compact(
        height: size,
        logoUrl: logoUrl,
      );
    }
    return FocuxOfficialLogo.icon(
      size: size,
      logoUrl: logoUrl,
    );
  }
}

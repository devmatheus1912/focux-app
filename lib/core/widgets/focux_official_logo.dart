import 'package:flutter/material.dart';

/// Logo oficial Focux Personal — asset único em todo o app.
class FocuxOfficialLogo extends StatelessWidget {
  const FocuxOfficialLogo({
    super.key,
    this.width,
    this.height,
    this.variant = FocuxLogoVariant.full,
    this.logoUrl,
    this.alignment = Alignment.center,
  }) : assert(width != null || height != null, 'Informe width ou height');

  const FocuxOfficialLogo.full({
    super.key,
    required this.width,
    this.logoUrl,
    this.alignment = Alignment.center,
  })  : height = null,
        variant = FocuxLogoVariant.full;

  const FocuxOfficialLogo.compact({
    super.key,
    required this.height,
    this.logoUrl,
    this.alignment = Alignment.centerLeft,
  })  : width = null,
        variant = FocuxLogoVariant.full;

  const FocuxOfficialLogo.icon({
    super.key,
    required double size,
    this.logoUrl,
  })  : width = size,
        height = size,
        variant = FocuxLogoVariant.icon,
        alignment = Alignment.center;

  static const asset = 'assets/images/logo_official.png';
  static const iconAsset = 'assets/images/logo_icon.png';

  final double? width;
  final double? height;
  final FocuxLogoVariant variant;
  final String? logoUrl;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.trim().isNotEmpty) {
      return _networkLogo(logoUrl!.trim());
    }

    if (variant == FocuxLogoVariant.icon) {
      final side = width ?? height ?? 40;
      return SizedBox(
        width: side,
        height: side,
        child: Image.asset(
          iconAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          gaplessPlayback: true,
          isAntiAlias: true,
        ),
      );
    }

    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      isAntiAlias: true,
    );
  }

  Widget _networkLogo(String url) {
    if (variant == FocuxLogoVariant.icon) {
      final side = width ?? height ?? 40;
      return SizedBox(
        width: side,
        height: side,
        child: ClipOval(
          child: Image.network(
            url,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => _fallbackAsset(),
          ),
        ),
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _fallbackAsset(),
    );
  }

  Widget _fallbackAsset() {
    if (variant == FocuxLogoVariant.icon) {
      return Image.asset(iconAsset, fit: BoxFit.contain);
    }
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

enum FocuxLogoVariant { full, icon }

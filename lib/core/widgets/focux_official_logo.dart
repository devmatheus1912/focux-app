import 'package:flutter/material.dart';

import 'fx_cached_network_image.dart';

/// Logo oficial Focux Personal — variantes prontas para fundo claro e escuro.
///
/// Assets baixados do Drive (não alterar pixels):
/// - [assetLight] — `Logo-oficial-ParaFundoClaro.png`
/// - [assetDark] — `Logo-oficial-ParaFundoEscuro.png`
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

  /// Logo para fundos claros (modo light).
  static const assetLight = 'assets/images/logo_oficial_fundo_claro.png';

  /// Logo para fundos escuros (modo dark / splash cinematográfico).
  static const assetDark = 'assets/images/logo_oficial_fundo_escuro.png';

  /// Ícone app — só o braço (sem wordmark FOCUX PERSONAL).
  static const assetArm = 'assets/images/logo_icon_arm.png';

  /// Alias light — preferir [assetOf] / [assetFor].
  static const asset = assetLight;
  static const iconAsset = assetArm;

  final double? width;
  final double? height;
  final FocuxLogoVariant variant;
  final String? logoUrl;
  final Alignment alignment;

  static String assetFor({required bool dark}) => dark ? assetDark : assetLight;

  static String assetOf(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return assetFor(dark: dark);
  }

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null && logoUrl!.trim().isNotEmpty) {
      return _networkLogo(context, logoUrl!.trim());
    }

    final assetPath = assetOf(context);

    if (variant == FocuxLogoVariant.icon) {
      final side = width ?? height ?? 40;
      final inset = side * 0.08;
      return SizedBox(
        width: side,
        height: side,
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: Image.asset(
            assetArm,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            isAntiAlias: true,
          ),
        ),
      );
    }

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      alignment: alignment,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      isAntiAlias: true,
    );
  }

  Widget _networkLogo(BuildContext context, String url) {
    if (variant == FocuxLogoVariant.icon) {
      final side = width ?? height ?? 40;
      return SizedBox(
        width: side,
        height: side,
        child: ClipOval(
          child: FxCachedNetworkImage(
            imageUrl: url,
            width: side,
            height: side,
            fit: BoxFit.cover,
            memCacheWidth: (side * 2).round(),
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => _fallbackAsset(context),
          ),
        ),
      );
    }

    return FxCachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: BoxFit.contain,
      memCacheWidth: width != null ? (width! * 2).round() : 400,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _fallbackAsset(context),
    );
  }

  Widget _fallbackAsset(BuildContext context) {
    final assetPath = assetOf(context);
    if (variant == FocuxLogoVariant.icon) {
      return Image.asset(assetArm, fit: BoxFit.contain);
    }
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}

enum FocuxLogoVariant { full, icon }

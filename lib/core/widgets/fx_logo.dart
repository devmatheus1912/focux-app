import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Logo completo: ícone F (glassmorphism) + "ocux Personal"
///
/// Parâmetros:
/// - [iconSize]  — tamanho do ícone F em pixels (padrão: 56)
/// - [showLabel] — se deve mostrar o texto "ocux Personal" (padrão: true)
/// - [horizontal]— layout horizontal (ícone + texto lado a lado) ou vertical (padrão: true)
/// - [light]     — usa texto branco (para fundos escuros) ou adapta ao tema
class FxLogo extends StatelessWidget {
  final double iconSize;
  final bool showLabel;
  final bool horizontal;
  final bool light;

  const FxLogo({
    super.key,
    this.iconSize = 56,
    this.showLabel = true,
    this.horizontal = true,
    this.light = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : EagleTokens.ink;

    final icon = Image.asset(
      'assets/images/focux_logo_transparent.png',
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
    );

    if (!showLabel) return icon;

    // Calcula tamanhos do texto proporcionalmente ao ícone
    final fSize = iconSize * 0.62;
    final restSize = iconSize * 0.42;
    final subSize = iconSize * 0.22;

    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'ocux',
                style: TextStyle(
                  color: textColor,
                  fontSize: restSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Personal',
          style: TextStyle(
            color: light
                ? Colors.white.withValues(alpha: 0.55)
                : EagleTokens.inkMute,
            fontSize: subSize,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            height: 1.2,
          ),
        ),
      ],
    );

    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          SizedBox(width: iconSize * 0.08),
          label,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(height: iconSize * 0.12),
        label,
      ],
    );
  }
}

/// Versão apenas do ícone F — para usar em AppBars, avatares, etc.
class FxLogoIcon extends StatelessWidget {
  final double size;

  const FxLogoIcon({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/focux_logo_transparent.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
